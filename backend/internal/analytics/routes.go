package analytics

import (
	"civic-complaint-system/backend/internal/common/middleware"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func RegisterRoutes(r *gin.RouterGroup, db *pgxpool.Pool) {
	repo := &Repository{DB: db}
	service := &Service{Repo: repo}
	handler := &Handler{Service: service}

	// Apply RBAC: Only JUNIOR_ENGINEER and COMMISSIONER
	r.Use(middleware.RequireRole("JUNIOR_ENGINEER", "COMMISSIONER", "ADMIN"))

	r.GET("/overview", handler.GetOverviewStats)
	r.GET("/complaints", handler.GetComplaintAnalytics)
	r.GET("/sla", handler.GetSLAStats)
	r.GET("/operator", handler.GetOperatorStats) // Legacy/General

	// New Operator Modules
	r.GET("/lifting", handler.GetLiftingAnalytics)
	r.GET("/pumping", handler.GetPumpingAnalytics)
	r.GET("/stp", handler.GetSTPAnalytics)
	r.GET("/operator-matrix", handler.GetOperatorTaskMatrix)
	r.GET("/operator-period-stats", handler.GetOperatorPeriodStats)

	r.POST("/reports", handler.GenerateReport)
}
