package leave_management

import "time"

type LeaveRequest struct {
	ID          string    `json:"id" db:"id"` // UUID
	OfficerID   string    `json:"officer_id" db:"officer_id"`
	OfficerName string    `json:"officer_name,omitempty"`
	FromDate    string    `json:"from_date" db:"from_date"`                            // YYYY-MM-DD
	ToDate      string    `json:"to_date" db:"to_date"`                                // YYYY-MM-DD
	Reason      string    `json:"reason" db:"reason" binding:"omitempty,max=500"`
	Status      string    `json:"status" db:"status"`                                  // PENDING, APPROVED, REJECTED
	CreatedAt   time.Time `json:"created_at" db:"applied_at"`
}

type ApproveRejectRequest struct {
	Status string `json:"status" binding:"required,oneof=APPROVED REJECTED"`
}

type ReassignmentLog struct {
	ComplaintID       string `json:"complaint_id"`
	PreviousOfficerID string `json:"previous_officer_id"`
	NewOfficerID      string `json:"new_officer_id"`
	Reason            string `json:"reason" binding:"omitempty,max=500"`
}
