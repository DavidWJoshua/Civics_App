package operator

import (
	"context"
	"time"
)

type Service struct {
	Repo *Repository
}

func (s *Service) GetStations(ctx context.Context) ([]Station, error) {
	return s.Repo.GetStations(ctx)
}

func (s *Service) GetEquipmentByStation(ctx context.Context, stationID int) ([]Equipment, error) {
	return s.Repo.GetEquipmentByStation(ctx, stationID)
}

// --- Lifting ---

func (s *Service) SubmitLiftingDailyLog(ctx context.Context, log *LiftingDailyLog) error {
	// Set CreatedAt if not set (though DB handles default, good to have consistent object)
	if log.CreatedAt.IsZero() {
		log.CreatedAt = time.Now()
	}
	// Parse date if needed, but we used string in struct for simplicity with JSON.
	// DB expects DATE type, driver handles string "YYYY-MM-DD" usually.
	return s.Repo.CreateLiftingDailyLog(ctx, log)
}

// --- Pumping ---

func (s *Service) SubmitPumpingDailyLog(ctx context.Context, log *PumpingDailyLog) error {
	return s.Repo.CreatePumpingDailyLog(ctx, log)
}

// --- STP ---

func (s *Service) SubmitSTPDailyLog(ctx context.Context, log *STPDailyLog) error {
	return s.Repo.CreateSTPDailyLog(ctx, log)
}

// --- Faults ---

func (s *Service) ReportFault(ctx context.Context, fault *Fault) error {
	if fault.ReportTime.IsZero() {
		fault.ReportTime = time.Now()
	}
	return s.Repo.ReportFault(ctx, fault)
}

func (s *Service) GetFaultsByStation(ctx context.Context, stationID int) ([]Fault, error) {
	return s.Repo.GetFaultsByStation(ctx, stationID)
}

func (s *Service) SubmitLiftingWeeklyLog(ctx context.Context, log *LiftingWeeklyLog) error {
	return s.Repo.CreateLiftingWeeklyLog(ctx, log)
}

func (s *Service) SubmitLiftingMonthlyLog(ctx context.Context, log *LiftingMonthlyLog) error {
	return s.Repo.CreateLiftingMonthlyLog(ctx, log)
}

func (s *Service) SubmitLiftingYearlyLog(ctx context.Context, log *LiftingYearlyLog) error {
	return s.Repo.CreateLiftingYearlyLog(ctx, log)
}

func (s *Service) SubmitPumpingWeeklyLog(ctx context.Context, log *PumpingWeeklyLog) error {
	return s.Repo.CreatePumpingWeeklyLog(ctx, log)
}

func (s *Service) SubmitPumpingMonthlyLog(ctx context.Context, log *PumpingMonthlyLog) error {
	return s.Repo.CreatePumpingMonthlyLog(ctx, log)
}

func (s *Service) SubmitPumpingYearlyLog(ctx context.Context, log *PumpingYearlyLog) error {
	return s.Repo.CreatePumpingYearlyLog(ctx, log)
}

func (s *Service) SubmitSTPMaintenanceLog(ctx context.Context, log *STPMaintenanceLog) error {
	return s.Repo.CreateSTPMaintenanceLog(ctx, log)
}
