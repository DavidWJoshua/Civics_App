package junior_engineer

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

// --------------------
// 👤 PROFILE
// --------------------
func (h *Handler) Profile(c *gin.Context) {
	userID := c.GetString("user_id")

	data, err := h.Service.GetProfile(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "profile load error"})
		return
	}

	c.JSON(http.StatusOK, data)
}

// --------------------
// 📊 DASHBOARD
// --------------------
func (h *Handler) Dashboard(c *gin.Context) {
	data, err := h.Service.Dashboard(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "dashboard error"})
		return
	}
	c.JSON(http.StatusOK, data)
}

// --------------------
// 💰 PENDING BUDGETS
// --------------------
func (h *Handler) PendingBudgets(c *gin.Context) {
	data, err := h.Service.PendingBudgets(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "budget load error"})
		return
	}
	c.JSON(http.StatusOK, data)
}

// --------------------
// ✅ APPROVE BUDGET
// --------------------
func (h *Handler) ApproveBudget(c *gin.Context) {
	var req ApproveBudgetRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	userID := c.GetString("user_id")

	if err := h.Service.ApproveBudget(c.Request.Context(), userID, req.ComplaintID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "approve failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "approved"})
}

// --------------------
// ❌ REJECT BUDGET
// --------------------
func (h *Handler) RejectBudget(c *gin.Context) {
	var req RejectBudgetRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	userID := c.GetString("user_id")

	if err := h.Service.RejectBudget(c.Request.Context(), userID, req.ComplaintID, req.Reason); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "reject failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "rejected"})
}

// --------------------
// ⏱ SLA ESCALATIONS
// --------------------
func (h *Handler) Escalations(c *gin.Context) {
	data, err := h.Service.Escalations(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "escalation load error"})
		return
	}
	c.JSON(http.StatusOK, data)
}
func (h *Handler) AllComplaints(c *gin.Context) {
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

// --------------------------------------------------
// 🔄 COMPLAINT REASSIGNMENT
// --------------------------------------------------

func (h *Handler) ComplaintsForReassignment(c *gin.Context) {
	userID := c.GetString("user_id")

	data, err := h.Service.GetComplaintsForReassignment(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch complaints for reassignment"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *Handler) FieldOfficers(c *gin.Context) {
	userID := c.GetString("user_id")

	data, err := h.Service.GetFieldOfficersStatus(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch field officers status"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *Handler) ReassignComplaint(c *gin.Context) {
	var req ReassignComplaintRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request format"})
		return
	}

	userID := c.GetString("user_id")

	if err := h.Service.ReassignComplaint(c.Request.Context(), req, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to reassign complaint"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "complaint reassigned successfully"})
}
