package operator

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

// --- Stations & Equipment ---

func (r *Repository) GetStations(ctx context.Context) ([]Station, error) {
	rows, err := r.DB.Query(ctx, "SELECT id, name, type, ward_number, COALESCE(capacity, 0), COALESCE(process_type, '') FROM stations")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var stations []Station
	for rows.Next() {
		var s Station
		if err := rows.Scan(&s.ID, &s.Name, &s.Type, &s.WardNumber, &s.Capacity, &s.ProcessType); err != nil {
			return nil, err
		}
		stations = append(stations, s)
	}
	return stations, nil
}

func (r *Repository) GetEquipmentByStation(ctx context.Context, stationID int) ([]Equipment, error) {
	rows, err := r.DB.Query(ctx, "SELECT id, station_id, name, type, details FROM equipment WHERE station_id = $1", stationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var equipment []Equipment
	for rows.Next() {
		var e Equipment
		if err := rows.Scan(&e.ID, &e.StationID, &e.Name, &e.Type, &e.Details); err != nil {
			return nil, err
		}
		equipment = append(equipment, e)
	}
	return equipment, nil
}

// --- Lifting Logs ---

func (r *Repository) CreateLiftingDailyLog(ctx context.Context, log *LiftingDailyLog) error {
	query := `INSERT INTO lifting_daily_logs (station_id, operator_id, log_date, shift_type, equipment_id, pump_status, hours_reading, voltage, current_reading, vibration_issue, noise_issue, leakage_issue, sump_level_status, panel_status, cleaning_done, remark, photo_url) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.StationID, log.OperatorID, log.LogDate, log.ShiftType, log.EquipmentID, log.PumpStatus, log.HoursReading, log.Voltage, log.CurrentReading, log.VibrationIssue, log.NoiseIssue, log.LeakageIssue, log.SumpLevelStatus, log.PanelStatus, log.CleaningDone, log.Remark, log.PhotoURL).Scan(&log.ID)
}

// --- Pumping Logs ---

func (r *Repository) CreatePumpingDailyLog(ctx context.Context, log *PumpingDailyLog) error {
	query := `INSERT INTO pumping_daily_logs (station_id, operator_id, log_date, shift_type, pumps_running_count, inlet_level_status, outlet_pressure, flow_rate, voltage, current_reading, power_factor, vibration_issue, noise_issue, leakage_issue, panel_alarm_status, sump_cleanliness, screen_bar_cleaned, remark, photo_url) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.StationID, log.OperatorID, log.LogDate, log.ShiftType, log.PumpsRunningCount, log.InletLevelStatus, log.OutletPressure, log.FlowRate, log.Voltage, log.CurrentReading, log.PowerFactor, log.VibrationIssue, log.NoiseIssue, log.LeakageIssue, log.PanelAlarmStatus, log.SumpCleanliness, log.ScreenBarCleaned, log.Remark, log.PhotoURL).Scan(&log.ID)
}

// --- STP Logs ---

func (r *Repository) CreateSTPDailyLog(ctx context.Context, log *STPDailyLog) error {
	query := `INSERT INTO stp_daily_logs (station_id, operator_id, log_date, inlet_flow_rate, inlet_ph, inlet_bod, inlet_cod, inlet_tss, inlet_oil_grease, inlet_temp, inlet_color_odour, do_level, mlss, mcrt, sv30, fm_ratio, blower_hours, sludge_depth, ras_flow, was_flow, scum_present, outlet_flow_rate, outlet_ph, outlet_bod, outlet_cod, outlet_tss, outlet_oil_grease, outlet_fecal_coliform, residual_chlorine, sludge_generated, sludge_dried, moisture_content, disposal_method, drying_bed_condition, power_kwh, energy_per_mld, chlorine_usage, polymer_usage, chemical_stock_status) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.StationID, log.OperatorID, log.LogDate, log.InletFlowRate, log.InletPH, log.InletBOD, log.InletCOD, log.InletTSS, log.InletOilGrease, log.InletTemp, log.InletColorOdour, log.DOLevel, log.MLSS, log.MCRT, log.SV30, log.FMRatio, log.BlowerHours, log.SludgeDepth, log.RASFlow, log.WASFlow, log.ScumPresent, log.OutletFlowRate, log.OutletPH, log.OutletBOD, log.OutletCOD, log.OutletTSS, log.OutletOilGrease, log.OutletFecalColiform, log.ResidualChlorine, log.SludgeGenerated, log.SludgeDried, log.MoistureContent, log.DisposalMethod, log.DryingBedCondition, log.PowerKWH, log.EnergyPerMLD, log.ChlorineUsage, log.PolymerUsage, log.ChemicalStockStatus).Scan(&log.ID)
}

// --- Faults ---

func (r *Repository) ReportFault(ctx context.Context, fault *Fault) error {
	query := `INSERT INTO faults (station_id, equipment_id, reported_by, fault_type, severity, emergency_shutdown, escalation_required, escalated_to_role, escalation_reason) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`
	return r.DB.QueryRow(ctx, query, fault.StationID, fault.EquipmentID, fault.ReportedBy, fault.FaultType, fault.Severity, fault.EmergencyShutdown, fault.EscalationRequired, fault.EscalatedToRole, fault.EscalationReason).Scan(&fault.ID)
}

func (r *Repository) GetFaultsByStation(ctx context.Context, stationID int) ([]Fault, error) {
	query := `SELECT id, station_id, equipment_id, reported_by, report_time, fault_type, severity, emergency_shutdown, escalation_required, escalated_to_role, escalation_reason, rectification_status, rectified_at, rectification_remark FROM faults WHERE station_id = $1`
	rows, err := r.DB.Query(ctx, query, stationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var faults []Fault
	for rows.Next() {
		var f Fault
		if err := rows.Scan(&f.ID, &f.StationID, &f.EquipmentID, &f.ReportedBy, &f.ReportTime, &f.FaultType, &f.Severity, &f.EmergencyShutdown, &f.EscalationRequired, &f.EscalatedToRole, &f.EscalationReason, &f.RectificationStatus, &f.RectifiedAt, &f.RectificationRemark); err != nil {
			return nil, err
		}
	}
	return faults, nil
}

// --- Additional Lifting Logs ---

func (r *Repository) CreateLiftingWeeklyLog(ctx context.Context, log *LiftingWeeklyLog) error {
	query := `INSERT INTO lifting_weekly_logs (equipment_id, operator_id, log_date, lubrication_done, belt_check_status, valve_status, panel_cleaned, earthing_status, standby_pump_test, minor_fault, remark, photo_url) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.EquipmentID, log.OperatorID, log.LogDate, log.LubricationDone, log.BeltCheckStatus, log.ValveStatus, log.PanelCleaned, log.EarthingStatus, log.StandbyPumpTest, log.MinorFault, log.Remark, log.PhotoURL).Scan(&log.ID)
}

func (r *Repository) CreateLiftingMonthlyLog(ctx context.Context, log *LiftingMonthlyLog) error {
	query := `INSERT INTO lifting_monthly_logs (equipment_id, operator_id, log_date, insulation_test_status, bearing_condition, alignment_status, foundation_bolt_status, starter_panel_status, load_test_done, energy_consumption) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.EquipmentID, log.OperatorID, log.LogDate, log.InsulationTestStatus, log.BearingCondition, log.AlignmentStatus, log.FoundationBoltStatus, log.StarterPanelStatus, log.LoadTestDone, log.EnergyConsumption).Scan(&log.ID)
}

func (r *Repository) CreateLiftingYearlyLog(ctx context.Context, log *LiftingYearlyLog) error {
	query := `INSERT INTO lifting_yearly_logs (equipment_id, operator_id, log_date, overhaul_done, rewinding_done, impeller_condition, seal_replaced, calibration_done, capacity_test_result, safety_audit_done, third_party_inspection, certificate_url) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.EquipmentID, log.OperatorID, log.LogDate, log.OverhaulDone, log.RewindingDone, log.ImpellerCondition, log.SealReplaced, log.CalibrationDone, log.CapacityTestResult, log.SafetyAuditDone, log.ThirdPartyInspection, log.CertificateURL).Scan(&log.ID)
}

// --- Additional Pumping Logs ---

func (r *Repository) CreatePumpingWeeklyLog(ctx context.Context, log *PumpingWeeklyLog) error {
	query := `INSERT INTO pumping_weekly_logs (station_id, operator_id, log_date, lubrication_done, valve_check, standby_test, panel_cleaned, earthing_status, cable_condition, minor_fault, remark, photo_url) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.StationID, log.OperatorID, log.LogDate, log.LubricationDone, log.ValveCheck, log.StandbyTest, log.PanelCleaned, log.EarthingStatus, log.CableCondition, log.MinorFault, log.Remark, log.PhotoURL).Scan(&log.ID)
}

func (r *Repository) CreatePumpingMonthlyLog(ctx context.Context, log *PumpingMonthlyLog) error {
	query := `INSERT INTO pumping_monthly_logs (equipment_id, operator_id, log_date, insulation_resistance, bearing_condition, alignment_status, foundation_bolt_status, starter_test_status, load_test_done, energy_consumption, preventive_action, remark) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.EquipmentID, log.OperatorID, log.LogDate, log.InsulationResistance, log.BearingCondition, log.AlignmentStatus, log.FoundationBoltStatus, log.StarterTestStatus, log.LoadTestDone, log.EnergyConsumption, log.PreventiveAction, log.Remark).Scan(&log.ID)
}

func (r *Repository) CreatePumpingYearlyLog(ctx context.Context, log *PumpingYearlyLog) error {
	query := `INSERT INTO pumping_yearly_logs (equipment_id, operator_id, log_date, overhaul_done, rewinding_done, impeller_condition, seal_replaced, calibration_done, capacity_test_result, safety_audit_done, inspection_flag, remark) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.EquipmentID, log.OperatorID, log.LogDate, log.OverhaulDone, log.RewindingDone, log.ImpellerCondition, log.SealReplaced, log.CalibrationDone, log.CapacityTestResult, log.SafetyAuditDone, log.InspectionFlag, log.Remark).Scan(&log.ID)
}

// --- STP Maintenance Logs ---

func (r *Repository) CreateSTPMaintenanceLog(ctx context.Context, log *STPMaintenanceLog) error {
	query := `INSERT INTO stp_maintenance_logs (station_id, operator_id, log_date, type, blower_maint_done, diffuser_cleaning_done, clarifier_check, lab_calibrated, analyzer_status) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`
	return r.DB.QueryRow(ctx, query, log.StationID, log.OperatorID, log.LogDate, log.Type, log.BlowerMaintDone, log.DiffuserCleaningDone, log.ClarifierCheck, log.LabCalibrated, log.AnalyzerStatus).Scan(&log.ID)
}
