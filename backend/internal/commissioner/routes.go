package commissioner

import (
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"civic-complaint-system/backend/internal/common/middleware"
)

func RegisterRoutes(r *gin.RouterGroup, db *pgxpool.Pool) {
	repo := &Repository{DB: db}
	service := &Service{Repo: repo}
	handler := &Handler{Service: service}

	r.Use(middleware.RequireRole("COMMISSIONER"))

	r.GET("/dashboard", handler.Dashboard)
	r.GET("/budgets", handler.PendingBudgets)
	r.POST("/budgets/approve", handler.ApproveBudget)
	r.POST("/budgets/reject", handler.RejectBudget)
	r.GET("/escalations", handler.Escalations)
	r.GET("/profile", handler.Profile)
	r.GET("/complaints/:id", handler.ComplaintDetails)
	r.GET("/complaints/all", handler.GetAllComplaints)

}
