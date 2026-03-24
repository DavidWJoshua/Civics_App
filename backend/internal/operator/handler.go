package operator

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

func (h *Handler) GetStations(c *gin.Context) {
	stations, err := h.Service.GetStations(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stations)
}

func (h *Handler) GetEquipment(c *gin.Context) {
	stationIDStr := c.Query("station_id")
	if stationIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "station_id required"})
		return
	}
	stationID, err := strconv.Atoi(stationIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid station_id"})
		return
	}

	equipment, err := h.Service.GetEquipmentByStation(c.Request.Context(), stationID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, equipment)
}

func (h *Handler) SubmitLiftingDailyLog(c *gin.Context) {
	var log LiftingDailyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID

	if err := h.Service.SubmitLiftingDailyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitPumpingDailyLog(c *gin.Context) {
	var log PumpingDailyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID

	if err := h.Service.SubmitPumpingDailyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitSTPDailyLog(c *gin.Context) {
	var log STPDailyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID

	if err := h.Service.SubmitSTPDailyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) ReportFault(c *gin.Context) {
	var fault Fault
	if err := c.ShouldBindJSON(&fault); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.Service.ReportFault(c.Request.Context(), &fault); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, fault)
}

func (h *Handler) GetFaults(c *gin.Context) {
	stationIDStr := c.Query("station_id")
	if stationIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "station_id required"})
		return
	}
	stationID, err := strconv.Atoi(stationIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid station_id"})
		return
	}

	faults, err := h.Service.GetFaultsByStation(c.Request.Context(), stationID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, faults)
}

// --- Additional Handlers ---

func (h *Handler) SubmitLiftingWeeklyLog(c *gin.Context) {
	var log LiftingWeeklyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitLiftingWeeklyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitLiftingMonthlyLog(c *gin.Context) {
	var log LiftingMonthlyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitLiftingMonthlyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitLiftingYearlyLog(c *gin.Context) {
	var log LiftingYearlyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitLiftingYearlyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitPumpingWeeklyLog(c *gin.Context) {
	var log PumpingWeeklyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitPumpingWeeklyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitPumpingMonthlyLog(c *gin.Context) {
	var log PumpingMonthlyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitPumpingMonthlyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitPumpingYearlyLog(c *gin.Context) {
	var log PumpingYearlyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitPumpingYearlyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitSTPMaintenanceLog(c *gin.Context) {
	var log STPMaintenanceLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitSTPMaintenanceLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitSTPMonthlyLog(c *gin.Context) {
	var log STPMonthlyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitSTPMonthlyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) SubmitSTPYearlyLog(c *gin.Context) {
	var log STPYearlyLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	log.OperatorID = userID
	if err := h.Service.SubmitSTPYearlyLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, log)
}

func (h *Handler) GetTaskStatus(c *gin.Context) {
	stationIDStr := c.Query("station_id")
	stationType := c.Query("type")
	if stationIDStr == "" || stationType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "station_id and type are required"})
		return
	}
	stationID, err := strconv.Atoi(stationIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid station_id"})
		return
	}
	status, err := h.Service.GetTaskStatus(c.Request.Context(), stationID, stationType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}
