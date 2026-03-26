package leave_management

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

func (h *Handler) ApplyLeave(c *gin.Context) {
	var req LeaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	req.OfficerID = userID

	if err := h.Service.ApplyLeave(c.Request.Context(), &req); err != nil {
		log.Printf("❌ ApplyLeave error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, req)
}

func (h *Handler) GetLeaveHistory(c *gin.Context) {
	userID := c.GetString("user_id")
	leaves, err := h.Service.GetLeaveHistory(c.Request.Context(), userID)
	if err != nil {
		log.Printf("❌ GetLeaveHistory error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, leaves)
}

func (h *Handler) GetPendingLeaves(c *gin.Context) {
	leaves, err := h.Service.GetPendingLeaves(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, leaves)
}

func (h *Handler) ApproveRejectLeave(c *gin.Context) {
	leaveID := c.Param("id")

	var req ApproveRejectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	approverID := c.GetString("user_id")

	if req.Status == "APPROVED" {
		if err := h.Service.ApproveLeave(c.Request.Context(), leaveID, approverID); err != nil {
			log.Printf("❌ ApproveLeave error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else if req.Status == "REJECTED" {
		if err := h.Service.RejectLeave(c.Request.Context(), leaveID, approverID); err != nil {
			log.Printf("❌ RejectLeave error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": req.Status})
}
