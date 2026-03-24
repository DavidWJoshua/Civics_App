package junior_engineer

import "time"

type JEProfile struct {
	UserID    string    `json:"user_id"`
	Name      string    `json:"name"`
	Shift     string    `json:"shift"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	WardFrom  int       `json:"ward_from"`
	WardTo    int       `json:"ward_to"`
}

type ComplaintFilter struct {
	Area      string
	Severity  string
	Category  string
	Ward      string
	StartDate string
	EndDate   string
}

type JEDashboardStats struct {
	PendingBudgets int `json:"pending_budgets"`
	Escalations    int `json:"escalations"`
	Completed      int `json:"completed"`
	Rejected       int `json:"rejected"`
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
	Reason      string `json:"reason" binding:"required,max=500"`
}
type JEComplaint struct {
	ID              string    `json:"id"`
	Category        string    `json:"category"`
	Severity        string    `json:"severity"`
	PhotoURL        *string   `json:"photo_url"`
	CompletionPhoto *string   `json:"completion_photo_url"`
	Area            string    `json:"area"`
	Status          string    `json:"status"`
	CreatedAt       time.Time `json:"created_at"`
	RejectionReason string    `json:"rejection_reason,omitempty"`
	Rating          int       `json:"rating,omitempty"`
	Feedback        string    `json:"feedback,omitempty"`
	Ward            string    `json:"ward"`
}

type FieldOfficerStatus struct {
	UserID    string `json:"user_id"`
	Name      string `json:"name"`
	WardFrom  int    `json:"ward_from"`
	WardTo    int    `json:"ward_to"`
	IsActive  bool   `json:"is_active"`
	IsOnLeave bool   `json:"is_on_leave"`
}

type ReassignComplaintRequest struct {
	ComplaintID  string `json:"complaint_id" binding:"required"`
	NewOfficerID string `json:"new_officer_id" binding:"required"`
}
