package field_officer

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.GetString("user_id") // ✅ FIXED

	profile, err := h.Service.GetProfile(c.Request.Context(), userID)
	if err != nil {
		log.Printf("❌ GetProfile error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load profile"})
		return
	}

	c.JSON(http.StatusOK, profile)
}

func (h *Handler) GetDashboardStats(c *gin.Context) {
	userID := c.GetString("user_id") // ✅ FIXED

	stats, err := h.Service.GetDashboardStats(c.Request.Context(), userID)
	if err != nil {
		log.Printf("❌ GetDashboardStats error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load dashboard stats"})
		return
	}

	c.JSON(http.StatusOK, stats)
}

func (h *Handler) GetRaisedComplaints(c *gin.Context) {
	userID := c.GetString("user_id") // ✅ FIXED

	filter := ComplaintFilter{
		Area:      c.Query("area"),
		Severity:  c.Query("severity"),
		Category:  c.Query("category"),
		Ward:      c.Query("ward"),
		StartDate: c.Query("start_date"),
		EndDate:   c.Query("end_date"),
	}

	data, err := h.Service.GetRaisedComplaints(c.Request.Context(), userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load complaints"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *Handler) GetToDoList(c *gin.Context) {
	userID := c.GetString("user_id") // ✅ FIXED

	filter := ComplaintFilter{
		Area:      c.Query("area"),
		Severity:  c.Query("severity"),
		Category:  c.Query("category"),
		Ward:      c.Query("ward"),
		StartDate: c.Query("start_date"),
		EndDate:   c.Query("end_date"),
	}

	data, err := h.Service.GetToDoList(c.Request.Context(), userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load todo list"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *Handler) AcceptComplaint(c *gin.Context) {
	userID := c.GetString("user_id") // ✅ FIXED

	var req AcceptComplaintRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	if err := h.Service.AcceptComplaint(c.Request.Context(), userID, req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Complaint accepted"})
}

func (h *Handler) RejectComplaint(c *gin.Context) {
	userID := c.GetString("user_id") // ✅ FIXED

	var req RejectComplaintRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	if err := h.Service.RejectComplaint(c.Request.Context(), userID, req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Complaint rejected"})
}

func (h *Handler) CompleteComplaint(c *gin.Context) {
	userID := c.GetString("user_id")

	complaintID := c.PostForm("complaint_id")
	latStr := c.PostForm("latitude")
	lngStr := c.PostForm("longitude")

	if complaintID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "complaint_id required"})
		return
	}

	lat, _ := strconv.ParseFloat(latStr, 64)
	lng, _ := strconv.ParseFloat(lngStr, 64)

	// 🔥 Handle FE image upload
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "image required"})
		return
	}

	// Ensure folder exists
	if _, err := os.Stat("fe_uploads"); os.IsNotExist(err) {
		os.Mkdir("fe_uploads", 0755)
	}

	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	path := filepath.Join("fe_uploads", filename)

	if err := c.SaveUploadedFile(file, path); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save image"})
		return
	}

	imageURL := fmt.Sprintf("/fe_uploads/%s", filename)

	req := CompleteComplaintRequest{
		ComplaintID: complaintID,
		Latitude:    lat,
		Longitude:   lng,
	}

	if err := h.Service.CompleteComplaint(
		c.Request.Context(),
		userID,
		req,
		imageURL,
	); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Complaint completed"})
}

func (h *Handler) GetCompletedComplaints(c *gin.Context) {
	userID := c.GetString("user_id")

	filter := ComplaintFilter{
		Area:      c.Query("area"),
		Severity:  c.Query("severity"),
		Category:  c.Query("category"),
		Ward:      c.Query("ward"),
		StartDate: c.Query("start_date"),
		EndDate:   c.Query("end_date"),
	}

	data, err := h.Service.GetCompletedComplaints(c.Request.Context(), userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load completed complaints"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *Handler) GetRejectedComplaints(c *gin.Context) {
	userID := c.GetString("user_id")

	filter := ComplaintFilter{
		Area:      c.Query("area"),
		Severity:  c.Query("severity"),
		Category:  c.Query("category"),
		Ward:      c.Query("ward"),
		StartDate: c.Query("start_date"),
		EndDate:   c.Query("end_date"),
	}

	data, err := h.Service.GetRejectedComplaints(c.Request.Context(), userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load rejected complaints"})
		return
	}

	c.JSON(http.StatusOK, data)
}
