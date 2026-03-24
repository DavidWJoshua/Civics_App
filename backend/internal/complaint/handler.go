package complaint

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"civic-complaint-system/backend/internal/ml"

	"civic-complaint-system/backend/config"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service  *Service
	MLClient *ml.Client
	Config   *config.Config
}

func (h *Handler) RaiseComplaint(c *gin.Context) {
	// 1. Parse Multipart Form — 5 MB limit (was 32 MB) to prevent resource exhaustion.
	if err := c.Request.ParseMultipartForm(5 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse form, ensure multipart/form-data and max 5MB"})
		return
	}

	// 2. Extract Fields
	category := c.Request.FormValue("category")
	severity := c.Request.FormValue("severity")
	latStr := c.Request.FormValue("latitude")
	lngStr := c.Request.FormValue("longitude")
	street := c.Request.FormValue("street")
	area := c.Request.FormValue("area")
	ward := c.Request.FormValue("ward")
	city := c.Request.FormValue("city")
	locationStr := c.Request.FormValue("location_json")

	if category == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "category is required"})
		return
	}

	// 3. Parse Numbers & JSON
	lat, _ := strconv.ParseFloat(latStr, 64)
	lng, _ := strconv.ParseFloat(lngStr, 64)
	var locationMap map[string]interface{}
	json.Unmarshal([]byte(locationStr), &locationMap)

	// 4. Handle Image Upload
	var imageURL string
	file, err := c.FormFile("image")
	if err == nil {
		// --- MIME type validation ---
		// Open the file and read the first 512 bytes for content sniffing.
		// This catches disguised files (e.g. a .jpg with executable content).
		f, openErr := file.Open()
		if openErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "failed to open uploaded file"})
			return
		}
		sniff := make([]byte, 512)
		n, _ := f.Read(sniff)
		f.Close()
		mime := http.DetectContentType(sniff[:n])
		if !strings.HasPrefix(mime, "image/") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "only image uploads are allowed"})
			return
		}

		// Ensure uploads directory exists
		if _, err := os.Stat(h.Config.UploadDir); os.IsNotExist(err) {
			os.MkdirAll(h.Config.UploadDir, 0755)
		}

		// Create unique filename
		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
		path := filepath.Join(h.Config.UploadDir, filename)

		// Save file
		if err := c.SaveUploadedFile(file, path); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save image"})
			return
		}

		// AI Analysis: If category is empty or "Other", try to predict
		if h.MLClient != nil && (category == "" || category == "Other") {
			imgData, err := os.ReadFile(path)
			if err == nil {
				prediction, err := h.MLClient.Predict(imgData, filename)
				if err == nil && prediction.Category != "Others" && prediction.Category != "" {
					category = prediction.Category
					severity = prediction.Severity
				}
			}
		}

		// Create Relative URL
		imageURL = fmt.Sprintf("/uploads/%s", filename)
	}

	// 5. Build Request DTO
	req := CreateComplaintRequest{
		Category:  category,
		Severity:  severity,
		Latitude:  lat,
		Longitude: lng,
		Street:    street,
		Area:      area,
		Ward:      ward,
		City:      city,
		Location:  locationMap,
		ImageURL:  imageURL,
	}

	citizenID := c.GetString("user_id")

	id, err := h.Service.RaiseComplaint(c, citizenID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create complaint"})
		return
	}

	c.JSON(http.StatusCreated, CreateComplaintResponse{
		ComplaintID: id,
		Status:      "RAISED",
		Message:     "Complaint raised successfully",
	})
}

func (h *Handler) Predict(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "image is required"})
		return
	}

	f, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to open image"})
		return
	}
	defer f.Close()

	imgData, err := io.ReadAll(f)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to read image"})
		return
	}

	prediction, err := h.MLClient.Predict(imgData, file.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ML service unavailable"})
		return
	}

	c.JSON(http.StatusOK, prediction)
}

func (h *Handler) GetComplaints(c *gin.Context) {
	citizenID := c.GetString("user_id")

	complaints, err := h.Service.GetComplaints(c, citizenID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch complaints"})
		return
	}

	c.JSON(http.StatusOK, complaints)
}

func (h *Handler) SubmitFeedback(c *gin.Context) {
	complaintID := c.Param("id")
	citizenID := c.GetString("user_id")

	var req SubmitFeedbackRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.Service.SubmitFeedback(c, citizenID, complaintID, req.Rating, req.FeedbackText)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to submit feedback"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "feedback submitted successfully"})
}
