package complaint

import "context"

type Service struct {
	Repo *Repository
}

func (s *Service) RaiseComplaint(
	ctx context.Context,
	citizenID string,
	req CreateComplaintRequest,
) (string, error) {

	return s.Repo.CreateComplaintWithAssignmentTx(ctx, citizenID, req)
}

func (s *Service) GetComplaints(ctx context.Context, citizenID string) ([]Complaint, error) {
	return s.Repo.GetComplaintsByCitizen(ctx, citizenID)
}

func (s *Service) SubmitFeedback(ctx context.Context, citizenID, complaintID string, rating int, feedback string) error {
	return s.Repo.UpdateFeedback(ctx, citizenID, complaintID, rating, feedback)
}
