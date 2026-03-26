package operator

import (
	"context"
	"fmt"
)

// GetProfileStats fetches aggregated statistics and profile info for an operator
func (r *Repository) GetProfileStats(ctx context.Context, operatorID, role string) (*ProfileStats, error) {
	stats := &ProfileStats{
		OperatorID: operatorID,
		Role:       role,
	}

	// 1. Fetch Profile Info from officer_profiles + stations
	// Left Join because profile might not exist yet
	queryProfile := `
		SELECT 
			COALESCE(op.name, u.name, ''),
			COALESCE(op.phone_number, u.phone_number, ''),
			COALESCE(op.station_id, 0),
			COALESCE(s.name, 'Not Assigned'),
			COALESCE(op.station_type, s.type, ''),
			COALESCE(op.ward_number, ''),
			COALESCE(op.shift, ''),
			COALESCE(op.is_active, false)
		FROM users u
		LEFT JOIN officer_profiles op ON u.id = op.user_id
		LEFT JOIN stations s ON op.station_id = s.id
		WHERE u.id = $1
	`
	err := r.DB.QueryRow(ctx, queryProfile, operatorID).Scan(
		&stats.Name,
		&stats.Phone,
		&stats.StationID,
		&stats.StationName,
		&stats.StationType,
		&stats.WardNumber,
		&stats.Shift,
		&stats.IsActive,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch profile info: %w", err)
	}

	// 2. Determine Log Table
	var logTable string
	switch role {
	case "LIFTING_OPERATOR":
		logTable = "lifting_daily_logs"
	case "PUMPING_OPERATOR":
		logTable = "pumping_daily_logs"
	case "STP_OPERATOR":
		logTable = "stp_daily_logs"
	default:
		// If unknown role, just return basic stats
		return stats, nil
	}

	// 3. Log Counts (Last 30 Days)
	queryLogs := fmt.Sprintf(`
		SELECT COUNT(DISTINCT log_date)
		FROM %s
		WHERE operator_id = $1 AND log_date >= CURRENT_DATE - INTERVAL '30 days'
	`, logTable)

	if err := r.DB.QueryRow(ctx, queryLogs, operatorID).Scan(&stats.TotalLogs); err != nil {
		return nil, err
	}

	stats.ComplianceRate = (float64(stats.TotalLogs) / 30.0) * 100
	if stats.ComplianceRate > 100 {
		stats.ComplianceRate = 100
	}

	// 4. Faults
	queryFaults := `SELECT COUNT(*) FROM faults WHERE reported_by = $1`
	r.DB.QueryRow(ctx, queryFaults, operatorID).Scan(&stats.FaultsReported)

	// 5. Avg Energy (Pumping/STP/Lifting?)
	// Lifting also has voltage/current in daily logs, maybe useful?
	// Requirement specific for Pumping/STP usually, but let's try generic approach or specific.
	// Users want "Performance Summary".
	if role == "STP_OPERATOR" {
		r.DB.QueryRow(ctx, `SELECT COALESCE(AVG(power_kwh), 0) FROM stp_daily_logs WHERE operator_id=$1`, operatorID).Scan(&stats.AvgEnergy)
	} else if role == "PUMPING_OPERATOR" {
		r.DB.QueryRow(ctx, `SELECT COALESCE(AVG(energy_consumption), 0) FROM pumping_monthly_logs WHERE operator_id=$1`, operatorID).Scan(&stats.AvgEnergy)
	}

	// 6. Score
	// Simple formula
	faultPenalty := 0.0
	if stats.FaultsReported > 0 {
		faultPenalty = float64(stats.FaultsReported) * 5 // 5 points per fault
	}
	stats.PerformanceScore = int(stats.ComplianceRate - faultPenalty)
	if stats.PerformanceScore < 0 {
		stats.PerformanceScore = 0
	}
	if stats.PerformanceScore > 100 {
		stats.PerformanceScore = 100
	}

	return stats, nil
}

func (r *Repository) CreateProfile(ctx context.Context, operatorID string, req CreateProfileRequest) error {
	// Insert into officer_profiles
	// Need to fetch phone from users first to ensure consistency or just trigger update?
	// Prompt says "Phone Number (auto-fetched from users table)".
	// We should store it in profiles as well if table has it.

	var phone string
	r.DB.QueryRow(ctx, "SELECT phone_number FROM users WHERE id=$1", operatorID).Scan(&phone)

	query := `
		INSERT INTO officer_profiles 
		(user_id, name, phone_number, station_id, station_type, ward_number, shift, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7, true)
		ON CONFLICT (user_id) DO UPDATE SET
			name = EXCLUDED.name,
			station_id = EXCLUDED.station_id,
			station_type = EXCLUDED.station_type,
			ward_number = EXCLUDED.ward_number,
			shift = EXCLUDED.shift,
			is_active = true
	`
	_, err := r.DB.Exec(ctx, query, operatorID, req.FullName, phone, req.StationID, req.StationType, req.WardNumber, req.Shift)
	return err
}

func (r *Repository) UpdateProfile(ctx context.Context, operatorID string, req UpdateProfileRequest) error {
	// Only update non-sensitive fields: Name, Shift
	// Station assignment cannot be changed by operator
	query := `
		UPDATE officer_profiles
		SET name = $2, shift = $3
		WHERE user_id = $1
	`
	_, err := r.DB.Exec(ctx, query, operatorID, req.FullName, req.Shift)
	return err
}
