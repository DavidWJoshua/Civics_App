package field_officer

import "time"

type OfficerProfile struct {
	UserID    string    `json:"user_id"`
	Name      string    `json:"name"`
	Shift     string    `json:"shift"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	WardFrom  int       `json:"ward_from"`
	WardTo    int       `json:"ward_to"`
}

type DashboardStats struct {
	Raised       int `json:"raised"`
	Completed    int `json:"completed"`
	Rejected     int `json:"rejected"`
	NotCompleted int `json:"not_completed"`
}

type RaisedComplaint struct {
	ID                 string    `json:"id"`
	Category           string    `json:"category"`
	Severity           string    `json:"severity"`
	Latitude           float64   `json:"latitude"`
	Longitude          float64   `json:"longitude"`
	PhotoURL           *string   `json:"photo_url"`
	CompletionPhotoURL *string   `json:"completion_photo_url,omitempty"`
	Area               string    `json:"area"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
	RejectionReason    string    `json:"rejection_reason,omitempty"`
	Rating             int       `json:"rating,omitempty"`
	Feedback           string    `json:"feedback,omitempty"`
	Ward               string    `json:"ward"`
}

type ComplaintFilter struct {
	Area      string
	Severity  string
	Category  string
	Ward      string
	StartDate string
	EndDate   string
}

type AcceptComplaintRequest struct {
	ComplaintID   string  `json:"complaint_id" binding:"required"`
	EstimatedCost float64 `json:"estimated_cost" binding:"required"`
	EstimatedDays int     `json:"estimated_days" binding:"required"`
}

type RejectComplaintRequest struct {
	ComplaintID string `json:"complaint_id" binding:"required"`
	Reason      string `json:"reason" binding:"required"`
}

type CompleteComplaintRequest struct {
	ComplaintID string  `json:"complaint_id" binding:"required"`
	Latitude    float64 `json:"latitude" binding:"required"`
	Longitude   float64 `json:"longitude" binding:"required"`
}
