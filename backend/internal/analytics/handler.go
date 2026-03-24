package analytics

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

// GetOverviewStats returns high-level KPIs
func (h *Handler) GetOverviewStats(c *gin.Context) {
	stats, err := h.Service.GetOverviewStats(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch overview stats: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// GetComplaintAnalytics returns detailed trends and breakdown
func (h *Handler) GetComplaintAnalytics(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "30")
	days, _ := strconv.Atoi(daysStr)

	stats, err := h.Service.GetComplaintAnalytics(c.Request.Context(), days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch complaint analytics: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// GetSLAStats returns SLA compliance data
func (h *Handler) GetSLAStats(c *gin.Context) {
	stats, err := h.Service.GetSLAStats(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch SLA stats: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// GetOperatorStats returns operator compliance and fault data
func (h *Handler) GetOperatorStats(c *gin.Context) {
	stats, err := h.Service.GetOperatorStats(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch operator stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// GenerateReport handles report download requests
func (h *Handler) GenerateReport(c *gin.Context) {
	var req ReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	data, filename, err := h.Service.GenerateReport(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate report"})
		return
	}

	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Data(http.StatusOK, "application/octet-stream", data)
}

// --- New Operator Analytics Handlers ---

// Helper to parse date range from query params
func parseDateRange(c *gin.Context) (time.Time, time.Time) {
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -30) // Default 30 days

	startStr := c.Query("start_date")
	endStr := c.Query("end_date")

	if startStr != "" && endStr != "" {
		s, err1 := time.Parse("2006-01-02", startStr)
		e, err2 := time.Parse("2006-01-02", endStr)
		if err1 == nil && err2 == nil {
			// Set end date to end of day
			e = e.Add(time.Hour*23 + time.Minute*59 + time.Second*59)
			return s, e
		}
	} else {
		// Fallback to 'days' param if dates not provided
		daysStr := c.Query("days")
		if daysStr != "" {
			days, err := strconv.Atoi(daysStr)
			if err == nil && days > 0 {
				startDate = endDate.AddDate(0, 0, -days)
			}
		}
	}
	return startDate, endDate
}

func (h *Handler) GetLiftingAnalytics(c *gin.Context) {
	start, end := parseDateRange(c)
	stats, err := h.Service.GetLiftingAnalytics(c.Request.Context(), start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch lifting stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (h *Handler) GetPumpingAnalytics(c *gin.Context) {
	start, end := parseDateRange(c)
	stats, err := h.Service.GetPumpingAnalytics(c.Request.Context(), start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pumping stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (h *Handler) GetSTPAnalytics(c *gin.Context) {
	start, end := parseDateRange(c)
	stats, err := h.Service.GetSTPAnalytics(c.Request.Context(), start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stp stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (h *Handler) GetOperatorTaskMatrix(c *gin.Context) {
	dateStr := c.DefaultQuery("date", "") // Service handles empty as today
	matrix, err := h.Service.GetOperatorTaskMatrix(c.Request.Context(), dateStr)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch operator matrix"})
		return
	}
	c.JSON(http.StatusOK, matrix)
}

func (h *Handler) GetOperatorPeriodStats(c *gin.Context) {
	start, end := parseDateRange(c)
	stats, err := h.Service.Repo.GetOperatorPeriodStats(c.Request.Context(), start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch operator period stats: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}
