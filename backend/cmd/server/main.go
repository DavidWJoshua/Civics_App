package main

import (
	"log"
	"os"
	"path/filepath"

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
	pg, err := db.Connect(db.DBConfig{
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

	// Bulletproof spatial wards path resolution
	cwd, _ := os.Getwd()
	wardPathFound := ""
	for _, p := range []string{
		filepath.Join(cwd, "resources", "wards.json"),
		filepath.Join(cwd, "..", "..", "resources", "wards.json"),
		filepath.Join(cwd, "..", "resources", "wards.json"),
		"C:\\Users\\david\\Downloads\\Civics_App-main\\Civics_App-main\\backend\\resources\\wards.json",
	} {
		if _, err := os.Stat(p); err == nil {
			wardPathFound = p
			break
		}
	}
	
	if wardPathFound == "" {
		log.Println("⚠️ Could not locate wards.json in any expected path relative to", cwd)
	} else if err := spatial.LoadWards(wardPathFound); err != nil {
		log.Println("⚠️ Failed to parse spatial wards.json from", wardPathFound, "error:", err)
	} else {
		log.Println("✅ Loaded spatial wards from", wardPathFound)
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

	snsClient := &auth.MockSNSSender{}
	log.Println("✅ Mock SNS initialized (OTP logged in console)")

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

	r := gin.Default()
	r.Use(middleware.CORSMiddleware())

	// Ensure upload directory exists
	if _, err := os.Stat(cfg.UploadDir); os.IsNotExist(err) {
		os.MkdirAll(cfg.UploadDir, 0755)
	}

	r.Static("/uploads", cfg.UploadDir)
	r.Static("/fe_uploads", "./fe_uploads")

	api := r.Group("/api")

	// PUBLIC ROUTES
	authRoutes := api.Group("/auth")
	auth.RegisterRoutes(authRoutes, authHandler)
	authRoutes.POST("/citizen/verify-otp", authHandler.VerifyOTP)
	authRoutes.POST("/logout", middleware.JWTAuthMiddleware(pg), authHandler.Logout)

	// ===========================
	// CITIZEN ROUTES
	// ===========================
	citizenRoutes := api.Group("/citizen")
	citizenRoutes.Use(middleware.JWTAuthMiddleware(pg))

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
	officerRoutes.Use(middleware.JWTAuthMiddleware(pg))
	field_officer.RegisterRoutes(officerRoutes, pg)

	// ===========================
	// JUNIOR ENGINEER ROUTES
	// ===========================
	jeRoutes := api.Group("/junior-engineer")
	jeRoutes.Use(middleware.JWTAuthMiddleware(pg))
	junior_engineer.RegisterRoutes(jeRoutes, pg)

	// ===========================
	// COMMISSIONER ROUTES
	// ===========================
	commissionerRoutes := api.Group("/commissioner")
	commissionerRoutes.Use(middleware.JWTAuthMiddleware(pg))
	commissioner.RegisterRoutes(commissionerRoutes, pg)

	// ===========================
	// OPERATOR ROUTES
	// ===========================
	operatorRoutes := api.Group("/operator")
	operatorRoutes.Use(middleware.JWTAuthMiddleware(pg))
	operator.RegisterRoutes(operatorRoutes, pg)

	// ===========================
	// ANALYTICS ROUTES (ADMIN)
	// ===========================
	adminRoutes := api.Group("/admin")
	adminRoutes.Use(middleware.JWTAuthMiddleware(pg))
	analytics.RegisterRoutes(adminRoutes, pg)

	// ===========================
	// LEAVE MANAGEMENT ROUTES
	// ===========================
	leaveRoutes := api.Group("/leave-management")
	leaveRoutes.Use(middleware.JWTAuthMiddleware(pg))
	leave_management.RegisterRoutes(leaveRoutes, pg)

	log.Println("🚀 Server running on http://localhost:8080")
	r.Run(":8080")
}
