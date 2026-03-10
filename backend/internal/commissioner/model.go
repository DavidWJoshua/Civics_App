package commissioner

import "time"

type CommissionerDashboardStats struct {
	PendingBudgets int `json:"pending_budgets"`
	Escalations    int `json:"escalations"`
	Completed      int `json:"completed"`
}

type BudgetApprovalItem struct {
	ComplaintID   string    `json:"complaint_id"`
	EstimatedCost float64   `json:"estimated_cost"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
}

type EscalationItem struct {
	ComplaintID string    `json:"complaint_id"`
	FromRole    string    `json:"from_role"`
	Reason      string    `json:"reason"`
	EscalatedAt time.Time `json:"escalated_at"`
}

type ApproveBudgetRequest struct {
	ComplaintID string `json:"complaint_id" binding:"required"`
}

type RejectBudgetRequest struct {
	ComplaintID string `json:"complaint_id" binding:"required"`
	Reason      string `json:"reason" binding:"required"`
}
type ComplaintDetails struct {
	ID                 string    `json:"id"`
	Category           string    `json:"category"`
	Severity           string    `json:"severity"`
	ImageURL           *string   `json:"image_url"`
	CompletionPhotoURL *string   `json:"completion_photo_url"`
	Area               string    `json:"area"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
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

type CommissionerProfile struct {
	UserID    string    `json:"user_id"`
	Name      string    `json:"name"`
	Shift     string    `json:"shift"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	WardFrom  int       `json:"ward_from"`
	WardTo    int       `json:"ward_to"`
}
