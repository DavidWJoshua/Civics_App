package operator

import (
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func RegisterRoutes(r *gin.RouterGroup, db *pgxpool.Pool) {
	repo := &Repository{DB: db}
	service := &Service{Repo: repo}
	handler := &Handler{Service: service}

	r.GET("/stations", handler.GetStations)
	r.GET("/equipment", handler.GetEquipment)
	r.GET("/faults", handler.GetFaults)
	r.POST("/faults", handler.ReportFault)

	// Daily Logs
	r.POST("/lifting/daily-log", handler.SubmitLiftingDailyLog)
	r.POST("/pumping/daily-log", handler.SubmitPumpingDailyLog)
	r.POST("/stp/daily-log", handler.SubmitSTPDailyLog)

	// Weekly/Monthly/Yearly Logs
	r.POST("/lifting/weekly-log", handler.SubmitLiftingWeeklyLog)
	r.POST("/lifting/monthly-log", handler.SubmitLiftingMonthlyLog)
	r.POST("/lifting/yearly-log", handler.SubmitLiftingYearlyLog)

	r.POST("/pumping/weekly-log", handler.SubmitPumpingWeeklyLog)
	r.POST("/pumping/monthly-log", handler.SubmitPumpingMonthlyLog)
	r.POST("/pumping/yearly-log", handler.SubmitPumpingYearlyLog)

	r.POST("/stp/maintenance-log", handler.SubmitSTPMaintenanceLog)

	// Profile
	r.GET("/profile", handler.GetProfile)
	r.POST("/profile", handler.CreateProfile)
	r.PUT("/profile", handler.UpdateProfile)
}
