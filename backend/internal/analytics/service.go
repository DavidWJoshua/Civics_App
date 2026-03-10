package analytics

import (
	"context"
	"fmt"
	"time"
)

type Service struct {
	Repo *Repository
}

func (s *Service) GetOverviewStats(ctx context.Context) (*OverviewStats, error) {
	return s.Repo.GetOverviewStats(ctx)
}

func (s *Service) GetComplaintAnalytics(ctx context.Context, days int) (*ComplaintAnalytics, error) {
	// 1. Fetch Trends
	trends, err := s.Repo.GetComplaintTrends(ctx, days)
	if err != nil {
		return nil, err
	}

	// 2. Fetch Breakdowns
	severity, err := s.Repo.GetComplaintBreakdown(ctx, "severity")
	if err != nil {
		return nil, err
	}

	category, err := s.Repo.GetComplaintBreakdown(ctx, "category")
	if err != nil {
		return nil, err
	}

	// 3. Fetch Officer Performance
	performance, err := s.Repo.GetOfficerPerformance(ctx)
	if err != nil {
		return nil, err
	}

	return &ComplaintAnalytics{
		TrendData:          trends,
		SeverityCounts:     severity,
		CategoryCounts:     category,
		AvgResolutionHours: 0, // Pending calculation logic
		OfficerPerformance: performance,
	}, nil
}

func (s *Service) GetSLAStats(ctx context.Context) (*SLAStats, error) {
	// Simple pass-through for now, can be enriched
	overview, err := s.Repo.GetOverviewStats(ctx)
	if err != nil {
		return nil, err
	}

	breaches, err := s.Repo.GetRecentBreaches(ctx, 10)
	if err != nil {
		return nil, err
	}

	return &SLAStats{
		TotalBreaches:  overview.SLABreaches,
		ComplianceRate: 0, // Placeholder
		RecentBreaches: breaches,
	}, nil
}

func (s *Service) GetOperatorStats(ctx context.Context) (*OperatorStats, error) {
	return s.Repo.GetOperatorStats(ctx)
}

// GenerateReport is a placeholder for PDF/Excel generation
// GenerateReport generates PDF/Excel/CSV reports
func (s *Service) GenerateReport(ctx context.Context, req ReportRequest) ([]byte, string, error) {
	if req.Type == "operator" && (req.Format == "excel" || req.Format == "csv") {
		// 1. Parse Dates
		var start, end time.Time
		var err error
		if req.StartDate != "" {
			start, err = time.Parse("2006-01-02", req.StartDate)
			if err != nil {
				return nil, "", fmt.Errorf("invalid start_date: %v", err)
			}
		} else {
			start = time.Now().AddDate(0, 0, -30)
		}

		if req.EndDate != "" {
			end, err = time.Parse("2006-01-02", req.EndDate)
			if err != nil {
				return nil, "", fmt.Errorf("invalid end_date: %v", err)
			}
		} else {
			end = time.Now()
		}

		// Ensure proper range
		if start.After(end) {
			start, end = end, start
		}

		// 2. Fetch Data
		stats, err := s.Repo.GetOperatorPeriodStats(ctx, start, end)
		if err != nil {
			return nil, "", err
		}

		// 3. Generate CSV
		// Header: Operator, Role, Station, [Date1, Date2, ...]
		header := "Operator Name,Role,Station"
		var dates []string
		for d := start; !d.After(end); d = d.AddDate(0, 0, 1) {
			dateStr := d.Format("2006-01-02")
			dates = append(dates, dateStr)
			header += fmt.Sprintf(",%s", dateStr)
		}
		header += "\n"

		csvData := header
		for _, stat := range stats {
			row := fmt.Sprintf("%s,%s,%s", stat.OperatorName, stat.Role, stat.StationName)
			for _, dateStr := range dates {
				status, exists := stat.DailyStatus[dateStr]
				if !exists || status == "" {
					status = "Pending"
				}
				// Clean status string if needed (remove commas)
				row += fmt.Sprintf(",%s", status)
			}
			csvData += row + "\n"
		}

		return []byte(csvData), fmt.Sprintf("operator_matrix_%s.csv", time.Now().Format("20060102")), nil
	}

	// Fallback/Placeholder for other types
	if req.Format == "excel" || req.Format == "csv" {
		data := "Date,Metric,Value\n2023-01-01,Complaint,10\n"
		return []byte(data), "report.csv", nil
	}

	return nil, "", fmt.Errorf("unsupported format or type")
}

// --- New Operator Analytics Methods ---

func (s *Service) GetLiftingAnalytics(ctx context.Context, startDate, endDate time.Time) (*LiftingStats, error) {
	return s.Repo.GetLiftingAnalytics(ctx, startDate, endDate)
}

func (s *Service) GetPumpingAnalytics(ctx context.Context, startDate, endDate time.Time) (*PumpingStats, error) {
	return s.Repo.GetPumpingAnalytics(ctx, startDate, endDate)
}

func (s *Service) GetSTPAnalytics(ctx context.Context, startDate, endDate time.Time) (*STPStats, error) {
	return s.Repo.GetSTPAnalytics(ctx, startDate, endDate)
}

func (s *Service) GetOperatorTaskMatrix(ctx context.Context, dateStr string) (*OperatorTaskMatrix, error) {
	// Parse date string (YYYY-MM-DD)
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		// Default to today if invalid
		date = time.Now()
	}
	return s.Repo.GetOperatorTaskMatrix(ctx, date)
}
