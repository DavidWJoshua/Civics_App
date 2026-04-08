package main

import (
	"context"
	"log"
	"os"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/analytics"
	"civic-complaint-system/backend/internal/auth"
	"civic-complaint-system/backend/internal/citizen"
	commissioner "civic-complaint-system/backend/internal/commissioner"
	"civic-complaint-system/backend/internal/common/db"
	"civic-complaint-system/backend/internal/common/middleware"
	"civic-complaint-system/backend/internal/common/utils"
	"civic-complaint-system/backend/internal/complaint"
	field_officer "civic-complaint-system/backend/internal/field_officer"
	junior_engineer "civic-complaint-system/backend/internal/junior_engineer"
	"civic-complaint-system/backend/internal/leave_management"
	"civic-complaint-system/backend/internal/ml"
	"civic-complaint-system/backend/internal/operator"
	"civic-complaint-system/backend/internal/scheduler"
	"civic-complaint-system/backend/pkg/spatial"

	aws_config "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {

	// Load .env
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️ .env not found in current dir, trying ../../.env")
		_ = godotenv.Load("../../.env")
	}

	cfg := config.LoadConfig()
	middleware.SetJWTSecret(cfg.JWTSecret)
	utils.SetJWTSecret(cfg.JWTSecret)

	// Connect DB
	pg, err := db.Connect(context.Background(), db.DBConfig{
		Host: cfg.DBHost,
		Port: cfg.DBPort,
		Name: cfg.DBName,
		User: cfg.DBUser,
		Pass: cfg.DBPass,
	})
	if err != nil {
		log.Fatal("❌ DB connection failed:", err)
	}
	log.Println("✅ PostgreSQL connected successfully")

	// Initialize SNS Sender
	var snsClient auth.SNSSender
	if cfg.AWSAccessKey != "" && cfg.AWSSecretKey != "" {
		awsCfg, err := aws_config.LoadDefaultConfig(context.Background(),
			aws_config.WithRegion(cfg.AWSRegion),
		)
		if err == nil {
			snsClient = &auth.AWSSNSSender{
				Client: sns.NewFromConfig(awsCfg),
			}
			log.Println("✅ AWS SNS initialized successfully")
		} else {
			log.Printf("⚠️ Warning: Failed to load AWS config: %v. Falling back to Mock SNS.", err)
			snsClient = &auth.MockSNSSender{}
		}
	} else {
		snsClient = &auth.MockSNSSender{}
		log.Println("✅ Mock SNS initialized (OTP logged in console)")
	}

	// ===========================
	// LOAD WARDS FOR GEOLOCATION
	// ===========================
	wardsFilePath := "../../resources/wards.json"
	if err := spatial.LoadWards(wardsFilePath); err != nil {
		log.Printf("⚠️ Warning: Failed to load wards.json: %v. Ward auto-detection will not work.", err)
	} else {
		log.Println("✅ Wards loaded successfully for automatic ward detection")
	}

	// ===========================
	// START SLA AUTO ESCALATION CRON
	// ===========================
	jeRepo := &junior_engineer.Repository{DB: pg}
	scheduler.StartSLACron(jeRepo)

	// ===========================
	// MODULE INITIALIZATION
	// ===========================

	mlClient := ml.NewClient(cfg.MLServiceURL)

	complaintRepo := &complaint.Repository{DB: pg}
	complaintService := &complaint.Service{Repo: complaintRepo}
	complaintHandler := &complaint.Handler{
		Service:  complaintService,
		MLClient: mlClient,
		Config:   cfg,
	}

	authRepo := &auth.Repository{DB: pg}
	citizenRepo := &citizen.Repository{DB: pg}

	authService := &auth.Service{
		Repo: authRepo,
		SNS:  snsClient,
	}

	authHandler := &auth.Handler{
		Service:     authService,
		CitizenRepo: citizenRepo,
	}

	citizenHandler := &citizen.Handler{Repo: citizenRepo}

	// ===========================
	// HTTP SERVER
	// ===========================

	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(middleware.SecurityHeaders())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.GeneralRateLimit())
	r.Use(middleware.LimitBodySize(10 * 1024 * 1024)) // 10MB Limit
	r.Use(middleware.AuditLogger())

	// Health check for AWS ALB
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "UP"})
	})

	// Ensure upload directory exists
	if _, err := os.Stat(cfg.UploadDir); os.IsNotExist(err) {
		os.MkdirAll(cfg.UploadDir, 0755)
	}

	r.Static("/uploads", cfg.UploadDir)
	r.Static("/fe_uploads", "./fe_uploads")

	api := r.Group("/api")

	// PUBLIC ROUTES (rate limiting applied per-route in auth/routes.go)
	authRoutes := api.Group("/auth")
	auth.RegisterRoutes(authRoutes, authHandler)

	// ===========================
	// CITIZEN ROUTES
	// ===========================
	citizenRoutes := api.Group("/citizen")
	citizenRoutes.Use(middleware.JWTAuthMiddleware())

	citizenRoutes.GET("/home", citizenHandler.CitizenHome)
	citizenRoutes.POST("/complaints", complaintHandler.RaiseComplaint)
	citizenRoutes.GET("/complaints", complaintHandler.GetComplaints)
	citizenRoutes.POST("/complaints/:id/feedback", complaintHandler.SubmitFeedback)
	citizenRoutes.POST("/predict", complaintHandler.Predict)
	citizenRoutes.GET("/ward", complaintHandler.GetWard)

	// ===========================
	// FIELD OFFICER ROUTES
	// ===========================
	officerRoutes := api.Group("/field-officer")
	officerRoutes.Use(middleware.JWTAuthMiddleware())
	field_officer.RegisterRoutes(officerRoutes, pg)

	// ===========================
	// JUNIOR ENGINEER ROUTES
	// ===========================
	jeRoutes := api.Group("/junior-engineer")
	jeRoutes.Use(middleware.JWTAuthMiddleware())
	junior_engineer.RegisterRoutes(jeRoutes, pg)

	// ===========================
	// COMMISSIONER ROUTES
	// ===========================
	commissionerRoutes := api.Group("/commissioner")
	commissionerRoutes.Use(middleware.JWTAuthMiddleware())
	commissioner.RegisterRoutes(commissionerRoutes, pg)

	// ===========================
	// OPERATOR ROUTES
	// ===========================
	operatorRoutes := api.Group("/operator")
	operatorRoutes.Use(middleware.JWTAuthMiddleware())
	operator.RegisterRoutes(operatorRoutes, pg)

	// ===========================
	// ANALYTICS ROUTES (ADMIN)
	// ===========================
	adminRoutes := api.Group("/admin")
	adminRoutes.Use(middleware.JWTAuthMiddleware())
	analytics.RegisterRoutes(adminRoutes, pg)

	// ===========================
	// LEAVE MANAGEMENT ROUTES
	// ===========================
	leaveRoutes := api.Group("/leave-management")
	leaveRoutes.Use(middleware.JWTAuthMiddleware())
	leave_management.RegisterRoutes(leaveRoutes, pg)

	log.Println("🚀 Server running on http://localhost:8080")
	r.Run(":8080")
}
