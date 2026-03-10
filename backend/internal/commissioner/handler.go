package commissioner

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

func (h *Handler) Profile(c *gin.Context) {
	userID := c.GetString("user_id")
	data, err := h.Service.GetProfile(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "profile load error"})
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) Dashboard(c *gin.Context) {
	data, err := h.Service.Dashboard(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "dashboard error"})
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) PendingBudgets(c *gin.Context) {
	data, err := h.Service.PendingBudgets(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "budget load error"})
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) ApproveBudget(c *gin.Context) {
	var req ApproveBudgetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	userID := c.GetString("user_id")
	if err := h.Service.ApproveBudget(c, userID, req.ComplaintID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "approve failed"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "approved"})
}

func (h *Handler) RejectBudget(c *gin.Context) {
	var req RejectBudgetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	userID := c.GetString("user_id")
	if err := h.Service.RejectBudget(c, userID, req.ComplaintID, req.Reason); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "reject failed"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "rejected"})
}

func (h *Handler) Escalations(c *gin.Context) {
	data, err := h.Service.Escalations(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "escalation load error"})
		return
	}
	c.JSON(http.StatusOK, data)
}
func (h *Handler) ComplaintDetails(c *gin.Context) {
	id := c.Param("id")

	data, err := h.Service.ComplaintDetails(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "load failed"})
		return
	}

	c.JSON(http.StatusOK, data)
}
func (h *Handler) GetAllComplaints(c *gin.Context) {
	filter := ComplaintFilter{
		Area:      c.Query("area"),
		Severity:  c.Query("severity"),
		Category:  c.Query("category"),
		Ward:      c.Query("ward"),
		StartDate: c.Query("start_date"),
		EndDate:   c.Query("end_date"),
	}

	data, err := h.Service.GetAllComplaints(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "load failed"})
		return
	}
	c.JSON(http.StatusOK, data)
}
