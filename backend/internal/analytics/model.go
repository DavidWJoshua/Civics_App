package analytics

import "time"

// --- Overview KPIs ---
type OverviewStats struct {
	TotalComplaints    int64            `json:"total_complaints"`
	StatusCounts       map[string]int64 `json:"status_counts"` // Raised, Assigned, etc.
	SLABreaches        int64            `json:"sla_breaches"`
	ActiveEscalations  int64            `json:"active_escalations"`
	PendingBudgets     int64            `json:"pending_budgets"`
	WardWiseComplaints map[string]int64 `json:"ward_wise_complaints"`
}

// --- Complaint Analytics ---
type ComplaintAnalytics struct {
	TrendData          []TimePoint      `json:"trend_data"` // Grouped by day/week
	SeverityCounts     map[string]int64 `json:"severity_counts"`
	CategoryCounts     map[string]int64 `json:"category_counts"`
	AvgResolutionHours float64          `json:"avg_resolution_hours"`
	OfficerPerformance []OfficerStat    `json:"officer_performance"`
}

type TimePoint struct {
	Date  string `json:"date"`
	Count int64  `json:"count"`
}

type OfficerStat struct {
	OfficerName     string `json:"officer_name"`
	ComplaintsTotal int64  `json:"complaints_total"`
	Resolved        int64  `json:"resolved"`
	AvgTimeHours    int    `json:"avg_time_hours"` // Averaged, can stay int or float
}

// --- SLA & Escalation ---
type SLAStats struct {
	TotalBreaches  int64            `json:"total_breaches"`
	ComplianceRate float64          `json:"compliance_rate"` // Percentage
	BreachByRole   map[string]int64 `json:"breach_by_role"`  // FO, JE, Commissioner
	RecentBreaches []BreachItem     `json:"recent_breaches"`
}

type BreachItem struct {
	ComplaintID string    `json:"complaint_id"`
	BreachedAt  time.Time `json:"breached_at"`
	Role        string    `json:"role"`
	Reason      string    `json:"reason"`
}

// --- Operator Monitoring (General & Specific) ---

// OperatorStats (General - legacy support or high level)
type OperatorStats struct {
	ComplianceRate    float64          `json:"compliance_rate"` // Overall % logs submitted
	StationCompliance []StationStat    `json:"station_compliance"`
	FaultsBySeverity  map[string]int64 `json:"faults_by_severity"`
	TotalEnergyKWH    float64          `json:"total_energy_kwh"`
}

type StationStat struct {
	StationName    string  `json:"station_name"`
	Type           string  `json:"type"`
	ComplianceRate float64 `json:"compliance_rate"`
	FaultCount     int64   `json:"fault_count"`
}

// --- Lifting Station Specifics ---
type LiftingStats struct {
	TotalStations      int64            `json:"total_stations"`
	ActiveOperators    int64            `json:"active_operators"`
	LogSubmissionRate  float64          `json:"log_submission_rate"`
	FaultCount         int64            `json:"fault_count"`
	SubmissionTrend    []TimePoint      `json:"submission_trend"`
	PumpRunningHours   []ChartSeries    `json:"pump_running_hours"` // Date vs Avg Hours
	VoltageTrend       []ChartSeries    `json:"voltage_trend"`
	CurrentTrend       []ChartSeries    `json:"current_trend"`
	AbnormalConditions map[string]int64 `json:"abnormal_conditions"` // Vibration, Noise, etc.
	SumpLevelStatus    map[string]int64 `json:"sump_level_status"`
	PanelStatus        map[string]int64 `json:"panel_status"`
	EquipmentFaults    map[string]int64 `json:"equipment_faults"`
	StationPerformance []StationStat    `json:"station_performance"`
}

// --- Pumping Station Specifics ---
type PumpingStats struct {
	TotalStations       int64            `json:"total_stations"`
	AvgFlowRate         float64          `json:"avg_flow_rate"`
	AvgPowerFactor      float64          `json:"avg_power_factor"`
	FaultCount          int64            `json:"fault_count"`
	FlowRateTrend       []ChartSeries    `json:"flow_rate_trend"`
	PressureTrend       []ChartSeries    `json:"pressure_trend"`
	EnergyTrend         []ChartSeries    `json:"energy_trend"`
	PumpsRunningDist    map[string]int64 `json:"pumps_running_dist"`
	CleanlinessDist     map[string]int64 `json:"cleanliness_dist"`
	PreventiveMaintRate float64          `json:"preventive_maint_rate"`
	StationPerformance  []StationStat    `json:"station_performance"`
}

// --- STP Plant Specifics ---

// ParameterCompliance describes how many days a parameter was within ideal limits
type ParameterCompliance struct {
	ParamName     string  `json:"param_name"`
	DaysOk        int64   `json:"days_ok"`
	DaysFail      int64   `json:"days_fail"`
	TotalDays     int64   `json:"total_days"`
	CompliancePct float64 `json:"compliance_pct"`
	Limit         string  `json:"limit"`
}

type STPStats struct {
	TotalSTPs           int64                 `json:"total_stps"`
	ComplianceRate      float64               `json:"compliance_rate"`
	AvgBOD              float64               `json:"avg_bod"`
	AvgCOD              float64               `json:"avg_cod"`
	AvgTSS              float64               `json:"avg_tss"`
	PollutionFlags      int64                 `json:"pollution_flags"`
	BODTrend            []MultiLineSeries     `json:"bod_trend"`
	CODTrend            []MultiLineSeries     `json:"cod_trend"`
	TSSTrend            []ChartSeries         `json:"tss_trend"`
	EfficiencyTrend     []ChartSeries         `json:"efficiency_trend"`
	ChemicalUsage       []ChartSeries         `json:"chemical_usage"`
	RiskIndex           float64               `json:"risk_index"`
	ParameterCompliance []ParameterCompliance `json:"parameter_compliance"`
}

// --- Shared Chart Structs ---
type ChartSeries struct {
	Label string  `json:"label"` // Date or Category
	Value float64 `json:"value"`
}

type MultiLineSeries struct {
	Label  string  `json:"label"`
	Value1 float64 `json:"value1"` // e.g. Inlet
	Value2 float64 `json:"value2"` // e.g. Outlet
}

// --- Operator Task Matrix ---
type OperatorTaskMatrix struct {
	TotalOperators int64                `json:"total_operators"`
	Tasks          []OperatorTaskStatus `json:"tasks"`
}

type OperatorTaskStatus struct {
	OperatorName string            `json:"operator_name"`
	StationName  string            `json:"station_name"`
	StationType  string            `json:"station_type"`
	Daily        map[string]string `json:"daily"`   // Date -> "Completed" | "Pending"
	Weekly       map[string]string `json:"weekly"`  // WeekStart -> Status
	Monthly      map[string]string `json:"monthly"` // Month -> Status
	Yearly       string            `json:"yearly"`  // Status
}

// --- Report Generation ---
type ReportRequest struct {
	Type      string `json:"type" binding:"required"` // 'complaints', 'sla', 'operator', 'budget', 'lifting', 'pumping', 'stp'
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
	Format    string `json:"format"` // 'pdf', 'excel'
}
