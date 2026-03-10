package operator

type ProfileStats struct {
	OperatorID       string  `json:"operator_id"`
	Name             string  `json:"name"`
	Role             string  `json:"role"`
	Phone            string  `json:"phone_number"` // From users/profile
	StationID        int     `json:"station_id"`
	StationName      string  `json:"station_name"`
	StationType      string  `json:"station_type"`
	WardNumber       string  `json:"ward_number"`
	Shift            string  `json:"shift"`
	IsActive         bool    `json:"is_active"`
	TotalLogs        int     `json:"total_logs"`
	ComplianceRate   float64 `json:"compliance_rate"` // Percentage
	FaultsReported   int     `json:"faults_reported"`
	AvgEnergy        float64 `json:"avg_energy"`        // Daily avg kWh
	PerformanceScore int     `json:"performance_score"` // 0-100

	// Daily Breakdown (Last 7 Days)
	DailyLogCounts []DailyLogCount `json:"daily_log_counts"`
}

type DailyLogCount struct {
	Date  string `json:"date"`
	Count int    `json:"count"`
}

type CompliancePoint struct {
	Date string  `json:"date"`
	Rate float64 `json:"rate"`
}

type CreateProfileRequest struct {
	FullName    string `json:"full_name"`
	StationID   int    `json:"station_id"`
	StationType string `json:"station_type"`
	WardNumber  string `json:"ward_number"`
	Shift       string `json:"shift"`
}

type UpdateProfileRequest struct {
	FullName string `json:"full_name"`
	Shift    string `json:"shift"`
}
