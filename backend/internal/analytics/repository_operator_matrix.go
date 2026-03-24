package analytics

import (
	"context"
	"fmt"
	"time"
)

// staticTableQuery returns a fully hard-coded SQL string for a given (table, queryType)
// combination. Using static strings instead of fmt.Sprintf ensures that table names
// can never be user-influenced, even if a future code change breaks the switch guard.
//
// queryType values:
//
//	"stationName"    – SELECT last station name for an operator
//	"dailyCreatedAt" – SELECT created_at for a daily log row by operator + date
//	"dailyLogDate"   – SELECT log_date for a daily log row by operator + date
//	"weeklyLog"      – SELECT log_date for a weekly log row by operator + year + week
//	"monthlyLog"     – SELECT log_date for a monthly log row by operator + year + month
//	"yearlyLog"      – SELECT log_date for a yearly log row by operator + year
//	"periodLogs"     – SELECT log_date + station name for a date-range period query
//	"lastStation"    – SELECT last known station name for an operator
func staticTableQuery(table, queryType string) string {
	type key struct{ table, queryType string }
	queries := map[key]string{
		// ----- stationName -----
		{"lifting_daily_logs", "stationName"}: `
			SELECT s.name
			FROM lifting_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1
			ORDER BY l.log_date DESC
			LIMIT 1`,
		{"pumping_daily_logs", "stationName"}: `
			SELECT s.name
			FROM pumping_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1
			ORDER BY l.log_date DESC
			LIMIT 1`,
		{"stp_daily_logs", "stationName"}: `
			SELECT s.name
			FROM stp_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1
			ORDER BY l.log_date DESC
			LIMIT 1`,
		// ----- dailyCreatedAt -----
		{"lifting_daily_logs", "dailyCreatedAt"}: `SELECT created_at FROM lifting_daily_logs WHERE operator_id = $1 AND log_date = $2`,
		// ----- dailyLogDate -----
		{"pumping_daily_logs", "dailyLogDate"}: `SELECT log_date FROM pumping_daily_logs WHERE operator_id = $1 AND log_date = $2`,
		{"stp_daily_logs", "dailyLogDate"}:     `SELECT log_date FROM stp_daily_logs     WHERE operator_id = $1 AND log_date = $2`,
		// ----- weeklyLog -----
		{"lifting_weekly_logs", "weeklyLog"}: `SELECT log_date FROM lifting_weekly_logs WHERE operator_id = $1 AND extract(year from log_date) = $2 AND extract(week from log_date) = $3 LIMIT 1`,
		{"pumping_weekly_logs", "weeklyLog"}: `SELECT log_date FROM pumping_weekly_logs WHERE operator_id = $1 AND extract(year from log_date) = $2 AND extract(week from log_date) = $3 LIMIT 1`,
		// ----- monthlyLog -----
		{"lifting_monthly_logs", "monthlyLog"}: `SELECT log_date FROM lifting_monthly_logs WHERE operator_id = $1 AND extract(year from log_date) = $2 AND extract(month from log_date) = $3 LIMIT 1`,
		{"pumping_monthly_logs", "monthlyLog"}: `SELECT log_date FROM pumping_monthly_logs WHERE operator_id = $1 AND extract(year from log_date) = $2 AND extract(month from log_date) = $3 LIMIT 1`,
		// ----- yearlyLog -----
		{"lifting_yearly_logs", "yearlyLog"}: `SELECT log_date FROM lifting_yearly_logs WHERE operator_id = $1 AND extract(year from log_date) = $2 LIMIT 1`,
		{"pumping_yearly_logs", "yearlyLog"}: `SELECT log_date FROM pumping_yearly_logs WHERE operator_id = $1 AND extract(year from log_date) = $2 LIMIT 1`,
		// ----- periodLogs -----
		{"lifting_daily_logs", "periodLogs"}: `
			SELECT l.log_date, s.name
			FROM lifting_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1 AND l.log_date >= $2 AND l.log_date <= $3
			ORDER BY l.log_date ASC`,
		{"pumping_daily_logs", "periodLogs"}: `
			SELECT l.log_date, s.name
			FROM pumping_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1 AND l.log_date >= $2 AND l.log_date <= $3
			ORDER BY l.log_date ASC`,
		{"stp_daily_logs", "periodLogs"}: `
			SELECT l.log_date, s.name
			FROM stp_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1 AND l.log_date >= $2 AND l.log_date <= $3
			ORDER BY l.log_date ASC`,
		// ----- lastStation -----
		{"lifting_daily_logs", "lastStation"}: `
			SELECT s.name
			FROM lifting_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1
			ORDER BY l.log_date DESC
			LIMIT 1`,
		{"pumping_daily_logs", "lastStation"}: `
			SELECT s.name
			FROM pumping_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1
			ORDER BY l.log_date DESC
			LIMIT 1`,
		{"stp_daily_logs", "lastStation"}: `
			SELECT s.name
			FROM stp_daily_logs l
			JOIN stations s ON l.station_id = s.id
			WHERE l.operator_id = $1
			ORDER BY l.log_date DESC
			LIMIT 1`,
	}
	return queries[key{table, queryType}]
}

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
			// 1. Fetch Station Name (last known assignment) — static query, no interpolation.
			var realStationName string
			_ = r.DB.QueryRow(ctx, staticTableQuery(table, "stationName"), op.ID).Scan(&realStationName)
			if realStationName != "" {
				status.StationName = realStationName
			} else {
				status.StationName = "Not Assigned"
			}

			// 2. Fetch Daily Status — static queries, no interpolation.
			var completedDate time.Time
			var err error
			if useCreatedAt {
				err = r.DB.QueryRow(ctx, staticTableQuery(table, "dailyCreatedAt"), op.ID, dateStr).Scan(&completedDate)
			} else {
				// Fallback to log_date if created_at not present
				var d time.Time
				err = r.DB.QueryRow(ctx, staticTableQuery(table, "dailyLogDate"), op.ID, dateStr).Scan(&d)
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
				// Static query — table name comes from a validated switch above.
				err := r.DB.QueryRow(ctx, staticTableQuery(table, "weeklyLog"), op.ID, yearNum, week).Scan(&weeklyDate)
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
				// Static query — table name comes from a validated switch above.
				err := r.DB.QueryRow(ctx, staticTableQuery(table, "monthlyLog"), op.ID, yearNum, month).Scan(&monthlyDate)
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
				// Static query — table name comes from a validated switch above.
				err := r.DB.QueryRow(ctx, staticTableQuery(table, "yearlyLog"), op.ID, yearNum).Scan(&yearlyDate)
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
			// Fetch Logs & Station Name — static query, no interpolation.
			logRows, err := r.DB.Query(ctx, staticTableQuery(table, "periodLogs"), op.ID, startDate, endDate)
			if err != nil {
				fmt.Printf("Error fetching logs for %s: %v\n", op.Phone, err)
			} else {
				defer logRows.Close()
				for logRows.Next() {
					var d time.Time
					var sName string
					if err := logRows.Scan(&d, &sName); err == nil {
						dateStr := d.Format("2006-01-02")
						stat.DailyStatus[dateStr] = "Completed"
						stat.StationName = sName // Update station name (last one wins)
					}
				}
				logRows.Close()
			}

			// If still unassigned, try to find *any* log to get the station name.
			// Static query — no interpolation.
			if stat.StationName == "Unassigned" {
				var lastStation string
				_ = r.DB.QueryRow(ctx, staticTableQuery(table, "lastStation"), op.ID).Scan(&lastStation)
				if lastStation != "" {
					stat.StationName = lastStation
				}
			}
		}
		stats = append(stats, stat)
	}

	return stats, nil
}
