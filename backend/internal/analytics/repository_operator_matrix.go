package analytics

import (
	"context"
	"fmt"
	"time"
)

// GetOperatorTaskMatrix fetches compliance status for all operators across frequencies
func (r *Repository) GetOperatorTaskMatrix(ctx context.Context, date time.Time) (*OperatorTaskMatrix, error) {
	matrix := &OperatorTaskMatrix{
		Tasks: []OperatorTaskStatus{},
	}

	// 1. Fetch all operators
	// Note: 'users' table has id(uuid), phone_number(varchar), role(varchar). No 'name' column.
	query := `
		SELECT id::text, phone_number, role 
		FROM users 
		WHERE role IN ('LIFTING_OPERATOR', 'PUMPING_OPERATOR', 'STP_OPERATOR')
	`
	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("fetch operators: %w", err)
	}
	defer rows.Close()

	type OpInfo struct {
		ID    string
		Phone string
		Role  string
	}
	var operators []OpInfo
	for rows.Next() {
		var o OpInfo
		if err := rows.Scan(&o.ID, &o.Phone, &o.Role); err != nil {
			return nil, err
		}
		operators = append(operators, o)
	}
	rows.Close() // Ensure closed before next queries

	matrix.TotalOperators = int64(len(operators))

	// Helper to format date
	dateStr := date.Format("2006-01-02")

	// Determine Week/Month/Year ranges
	_, week := date.ISOWeek()
	month := date.Month()
	yearNum := date.Year()

	for _, op := range operators {
		status := OperatorTaskStatus{
			OperatorName: op.Phone,
			StationName:  "Assigned Station",
			StationType:  op.Role,
			Daily:        make(map[string]string),
			Weekly:       make(map[string]string),
			Monthly:      make(map[string]string),
		}

		// --- CHECK DAILY ---
		var table string
		var useCreatedAt bool
		switch op.Role {
		case "LIFTING_OPERATOR":
			table = "lifting_daily_logs"
			useCreatedAt = true
		case "PUMPING_OPERATOR":
			table = "pumping_daily_logs"
			// Pumping daily log in migration 008 doesn't show created_at, but we'll check if it exists or use log_date.
			// Checking migration 008 content confirms Pumping daily DOES NOT have created_at.
			useCreatedAt = false
		case "STP_OPERATOR":
			table = "stp_daily_logs"
			useCreatedAt = false
		}

		if table != "" {
			// 1. Fetch Station Name (Last known assignment)
			stationQuery := fmt.Sprintf(`
				SELECT s.name 
				FROM %s l
				JOIN stations s ON l.station_id = s.id
				WHERE l.operator_id = $1
				ORDER BY l.log_date DESC
				LIMIT 1
			`, table)
			var realStationName string
			_ = r.DB.QueryRow(ctx, stationQuery, op.ID).Scan(&realStationName)
			if realStationName != "" {
				status.StationName = realStationName
			} else {
				status.StationName = "Not Assigned"
			}

			// 2. Fetch Daily Status
			var completedDate time.Time
			var err error
			if useCreatedAt {
				err = r.DB.QueryRow(ctx, fmt.Sprintf("SELECT created_at FROM %s WHERE operator_id = $1 AND log_date = $2", table), op.ID, dateStr).Scan(&completedDate)
			} else {
				// Fallback to log_date if created_at not present
				var d time.Time
				err = r.DB.QueryRow(ctx, fmt.Sprintf("SELECT log_date FROM %s WHERE operator_id = $1 AND log_date = $2", table), op.ID, dateStr).Scan(&d)
				completedDate = d
			}

			if err == nil {
				status.Daily[dateStr] = fmt.Sprintf("Completed (%s)", completedDate.Format("2006-01-02"))
			} else {
				status.Daily[dateStr] = "Pending"
			}
		}

		// --- CHECK WEEKLY ---
		var weeklyDate time.Time
		var foundWeekly bool

		if op.Role == "STP_OPERATOR" {
			q := `SELECT log_date FROM stp_maintenance_logs WHERE operator_id = $1 AND type = 'weekly' AND extract(year from log_date) = $2 AND extract(week from log_date) = $3 LIMIT 1`
			err := r.DB.QueryRow(ctx, q, op.ID, yearNum, week).Scan(&weeklyDate)
			if err == nil {
				foundWeekly = true
			}
		} else {
			table = ""
			if op.Role == "LIFTING_OPERATOR" {
				table = "lifting_weekly_logs"
			}
			if op.Role == "PUMPING_OPERATOR" {
				table = "pumping_weekly_logs"
			}

			if table != "" {
				q := fmt.Sprintf(`SELECT log_date FROM %s WHERE operator_id = $1 AND extract(year from log_date) = $2 AND extract(week from log_date) = $3 LIMIT 1`, table)
				err := r.DB.QueryRow(ctx, q, op.ID, yearNum, week).Scan(&weeklyDate)
				if err == nil {
					foundWeekly = true
				}
			}
		}
		keyW := fmt.Sprintf("%d-W%d", yearNum, week)
		status.Weekly[keyW] = "Pending"
		if foundWeekly {
			status.Weekly[keyW] = fmt.Sprintf("Completed (%s)", weeklyDate.Format("2006-01-02"))
		}

		// --- CHECK MONTHLY ---
		var monthlyDate time.Time
		var foundMonthly bool
		if op.Role == "STP_OPERATOR" {
			q := `SELECT log_date FROM stp_maintenance_logs WHERE operator_id = $1 AND type = 'monthly' AND extract(year from log_date) = $2 AND extract(month from log_date) = $3 LIMIT 1`
			err := r.DB.QueryRow(ctx, q, op.ID, yearNum, month).Scan(&monthlyDate)
			if err == nil {
				foundMonthly = true
			}
		} else {
			table = ""
			if op.Role == "LIFTING_OPERATOR" {
				table = "lifting_monthly_logs"
			}
			if op.Role == "PUMPING_OPERATOR" {
				table = "pumping_monthly_logs"
			}

			if table != "" {
				q := fmt.Sprintf(`SELECT log_date FROM %s WHERE operator_id = $1 AND extract(year from log_date) = $2 AND extract(month from log_date) = $3 LIMIT 1`, table)
				err := r.DB.QueryRow(ctx, q, op.ID, yearNum, month).Scan(&monthlyDate)
				if err == nil {
					foundMonthly = true
				}
			}
		}
		keyM := fmt.Sprintf("%d-%02d", yearNum, month)
		status.Monthly[keyM] = "Pending"
		if foundMonthly {
			status.Monthly[keyM] = fmt.Sprintf("Completed (%s)", monthlyDate.Format("2006-01-02"))
		}

		// --- CHECK YEARLY ---
		var yearlyDate time.Time
		var foundYearly bool
		if op.Role != "STP_OPERATOR" {
			table = ""
			if op.Role == "LIFTING_OPERATOR" {
				table = "lifting_yearly_logs"
			}
			if op.Role == "PUMPING_OPERATOR" {
				table = "pumping_yearly_logs"
			}

			if table != "" {
				q := fmt.Sprintf(`SELECT log_date FROM %s WHERE operator_id = $1 AND extract(year from log_date) = $2 LIMIT 1`, table)
				err := r.DB.QueryRow(ctx, q, op.ID, yearNum).Scan(&yearlyDate)
				if err == nil {
					foundYearly = true
				}
			}
		} else {
			// STP N/A
		}
		status.Yearly = "Pending"
		if foundYearly {
			status.Yearly = fmt.Sprintf("Completed (%s)", yearlyDate.Format("2006-01-02"))
		}
		if op.Role == "STP_OPERATOR" {
			status.Yearly = "N/A"
		}

		matrix.Tasks = append(matrix.Tasks, status)
	}

	return matrix, nil
}

// OperatorPeriodStat holds the summary for an operator over a period
type OperatorPeriodStat struct {
	OperatorName string            `json:"operator_name"` // Phone number
	StationName  string            `json:"station_name"`
	Role         string            `json:"role"`
	DailyStatus  map[string]string `json:"daily_status"` // Date -> Status (Completed/Pending)
}

// GetOperatorPeriodStats fetches compliance for a range of dates
func (r *Repository) GetOperatorPeriodStats(ctx context.Context, startDate, endDate time.Time) ([]OperatorPeriodStat, error) {
	// 1. Fetch all operators
	query := `
		SELECT id::text, phone_number, role 
		FROM users 
		WHERE role IN ('LIFTING_OPERATOR', 'PUMPING_OPERATOR', 'STP_OPERATOR')
		ORDER BY role, phone_number
	`
	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("fetch operators: %w", err)
	}
	defer rows.Close()

	type OpInfo struct {
		ID    string
		Phone string
		Role  string
	}
	var operators []OpInfo
	for rows.Next() {
		var o OpInfo
		if err := rows.Scan(&o.ID, &o.Phone, &o.Role); err != nil {
			return nil, err
		}
		operators = append(operators, o)
	}
	rows.Close()

	var stats []OperatorPeriodStat

	for _, op := range operators {
		stat := OperatorPeriodStat{
			OperatorName: op.Phone,
			Role:         op.Role,
			DailyStatus:  make(map[string]string),
			StationName:  "Unassigned", // Default
		}

		// Determine log table
		var table string
		switch op.Role {
		case "LIFTING_OPERATOR":
			table = "lifting_daily_logs"
		case "PUMPING_OPERATOR":
			table = "pumping_daily_logs"
		case "STP_OPERATOR":
			table = "stp_daily_logs"
		}

		if table != "" {
			// Fetch logs for the period
			// Also fetch station name from the most recent log in this period (or overall)
			// For simplicity, we'll fetch station name from the first log found in the range, or a separate query

			// 2. Fetch Logs & Station Name
			// We join with stations to get the name
			logQuery := fmt.Sprintf(`
				SELECT l.log_date, s.name 
				FROM %s l
				JOIN stations s ON l.station_id = s.id
				WHERE l.operator_id = $1 AND l.log_date >= $2 AND l.log_date <= $3
				ORDER BY l.log_date ASC
			`, table)

			logRows, err := r.DB.Query(ctx, logQuery, op.ID, startDate, endDate)
			if err != nil {
				// Log error but continue?
				fmt.Printf("Error fetching logs for %s: %v\n", op.Phone, err)
			} else {
				defer logRows.Close()
				for logRows.Next() {
					var d time.Time
					var sName string
					if err := logRows.Scan(&d, &sName); err == nil {
						dateStr := d.Format("2006-01-02")
						stat.DailyStatus[dateStr] = "Completed"
						stat.StationName = sName // Update station name (last one wins or any is fine)
					}
				}
				logRows.Close()
			}

			// If still unassigned, try to find *any* log to get the station name
			if stat.StationName == "Unassigned" {
				// Quick check for last known station
				stationQuery := fmt.Sprintf(`
					SELECT s.name 
					FROM %s l
					JOIN stations s ON l.station_id = s.id
					WHERE l.operator_id = $1
					ORDER BY l.log_date DESC
					LIMIT 1
				`, table)
				var lastStation string
				_ = r.DB.QueryRow(ctx, stationQuery, op.ID).Scan(&lastStation)
				if lastStation != "" {
					stat.StationName = lastStation
				}
			}
		}
		stats = append(stats, stat)
	}

	return stats, nil
}
