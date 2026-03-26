package analytics

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

// GetOverviewStats fetches high-level KPIs
func (r *Repository) GetOverviewStats(ctx context.Context) (*OverviewStats, error) {
	stats := &OverviewStats{
		StatusCounts:       make(map[string]int64),
		WardWiseComplaints: make(map[string]int64),
	}

	// Total Complaints
	var total int64
	err := r.DB.QueryRow(ctx, "SELECT COUNT(*) FROM complaints").Scan(&total)
	if err != nil {
		fmt.Printf("Error fetching total complaints: %v\n", err) // Added logging
		return nil, err
	}
	stats.TotalComplaints = total

	// Status Counts
	rows, err := r.DB.Query(ctx, "SELECT status, COUNT(*) FROM complaints GROUP BY status")
	if err != nil {
		fmt.Printf("Error fetching status counts: %v\n", err)
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var status string
		var count int64
		if err := rows.Scan(&status, &count); err != nil {
			fmt.Printf("Error scanning status count: %v\n", err)
			return nil, err
		}
		stats.StatusCounts[status] = count
	}

	// Ward Wise Counts
	// 'ward' is INTEGER in DB, casting to text for map usage
	rowsWard, err := r.DB.Query(ctx, "SELECT ward::text, COUNT(*) FROM complaints WHERE ward IS NOT NULL GROUP BY ward")
	if err != nil {
		fmt.Printf("Error fetching ward counts: %v\n", err)
		return nil, err
	}
	defer rowsWard.Close()

	for rowsWard.Next() {
		var ward string
		var count int64
		if err := rowsWard.Scan(&ward, &count); err != nil {
			return nil, err
		}
		stats.WardWiseComplaints[ward] = count
	}

	// SLA Breaches (Example logic: unresolved > 48h)
	var breachCount int64
	err = r.DB.QueryRow(ctx, `
		SELECT COUNT(*) FROM complaints 
		WHERE status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED') 
		AND created_at < NOW() - INTERVAL '48 hours'
	`).Scan(&breachCount)
	if err != nil {
		fmt.Printf("Error fetching breach count: %v\n", err)
		return nil, err
	}
	stats.SLABreaches = breachCount

	// Active Escalations (Count complaints with status containing 'ESCALATED' or specific flag)
	// Assuming logic based on escalation table or status
	// Placeholder: 0
	stats.ActiveEscalations = 0

	// Pending Budgets
	// Placeholder: 0
	stats.PendingBudgets = 0

	return stats, nil
}

// GetComplaintTrends fetches trend data
func (r *Repository) GetComplaintTrends(ctx context.Context, days int) ([]TimePoint, error) {
	var trends []TimePoint
	// Use explicit parameter in query string for pg interpolation
	query := fmt.Sprintf(`
		SELECT to_char(created_at, 'YYYY-MM-DD') as date, COUNT(*) as count
		FROM complaints
		WHERE created_at > NOW() - INTERVAL '%d days'
		GROUP BY date
		ORDER BY date ASC
	`, days)

	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		fmt.Printf("Error fetching trends: %v\n", err)
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var tp TimePoint
		if err := rows.Scan(&tp.Date, &tp.Count); err != nil {
			fmt.Printf("Error scanning trend: %v\n", err)
			return nil, err
		}
		trends = append(trends, tp)
	}

	return trends, nil
}

// GetComplaintBreakdown groups complaints by a field
func (r *Repository) GetComplaintBreakdown(ctx context.Context, field string) (map[string]int64, error) {
	// Safe-guarding against SQL injection
	if field != "severity" && field != "category" {
		return nil, fmt.Errorf("invalid grouping field")
	}

	query := fmt.Sprintf("SELECT %s, COUNT(*) FROM complaints GROUP BY %s", field, field)
	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		fmt.Printf("Error fetching breakdown for %s: %v\n", field, err)
		return nil, err
	}
	defer rows.Close()

	breakdown := make(map[string]int64)
	for rows.Next() {
		var key string
		var count int64
		if err := rows.Scan(&key, &count); err != nil {
			return nil, err
		}
		if key == "" {
			key = "Unknown"
		}
		breakdown[key] = count
	}
	return breakdown, nil
}

// GetOfficerPerformance calculates average resolution time per officer
func (r *Repository) GetOfficerPerformance(ctx context.Context) ([]OfficerStat, error) {
	var stats []OfficerStat
	// 'users' table has no 'name' column, using 'phone_number' as identifier
	rows, err := r.DB.Query(ctx, `
		SELECT 
			u.phone_number,
			COUNT(c.id),
			COUNT(CASE WHEN c.status = 'RESOLVED' THEN 1 END),
			COALESCE(AVG(CASE WHEN c.status = 'RESOLVED' THEN EXTRACT(EPOCH FROM (c.updated_at - c.created_at))/3600 ELSE 0 END), 0)
		FROM users u
		JOIN complaint_assignments ca ON u.phone_number = ca.assigned_to_user_id
		JOIN complaints c ON ca.complaint_id = c.id
		WHERE u.role = 'FIELD_OFFICER'
		GROUP BY u.phone_number
	`)
	if err != nil {
		fmt.Printf("Error fetching officer performance: %v\n", err)
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var s OfficerStat
		var avgTime float64
		if err := rows.Scan(&s.OfficerName, &s.ComplaintsTotal, &s.Resolved, &avgTime); err != nil {
			return nil, err
		}
		s.AvgTimeHours = int(avgTime)
		stats = append(stats, s)
	}
	return stats, nil
}

// GetRecentBreaches fetches detailed list of SLA violations
func (r *Repository) GetRecentBreaches(ctx context.Context, limit int) ([]BreachItem, error) {
	var breaches []BreachItem
	rows, err := r.DB.Query(ctx, `
		SELECT 
			id,
			(created_at + INTERVAL '48 hours'),
			'FIELD_OFFICER',
			'Resolution time exceeded'
		FROM complaints
		WHERE status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
		AND created_at < NOW() - INTERVAL '48 hours'
		ORDER BY created_at ASC
		LIMIT $1
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var b BreachItem
		if err := rows.Scan(&b.ComplaintID, &b.BreachedAt, &b.Role, &b.Reason); err != nil {
			return nil, err
		}
		breaches = append(breaches, b)
	}

	return breaches, nil
}

// GetOperatorStats aggregates compliance from daily logs
func (r *Repository) GetOperatorStats(ctx context.Context) (*OperatorStats, error) {
	stats := &OperatorStats{
		StationCompliance: []StationStat{},
		FaultsBySeverity:  make(map[string]int64),
	}

	// 1. Calculate Station Compliance (Logs submitted vs Days)
	query := `
		SELECT s.name, s.type, COUNT(l.id)
		FROM stations s
		LEFT JOIN lifting_daily_logs l ON s.id = l.station_id AND l.log_date > CURRENT_DATE - 30
		WHERE s.type = 'lifting'
		GROUP BY s.name, s.type
		UNION ALL
		SELECT s.name, s.type, COUNT(p.id)
		FROM stations s
		LEFT JOIN pumping_daily_logs p ON s.id = p.station_id AND p.log_date > CURRENT_DATE - 30
		WHERE s.type = 'pumping'
		GROUP BY s.name, s.type
		UNION ALL
		SELECT s.name, s.type, COUNT(stp.id)
		FROM stations s
		LEFT JOIN stp_daily_logs stp ON s.id = stp.station_id AND stp.log_date > CURRENT_DATE - 30
		WHERE s.type = 'stp'
		GROUP BY s.name, s.type
	`
	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		if err == pgx.ErrNoRows {
			// No stations or stats found
		} else {
			return nil, err
		}
	} else {
		defer rows.Close()
		totalLogs := int64(0)
		stationCount := 0

		for rows.Next() {
			var name, stType string
			var count int64
			if err := rows.Scan(&name, &stType, &count); err != nil {
				continue
			}

			rate := (float64(count) / 30.0) * 100
			if rate > 100 {
				rate = 100
			}
			stats.StationCompliance = append(stats.StationCompliance, StationStat{
				StationName:    name,
				Type:           stType,
				ComplianceRate: rate,
				FaultCount:     0,
			})
			totalLogs += count
			stationCount++
		}

		totalExpected := int64(stationCount * 30)
		if totalExpected > 0 {
			stats.ComplianceRate = (float64(totalLogs) / float64(totalExpected)) * 100
		}
	}

	// 2. Fault Analysis
	rowsFaults, err := r.DB.Query(ctx, "SELECT severity, COUNT(*) FROM faults GROUP BY severity")
	if err != nil {
		if err != pgx.ErrNoRows {
			return nil, err
		}
	} else {
		defer rowsFaults.Close()
		for rowsFaults.Next() {
			var severity string
			var count int64
			if err := rowsFaults.Scan(&severity, &count); err != nil {
				continue
			}
			if severity == "" {
				severity = "Unknown"
			}
			stats.FaultsBySeverity[severity] = count
		}
	}

	return stats, nil
}
