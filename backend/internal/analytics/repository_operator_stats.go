package analytics

import (
	"context"
	"fmt"
	"time"
)

// --- LIFTING STATION ANALYTICS ---

func (r *Repository) GetLiftingAnalytics(ctx context.Context, startDate, endDate time.Time) (*LiftingStats, error) {
	stats := &LiftingStats{
		AbnormalConditions: make(map[string]int64),
		SumpLevelStatus:    make(map[string]int64),
		PanelStatus:        make(map[string]int64),
		EquipmentFaults:    make(map[string]int64),
		StationPerformance: []StationStat{},
	}

	// Calculate days in range for compliance calculation
	days := int(endDate.Sub(startDate).Hours() / 24)
	if days < 1 {
		days = 1
	}

	// 1. Basic Counts
	// Total Stations
	err := r.DB.QueryRow(ctx, "SELECT COUNT(*) FROM stations WHERE type = 'lifting'").Scan(&stats.TotalStations)
	if err != nil {
		return nil, err
	}

	// Active Operators (distinct operators who submitted logs in range)
	err = r.DB.QueryRow(ctx, "SELECT COUNT(DISTINCT operator_id) FROM lifting_daily_logs WHERE log_date BETWEEN $1 AND $2", startDate, endDate).Scan(&stats.ActiveOperators)
	if err != nil {
		stats.ActiveOperators = 0
	}

	// Faults
	err = r.DB.QueryRow(ctx, `
		SELECT COUNT(*) FROM faults f 
		JOIN stations s ON f.station_id = s.id 
		WHERE s.type = 'lifting' AND f.report_time BETWEEN $1 AND $2`, startDate, endDate).Scan(&stats.FaultCount)
	if err != nil {
		stats.FaultCount = 0
	}

	// 2. Submission Trend
	rows, err := r.DB.Query(ctx, `
		SELECT to_char(log_date, 'YYYY-MM-DD'), COUNT(*) 
		FROM lifting_daily_logs 
		WHERE log_date BETWEEN $1 AND $2 
		GROUP BY log_date ORDER BY log_date`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var tp TimePoint
			rows.Scan(&tp.Date, &tp.Count)
			stats.SubmissionTrend = append(stats.SubmissionTrend, tp)
		}
	}
	rows.Close()

	// 3. Pump Running Hours Trend
	rows, err = r.DB.Query(ctx, `
		SELECT to_char(log_date, 'YYYY-MM-DD'), COALESCE(AVG(hours_reading), 0)
		FROM lifting_daily_logs 
		WHERE log_date BETWEEN $1 AND $2 
		GROUP BY log_date ORDER BY log_date`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var cs ChartSeries
			rows.Scan(&cs.Label, &cs.Value)
			stats.PumpRunningHours = append(stats.PumpRunningHours, cs)
		}
	}
	rows.Close()

	// 4. Abnormal Conditions & Status Dist
	var vib, noise, leak, sumpHigh, panelFault int64
	err = r.DB.QueryRow(ctx, `
        SELECT 
            COALESCE(SUM(CASE WHEN vibration_issue THEN 1 ELSE 0 END),0),
            COALESCE(SUM(CASE WHEN noise_issue THEN 1 ELSE 0 END),0),
            COALESCE(SUM(CASE WHEN leakage_issue THEN 1 ELSE 0 END),0),
            COALESCE(SUM(CASE WHEN sump_level_status = 'High' THEN 1 ELSE 0 END),0),
            COALESCE(SUM(CASE WHEN panel_status = 'Fault' THEN 1 ELSE 0 END),0)
        FROM lifting_daily_logs
        WHERE log_date BETWEEN $1 AND $2
    `, startDate, endDate).Scan(&vib, &noise, &leak, &sumpHigh, &panelFault)

	stats.AbnormalConditions["Vibration"] = vib
	stats.AbnormalConditions["Noise"] = noise
	stats.AbnormalConditions["Leakage"] = leak
	stats.SumpLevelStatus["High"] = sumpHigh
	stats.PanelStatus["Fault"] = panelFault

	if err == nil {
		totalLogs := int64(0)
		for _, tp := range stats.SubmissionTrend {
			totalLogs += tp.Count
		}
		stats.SumpLevelStatus["Normal"] = totalLogs - stats.SumpLevelStatus["High"]
		stats.PanelStatus["Normal"] = totalLogs - stats.PanelStatus["Fault"]
	}

	// 5. Station Performance (Ward-wise Compliance)
	// Fetch log counts per station
	rows, err = r.DB.Query(ctx, `
		SELECT s.name, s.type, COUNT(l.id)
		FROM stations s
		LEFT JOIN lifting_daily_logs l ON s.id = l.station_id AND l.log_date BETWEEN $1 AND $2
		WHERE s.type = 'lifting'
		GROUP BY s.id, s.name, s.type
	`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var ps StationStat
			var logCount int64
			rows.Scan(&ps.StationName, &ps.Type, &logCount)

			// Calculate compliance (logs / days)
			if days > 0 {
				ps.ComplianceRate = (float64(logCount) / float64(days)) * 100
				if ps.ComplianceRate > 100 {
					ps.ComplianceRate = 100
				}
			}
			stats.StationPerformance = append(stats.StationPerformance, ps)
		}
	} else {
		fmt.Println("Error fetching station performance:", err) // Basic logging
	}
	// Note: Fault count per station strictly needs another join or query, simplifying for now

	// Calculate overall Submission Rate
	expectedLogs := stats.TotalStations * int64(days)
	totalLogs := int64(0)
	for _, tp := range stats.SubmissionTrend {
		totalLogs += tp.Count
	}
	if expectedLogs > 0 {
		stats.LogSubmissionRate = (float64(totalLogs) / float64(expectedLogs)) * 100
	}

	return stats, nil
}

// --- PUMPING STATION ANALYTICS ---

func (r *Repository) GetPumpingAnalytics(ctx context.Context, startDate, endDate time.Time) (*PumpingStats, error) {
	stats := &PumpingStats{
		PumpsRunningDist: make(map[string]int64),
		CleanlinessDist:  make(map[string]int64),
	}

	// 1. KPIs
	err := r.DB.QueryRow(ctx, "SELECT COUNT(*) FROM stations WHERE type = 'pumping'").Scan(&stats.TotalStations)
	if err != nil {
		return nil, err
	}

	var avgFlow, avgPF float64
	err = r.DB.QueryRow(ctx, `
        SELECT 
            COALESCE(AVG(flow_rate), 0),
            COALESCE(AVG(power_factor), 0)
        FROM pumping_daily_logs
        WHERE log_date BETWEEN $1 AND $2
    `, startDate, endDate).Scan(&avgFlow, &avgPF)
	stats.AvgFlowRate = avgFlow
	stats.AvgPowerFactor = avgPF

	// 2. Trends (Flow, Pressure)
	rows, err := r.DB.Query(ctx, `
		SELECT to_char(log_date, 'YYYY-MM-DD'), COALESCE(AVG(flow_rate), 0)
		FROM pumping_daily_logs 
		WHERE log_date BETWEEN $1 AND $2 
		GROUP BY log_date ORDER BY log_date`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var cs ChartSeries
			rows.Scan(&cs.Label, &cs.Value)
			stats.FlowRateTrend = append(stats.FlowRateTrend, cs)
		}
	}
	rows.Close()

	rows, err = r.DB.Query(ctx, `
		SELECT to_char(log_date, 'YYYY-MM-DD'), COALESCE(AVG(outlet_pressure), 0)
		FROM pumping_daily_logs 
		WHERE log_date BETWEEN $1 AND $2 
		GROUP BY log_date ORDER BY log_date`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var cs ChartSeries
			rows.Scan(&cs.Label, &cs.Value)
			stats.PressureTrend = append(stats.PressureTrend, cs)
		}
	}
	rows.Close()

	// 3. Station Performance (Efficiency Trend placeholder)
	// For now, listing stations with average flow rate in the period
	rows, err = r.DB.Query(ctx, `
		SELECT s.name, s.type, COALESCE(AVG(l.flow_rate), 0)
		FROM stations s
		LEFT JOIN pumping_daily_logs l ON s.id = l.station_id AND l.log_date BETWEEN $1 AND $2
		WHERE s.type = 'pumping'
		GROUP BY s.id, s.name, s.type
	`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var ps StationStat
			var avgFlow float64
			rows.Scan(&ps.StationName, &ps.Type, &avgFlow)
			// Using ComplianceRate field to store Avg Flow for now as a makeshift metric
			ps.ComplianceRate = avgFlow
			stats.StationPerformance = append(stats.StationPerformance, ps)
		}
	}

	return stats, nil
}

// --- STP ANALYTICS ---

func (r *Repository) GetSTPAnalytics(ctx context.Context, startDate, endDate time.Time) (*STPStats, error) {
	stats := &STPStats{}

	err := r.DB.QueryRow(ctx, "SELECT COUNT(*) FROM stations WHERE type = 'stp'").Scan(&stats.TotalSTPs)
	if err != nil {
		return nil, err
	}

	// Avg Parameters
	err = r.DB.QueryRow(ctx, `
        SELECT 
            COALESCE(AVG(outlet_bod), 0),
            COALESCE(AVG(outlet_cod), 0),
            COALESCE(AVG(outlet_tss), 0)
        FROM stp_daily_logs
        WHERE log_date BETWEEN $1 AND $2
    `, startDate, endDate).Scan(&stats.AvgBOD, &stats.AvgCOD, &stats.AvgTSS)

	// BOD Trend (Multi-line: Inlet vs Outlet)
	rows, err := r.DB.Query(ctx, `
		SELECT to_char(log_date, 'YYYY-MM-DD'), COALESCE(AVG(inlet_bod), 0), COALESCE(AVG(outlet_bod), 0)
		FROM stp_daily_logs 
		WHERE log_date BETWEEN $1 AND $2 
		GROUP BY log_date ORDER BY log_date`, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var ms MultiLineSeries
			rows.Scan(&ms.Label, &ms.Value1, &ms.Value2)
			stats.BODTrend = append(stats.BODTrend, ms)
		}
	}
	rows.Close()

	// Calculate Risk Index (Percentage of logs with parameters exceeding limits)
	// Limits: BOD > 30, COD > 250, TSS > 100 (Example Indu standard)
	var totalLogs, riskyLogs int64
	err = r.DB.QueryRow(ctx, `
		SELECT COUNT(*), 
		COUNT(*) FILTER (WHERE outlet_bod > 30 OR outlet_cod > 250 OR outlet_tss > 100)
		FROM stp_daily_logs
		WHERE log_date BETWEEN $1 AND $2
	`, startDate, endDate).Scan(&totalLogs, &riskyLogs)

	if err == nil && totalLogs > 0 {
		stats.RiskIndex = (float64(riskyLogs) / float64(totalLogs)) * 10.0 // Scale 0-10
	}

	// Parameter Compliance: days within vs outside standard limits
	// BOD <= 30, COD <= 250, TSS <= 100  (CPCB standards)
	var bodOk, bodFail, codOk, codFail, tssOk, tssFail int64
	err = r.DB.QueryRow(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE outlet_bod <= 30),
			COUNT(*) FILTER (WHERE outlet_bod >  30),
			COUNT(*) FILTER (WHERE outlet_cod <= 250),
			COUNT(*) FILTER (WHERE outlet_cod >  250),
			COUNT(*) FILTER (WHERE outlet_tss <= 100),
			COUNT(*) FILTER (WHERE outlet_tss >  100)
		FROM stp_daily_logs
		WHERE log_date BETWEEN $1 AND $2
	`, startDate, endDate).Scan(&bodOk, &bodFail, &codOk, &codFail, &tssOk, &tssFail)

	if err == nil {
		calcPct := func(ok, fail int64) float64 {
			total := ok + fail
			if total == 0 {
				return 0
			}
			return (float64(ok) / float64(total)) * 100
		}
		stats.ParameterCompliance = []ParameterCompliance{
			{
				ParamName:     "BOD",
				DaysOk:        bodOk,
				DaysFail:      bodFail,
				TotalDays:     bodOk + bodFail,
				CompliancePct: calcPct(bodOk, bodFail),
				Limit:         "≤ 30 mg/L",
			},
			{
				ParamName:     "COD",
				DaysOk:        codOk,
				DaysFail:      codFail,
				TotalDays:     codOk + codFail,
				CompliancePct: calcPct(codOk, codFail),
				Limit:         "≤ 250 mg/L",
			},
			{
				ParamName:     "TSS",
				DaysOk:        tssOk,
				DaysFail:      tssFail,
				TotalDays:     tssOk + tssFail,
				CompliancePct: calcPct(tssOk, tssFail),
				Limit:         "≤ 100 mg/L",
			},
		}
	}

	return stats, nil
}
