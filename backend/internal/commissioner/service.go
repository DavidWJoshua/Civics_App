package commissioner

import "context"

type Service struct {
	Repo *Repository
}

func (s *Service) GetProfile(ctx context.Context, userID string) (*CommissionerProfile, error) {
	return s.Repo.GetProfile(ctx, userID)
}

func (s *Service) Dashboard(ctx context.Context) (*CommissionerDashboardStats, error) {
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
func (s *Service) ComplaintDetails(ctx context.Context, id string) (*ComplaintDetails, error) {
	return s.Repo.GetComplaintDetails(ctx, id)
}
func (s *Service) GetAllComplaints(ctx context.Context, filter ComplaintFilter) ([]ComplaintDetails, error) {
	return s.Repo.GetAllComplaints(ctx, filter)
}
