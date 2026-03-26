package field_officer

import (
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"civic-complaint-system/backend/internal/common/middleware"
)

func RegisterRoutes(r *gin.RouterGroup, db *pgxpool.Pool) {
	repo := &Repository{DB: db}
	service := &Service{Repo: repo}
	handler := &Handler{Service: service}

	// 🔒 Only FIELD_OFFICER can access
	r.Use(middleware.RequireFieldOfficer())

	r.GET("/profile", handler.GetProfile)
	r.GET("/dashboard-stats", handler.GetDashboardStats)
	r.GET("/complaints/raised", handler.GetRaisedComplaints)
	r.GET("/complaints/todo", handler.GetToDoList)
	r.POST("/complaints/accept", handler.AcceptComplaint)
	r.POST("/complaints/reject", handler.RejectComplaint)
	r.POST("/complaints/complete", handler.CompleteComplaint)
	r.GET("/complaints/completed", handler.GetCompletedComplaints)
	r.GET("/complaints/rejected", handler.GetRejectedComplaints)
}
