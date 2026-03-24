package operator

import "context"

func (s *Service) GetOperatorProfile(ctx context.Context, operatorID, role string) (*ProfileStats, error) {
	return s.Repo.GetProfileStats(ctx, operatorID, role)
}

func (s *Service) CreateOperatorProfile(ctx context.Context, operatorID string, req CreateProfileRequest) error {
	return s.Repo.CreateProfile(ctx, operatorID, req)
}

func (s *Service) UpdateOperatorProfile(ctx context.Context, operatorID string, req UpdateProfileRequest) error {
	return s.Repo.UpdateProfile(ctx, operatorID, req)
}
