package operator

import (
	"encoding/json"
	"time"
)

// Station represents a pumping/lifting/stp station
type Station struct {
	ID          int     `json:"id" db:"id"`
	Name        string  `json:"name" db:"name"`
	Type        string  `json:"type" db:"type"` // lifting, pumping, stp
	WardNumber  string  `json:"ward_number" db:"ward_number"`
	Capacity    float64 `json:"capacity" db:"capacity"`
	ProcessType string  `json:"process_type" db:"process_type"`
}

// Equipment represents pumps, motors, etc.
type Equipment struct {
	ID        int             `json:"id" db:"id"`
	StationID int             `json:"station_id" db:"station_id"`
	Name      string          `json:"name" db:"name"`
	Type      string          `json:"type" db:"type"`
	Details   json.RawMessage `json:"details" db:"details"`
}

// Fault represents a reported issue
type Fault struct {
	ID                  int        `json:"id" db:"id"`
	StationID           int        `json:"station_id" db:"station_id"`
	EquipmentID         *int       `json:"equipment_id" db:"equipment_id"`
	ReportedBy          string     `json:"reported_by" db:"reported_by"`
	ReportTime          time.Time  `json:"report_time" db:"report_time"`
	FaultType           string     `json:"fault_type" db:"fault_type" binding:"omitempty,max=200"`
	Severity            string     `json:"severity" db:"severity"`
	EmergencyShutdown   bool       `json:"emergency_shutdown" db:"emergency_shutdown"`
	EscalationRequired  bool       `json:"escalation_required" db:"escalation_required"`
	EscalatedToRole     string     `json:"escalated_to_role" db:"escalated_to_role"`
	EscalationReason    string     `json:"escalation_reason" db:"escalation_reason" binding:"omitempty,max=1000"`
	RectificationStatus string     `json:"rectification_status" db:"rectification_status"`
	RectifiedAt         *time.Time `json:"rectified_at" db:"rectified_at"`
	RectificationRemark string     `json:"rectification_remark" db:"rectification_remark" binding:"omitempty,max=1000"`
}

// --- Lifting Logs ---

type LiftingDailyLog struct {
	ID              int       `json:"id" db:"id"`
	StationID       int       `json:"station_id" db:"station_id"`
	OperatorID      string    `json:"operator_id" db:"operator_id"`
	LogDate         string    `json:"log_date" db:"log_date"` // YYYY-MM-DD
	ShiftType       string    `json:"shift_type" db:"shift_type"`
	EquipmentID     *int      `json:"equipment_id" db:"equipment_id"`
	PumpStatus      string    `json:"pump_status" db:"pump_status"`
	HoursReading    float64   `json:"hours_reading" db:"hours_reading"`
	Voltage         float64   `json:"voltage" db:"voltage"`
	CurrentReading  float64   `json:"current_reading" db:"current_reading"`
	VibrationIssue  bool      `json:"vibration_issue" db:"vibration_issue"`
	NoiseIssue      bool      `json:"noise_issue" db:"noise_issue"`
	LeakageIssue    bool      `json:"leakage_issue" db:"leakage_issue"`
	SumpLevelStatus string    `json:"sump_level_status" db:"sump_level_status"`
	PanelStatus     string    `json:"panel_status" db:"panel_status"`
	CleaningDone    bool      `json:"cleaning_done" db:"cleaning_done"`
	Remark          string    `json:"remark" db:"remark" binding:"omitempty,max=1000"`
	PhotoURL        string    `json:"photo_url" db:"photo_url"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
}

type LiftingWeeklyLog struct {
	ID              int    `json:"id" db:"id"`
	EquipmentID     int    `json:"equipment_id" db:"equipment_id"`
	OperatorID      string `json:"operator_id" db:"operator_id"`
	LogDate         string `json:"log_date" db:"log_date"`
	LubricationDone bool   `json:"lubrication_done" db:"lubrication_done"`
	BeltCheckStatus string `json:"belt_check_status" db:"belt_check_status"`
	ValveStatus     string `json:"valve_status" db:"valve_status"`
	PanelCleaned    bool   `json:"panel_cleaned" db:"panel_cleaned"`
	EarthingStatus  string `json:"earthing_status" db:"earthing_status"`
	StandbyPumpTest bool   `json:"standby_pump_test" db:"standby_pump_test"`
	MinorFault      bool   `json:"minor_fault" db:"minor_fault"`
	Remark          string `json:"remark" db:"remark" binding:"omitempty,max=1000"`
	PhotoURL        string `json:"photo_url" db:"photo_url"`
}

type LiftingMonthlyLog struct {
	ID                   int     `json:"id" db:"id"`
	EquipmentID          int     `json:"equipment_id" db:"equipment_id"`
	OperatorID           string  `json:"operator_id" db:"operator_id"`
	LogDate              string  `json:"log_date" db:"log_date"`
	InsulationTestStatus string  `json:"insulation_test_status" db:"insulation_test_status"`
	BearingCondition     string  `json:"bearing_condition" db:"bearing_condition"`
	AlignmentStatus      string  `json:"alignment_status" db:"alignment_status"`
	FoundationBoltStatus string  `json:"foundation_bolt_status" db:"foundation_bolt_status"`
	StarterPanelStatus   string  `json:"starter_panel_status" db:"starter_panel_status"`
	LoadTestDone         bool    `json:"load_test_done" db:"load_test_done"`
	EnergyConsumption    float64 `json:"energy_consumption" db:"energy_consumption"`
}

type LiftingYearlyLog struct {
	ID                   int    `json:"id" db:"id"`
	EquipmentID          int    `json:"equipment_id" db:"equipment_id"`
	OperatorID           string `json:"operator_id" db:"operator_id"`
	LogDate              string `json:"log_date" db:"log_date"`
	OverhaulDone         bool   `json:"overhaul_done" db:"overhaul_done"`
	RewindingDone        bool   `json:"rewinding_done" db:"rewinding_done"`
	ImpellerCondition    string `json:"impeller_condition" db:"impeller_condition"`
	SealReplaced         bool   `json:"seal_replaced" db:"seal_replaced"`
	CalibrationDone      bool   `json:"calibration_done" db:"calibration_done"`
	CapacityTestResult   string `json:"capacity_test_result" db:"capacity_test_result"`
	SafetyAuditDone      bool   `json:"safety_audit_done" db:"safety_audit_done"`
	ThirdPartyInspection bool   `json:"third_party_inspection" db:"third_party_inspection"`
	CertificateURL       string `json:"certificate_url" db:"certificate_url"`
}

// --- Pumping Logs ---

type PumpingDailyLog struct {
	ID                int     `json:"id" db:"id"`
	StationID         int     `json:"station_id" db:"station_id"`
	OperatorID        string  `json:"operator_id" db:"operator_id"`
	LogDate           string  `json:"log_date" db:"log_date"`
	ShiftType         string  `json:"shift_type" db:"shift_type"`
	PumpsRunningCount int     `json:"pumps_running_count" db:"pumps_running_count"`
	InletLevelStatus  string  `json:"inlet_level_status" db:"inlet_level_status"`
	OutletPressure    float64 `json:"outlet_pressure" db:"outlet_pressure"`
	FlowRate          float64 `json:"flow_rate" db:"flow_rate"`
	Voltage           float64 `json:"voltage" db:"voltage"`
	CurrentReading    float64 `json:"current_reading" db:"current_reading"`
	PowerFactor       float64 `json:"power_factor" db:"power_factor"`
	VibrationIssue    bool    `json:"vibration_issue" db:"vibration_issue"`
	NoiseIssue        bool    `json:"noise_issue" db:"noise_issue"`
	LeakageIssue      bool    `json:"leakage_issue" db:"leakage_issue"`
	PanelAlarmStatus  string  `json:"panel_alarm_status" db:"panel_alarm_status"`
	SumpCleanliness   string  `json:"sump_cleanliness" db:"sump_cleanliness"`
	ScreenBarCleaned  bool    `json:"screen_bar_cleaned" db:"screen_bar_cleaned"`
	Remark            string  `json:"remark" db:"remark" binding:"omitempty,max=1000"`
	PhotoURL          string  `json:"photo_url" db:"photo_url"`
}

type PumpingWeeklyLog struct {
	ID              int    `json:"id" db:"id"`
	StationID       int    `json:"station_id" db:"station_id"`
	OperatorID      string `json:"operator_id" db:"operator_id"`
	LogDate         string `json:"log_date" db:"log_date"`
	LubricationDone bool   `json:"lubrication_done" db:"lubrication_done"`
	ValveCheck      string `json:"valve_check" db:"valve_check"`
	StandbyTest     bool   `json:"standby_test" db:"standby_test"`
	PanelCleaned    bool   `json:"panel_cleaned" db:"panel_cleaned"`
	EarthingStatus  string `json:"earthing_status" db:"earthing_status"`
	CableCondition  string `json:"cable_condition" db:"cable_condition"`
	MinorFault      bool   `json:"minor_fault" db:"minor_fault"`
	Remark          string `json:"remark" db:"remark" binding:"omitempty,max=1000"`
	PhotoURL        string `json:"photo_url" db:"photo_url"`
}

type PumpingMonthlyLog struct {
	ID                   int     `json:"id" db:"id"`
	EquipmentID          int     `json:"equipment_id" db:"equipment_id"`
	OperatorID           string  `json:"operator_id" db:"operator_id"`
	LogDate              string  `json:"log_date" db:"log_date"`
	InsulationResistance float64 `json:"insulation_resistance" db:"insulation_resistance"`
	BearingCondition     string  `json:"bearing_condition" db:"bearing_condition"`
	AlignmentStatus      string  `json:"alignment_status" db:"alignment_status"`
	FoundationBoltStatus string  `json:"foundation_bolt_status" db:"foundation_bolt_status"`
	StarterTestStatus    string  `json:"starter_test_status" db:"starter_test_status"`
	LoadTestDone         bool    `json:"load_test_done" db:"load_test_done"`
	EnergyConsumption    float64 `json:"energy_consumption" db:"energy_consumption"`
	PreventiveAction     string  `json:"preventive_action" db:"preventive_action" binding:"omitempty,max=1000"`
	Remark               string  `json:"remark" db:"remark" binding:"omitempty,max=1000"`
}

type PumpingYearlyLog struct {
	ID                 int    `json:"id" db:"id"`
	EquipmentID        int    `json:"equipment_id" db:"equipment_id"`
	OperatorID         string `json:"operator_id" db:"operator_id"`
	LogDate            string `json:"log_date" db:"log_date"`
	OverhaulDone       bool   `json:"overhaul_done" db:"overhaul_done"`
	RewindingDone      bool   `json:"rewinding_done" db:"rewinding_done"`
	ImpellerCondition  string `json:"impeller_condition" db:"impeller_condition"`
	SealReplaced       bool   `json:"seal_replaced" db:"seal_replaced"`
	CalibrationDone    bool   `json:"calibration_done" db:"calibration_done"`
	CapacityTestResult string `json:"capacity_test_result" db:"capacity_test_result"`
	SafetyAuditDone    bool   `json:"safety_audit_done" db:"safety_audit_done"`
	InspectionFlag     bool   `json:"inspection_flag" db:"inspection_flag"`
	Remark             string `json:"remark" db:"remark" binding:"omitempty,max=1000"`
}

// --- STP Logs ---

type STPDailyLog struct {
	ID                  int     `json:"id" db:"id"`
	StationID           int     `json:"station_id" db:"station_id"`
	OperatorID          string  `json:"operator_id" db:"operator_id"`
	LogDate             string  `json:"log_date" db:"log_date"`
	InletFlowRate       float64 `json:"inlet_flow_rate" db:"inlet_flow_rate"`
	InletPH             float64 `json:"inlet_ph" db:"inlet_ph"`
	InletBOD            float64 `json:"inlet_bod" db:"inlet_bod"`
	InletCOD            float64 `json:"inlet_cod" db:"inlet_cod"`
	InletTSS            float64 `json:"inlet_tss" db:"inlet_tss"`
	InletOilGrease      float64 `json:"inlet_oil_grease" db:"inlet_oil_grease"`
	InletTemp           float64 `json:"inlet_temp" db:"inlet_temp"`
	InletColorOdour     string  `json:"inlet_color_odour" db:"inlet_color_odour"`
	DOLevel             float64 `json:"do_level" db:"do_level"`
	MLSS                float64 `json:"mlss" db:"mlss"`
	MCRT                float64 `json:"mcrt" db:"mcrt"`
	SV30                float64 `json:"sv30" db:"sv30"`
	FMRatio             float64 `json:"fm_ratio" db:"fm_ratio"`
	BlowerHours         float64 `json:"blower_hours" db:"blower_hours"`
	SludgeDepth         float64 `json:"sludge_depth" db:"sludge_depth"`
	RASFlow             float64 `json:"ras_flow" db:"ras_flow"`
	WASFlow             float64 `json:"was_flow" db:"was_flow"`
	ScumPresent         bool    `json:"scum_present" db:"scum_present"`
	OutletFlowRate      float64 `json:"outlet_flow_rate" db:"outlet_flow_rate"`
	OutletPH            float64 `json:"outlet_ph" db:"outlet_ph"`
	OutletBOD           float64 `json:"outlet_bod" db:"outlet_bod"`
	OutletCOD           float64 `json:"outlet_cod" db:"outlet_cod"`
	OutletTSS           float64 `json:"outlet_tss" db:"outlet_tss"`
	OutletOilGrease     float64 `json:"outlet_oil_grease" db:"outlet_oil_grease"`
	OutletFecalColiform float64 `json:"outlet_fecal_coliform" db:"outlet_fecal_coliform"`
	ResidualChlorine    float64 `json:"residual_chlorine" db:"residual_chlorine"`
	SludgeGenerated     float64 `json:"sludge_generated" db:"sludge_generated"`
	SludgeDried         float64 `json:"sludge_dried" db:"sludge_dried"`
	MoistureContent     float64 `json:"moisture_content" db:"moisture_content"`
	DisposalMethod      string  `json:"disposal_method" db:"disposal_method"`
	DryingBedCondition  string  `json:"drying_bed_condition" db:"drying_bed_condition"`
	PowerKWH            float64 `json:"power_kwh" db:"power_kwh"`
	EnergyPerMLD        float64 `json:"energy_per_mld" db:"energy_per_mld"`
	ChlorineUsage       float64 `json:"chlorine_usage" db:"chlorine_usage"`
	PolymerUsage        float64 `json:"polymer_usage" db:"polymer_usage"`
	ChemicalStockStatus string  `json:"chemical_stock_status" db:"chemical_stock_status"`
}

type STPMaintenanceLog struct {
	ID                   int    `json:"id" db:"id"`
	StationID            int    `json:"station_id" db:"station_id"`
	OperatorID           string `json:"operator_id" db:"operator_id"`
	LogDate              string `json:"log_date" db:"log_date"`
	Type                 string `json:"type" db:"type"` // weekly or monthly
	BlowerMaintDone      bool   `json:"blower_maint_done" db:"blower_maint_done"`
	DiffuserCleaningDone bool   `json:"diffuser_cleaning_done" db:"diffuser_cleaning_done"`
	ClarifierCheck       string `json:"clarifier_check" db:"clarifier_check"`
	LabCalibrated        bool   `json:"lab_calibrated" db:"lab_calibrated"`
	AnalyzerStatus       string `json:"analyzer_status" db:"analyzer_status"`
}

type STPMonthlyLog struct {
	ID                 int    `json:"id" db:"id"`
	StationID          int    `json:"station_id" db:"station_id"`
	OperatorID         string `json:"operator_id" db:"operator_id"`
	LogDate            string `json:"log_date" db:"log_date"`
	PumpMaintStatus    string `json:"pump_maint_status" db:"pump_maint_status"`
	MotorServiceDone   string `json:"motor_service_done" db:"motor_service_done"`
	ValveLubrication   string `json:"valve_lubrication" db:"valve_lubrication"`
	PanelInspection    string `json:"panel_inspection" db:"panel_inspection"`
	EmergencyPowerTest bool   `json:"emergency_power_test" db:"emergency_power_test"`
	SandFilterStatus   string `json:"sand_filter_status" db:"sand_filter_status"`
	CarbonFilterStatus string `json:"carbon_filter_status" db:"carbon_filter_status"`
	Remark             string `json:"remark" db:"remark" binding:"omitempty,max=1000"`
	PhotoURL           string `json:"photo_url" db:"photo_url"`
}

type STPYearlyLog struct {
	ID                    int    `json:"id" db:"id"`
	StationID             int    `json:"station_id" db:"station_id"`
	OperatorID            string `json:"operator_id" db:"operator_id"`
	LogDate               string `json:"log_date" db:"log_date"`
	StructuralAudit       bool   `json:"structural_audit" db:"structural_audit"`
	TankCleaning          bool   `json:"tank_cleaning" db:"tank_cleaning"`
	SludgeUnitOverhaul    bool   `json:"sludge_unit_overhaul" db:"sludge_unit_overhaul"`
	ElectricalSafetyAudit bool   `json:"electrical_safety_audit" db:"electrical_safety_audit"`
	InstrumentCalibration string `json:"instrument_calibration" db:"instrument_calibration" binding:"omitempty,max=500"`
	GritChamberService    string `json:"grit_chamber_service" db:"grit_chamber_service" binding:"omitempty,max=500"`
	Remark                string `json:"remark" db:"remark" binding:"omitempty,max=1000"`
	PhotoURL              string `json:"photo_url" db:"photo_url"`
}

