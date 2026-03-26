package field_officer

import (
	"context"
	"fmt"
)

type Service struct {
	Repo *Repository
}

func (s *Service) GetProfile(ctx context.Context, userID string) (*OfficerProfile, error) {
	return s.Repo.GetOfficerProfile(ctx, userID)
}

func (s *Service) GetDashboardStats(ctx context.Context, userID string) (*DashboardStats, error) {
	return s.Repo.GetDashboardStats(ctx, userID)
}

func (s *Service) GetRaisedComplaints(ctx context.Context, userID string, filter ComplaintFilter) ([]RaisedComplaint, error) {
	return s.Repo.GetComplaintsByStatus(ctx, userID, "ALLOCATED", filter)
}

func (s *Service) GetToDoList(ctx context.Context, userID string, filter ComplaintFilter) ([]RaisedComplaint, error) {
	return s.Repo.GetComplaintsByStatus(ctx, userID, "PENDING", filter)
}

func (s *Service) AcceptComplaint(ctx context.Context, userID string, req AcceptComplaintRequest) error {
	onLeave, err := s.Repo.IsOnLeave(ctx, userID)
	if err != nil {
		return err
	}
	if onLeave {
		return fmt.Errorf("you are currently on leave and cannot perform this action")
	}

	if err := s.Repo.CreateBudget(ctx, req.ComplaintID, req.EstimatedCost, userID); err != nil {
		return err
	}

	if err := s.Repo.CreateSLA(ctx, req.ComplaintID, req.EstimatedDays); err != nil {
		return err
	}

	return s.Repo.UpdateComplaintStatus(ctx, req.ComplaintID, "PENDING")
}

func (s *Service) RejectComplaint(ctx context.Context, userID string, req RejectComplaintRequest) error {
	onLeave, err := s.Repo.IsOnLeave(ctx, userID)
	if err != nil {
		return err
	}
	if onLeave {
		return fmt.Errorf("you are currently on leave and cannot perform this action")
	}

	// 1️⃣ Insert into complaint_rejections table
	_, err = s.Repo.DB.Exec(ctx, `
		INSERT INTO complaint_rejections
		(complaint_id, rejected_by, role, reason)
		VALUES ($1, $2, 'FIELD_OFFICER', $3)
	`, req.ComplaintID, userID, req.Reason)

	if err != nil {
		return err
	}

	// 2️⃣ Update complaint status
	return s.Repo.UpdateComplaintStatus(ctx, req.ComplaintID, "REJECTED")
}

func (s *Service) CompleteComplaint(
	ctx context.Context,
	userID string,
	req CompleteComplaintRequest,
	imageURL string,
) error {
	onLeave, err := s.Repo.IsOnLeave(ctx, userID)
	if err != nil {
		return err
	}
	if onLeave {
		return fmt.Errorf("you are currently on leave and cannot perform this action")
	}

	return s.Repo.CompleteComplaint(
		ctx,
		req.ComplaintID,
		imageURL,
		req.Latitude,
		req.Longitude,
	)
}
func (s *Service) GetCompletedComplaints(ctx context.Context, userID string, filter ComplaintFilter) ([]RaisedComplaint, error) {
	return s.Repo.GetComplaintsByStatus(ctx, userID, "COMPLETED", filter)
}

func (s *Service) GetRejectedComplaints(ctx context.Context, userID string, filter ComplaintFilter) ([]RaisedComplaint, error) {
	return s.Repo.GetComplaintsByStatus(ctx, userID, "REJECTED", filter)
}
