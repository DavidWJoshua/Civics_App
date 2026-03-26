package leave_management

import (
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func RegisterRoutes(r *gin.RouterGroup, db *pgxpool.Pool) {
	repo := &Repository{DB: db}
	service := &Service{Repo: repo}
	handler := &Handler{Service: service}

	// Field Officer Routes
	r.POST("/leave/apply", handler.ApplyLeave)
	r.GET("/leave/history", handler.GetLeaveHistory)

	// JE Routes
	r.GET("/leave/pending", handler.GetPendingLeaves)
	r.POST("/leave/:id/approval", handler.ApproveRejectLeave) // JSON body {"status": "APPROVED"|"REJECTED"}
}
