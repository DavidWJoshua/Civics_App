package junior_engineer

import "context"

type Service struct {
	Repo *Repository
}

func (s *Service) GetProfile(ctx context.Context, userID string) (*JEProfile, error) {
	return s.Repo.GetProfile(ctx, userID)
}

func (s *Service) Dashboard(ctx context.Context) (*JEDashboardStats, error) {
	return s.Repo.GetDashboardStats(ctx)
}

func (s *Service) PendingBudgets(ctx context.Context) ([]BudgetApprovalItem, error) {
	return s.Repo.GetPendingBudgets(ctx)
}

func (s *Service) ApproveBudget(ctx context.Context, userID, complaintID string) error {
	return s.Repo.ApproveBudget(ctx, complaintID, userID)
}

func (s *Service) RejectBudget(ctx context.Context, userID, complaintID, reason string) error {
	return s.Repo.RejectBudget(ctx, complaintID, userID, reason)
}

func (s *Service) Escalations(ctx context.Context) ([]EscalationItem, error) {
	return s.Repo.GetEscalations(ctx)
}
func (s *Service) GetAllComplaints(ctx context.Context, filter ComplaintFilter) ([]JEComplaint, error) {
	return s.Repo.GetAllComplaints(ctx, filter)
}

// --------------------------------------------------
// 🔄 COMPLAINT REASSIGNMENT
// --------------------------------------------------

func (s *Service) GetComplaintsForReassignment(ctx context.Context, jeUserID string) ([]JEComplaint, error) {
	return s.Repo.GetComplaintsForReassignment(ctx, jeUserID)
}

func (s *Service) GetFieldOfficersStatus(ctx context.Context, jeUserID string) ([]FieldOfficerStatus, error) {
	return s.Repo.GetFieldOfficersStatus(ctx, jeUserID)
}

func (s *Service) ReassignComplaint(ctx context.Context, req ReassignComplaintRequest, jeUserID string) error {
	return s.Repo.ReassignComplaint(ctx, req.ComplaintID, req.NewOfficerID, jeUserID)
}
