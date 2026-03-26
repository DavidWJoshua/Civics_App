package auth

import "context"

type CitizenRepo interface {
	GetOrCreateCitizen(ctx context.Context, phone string) (string, error)
	GetUserByPhoneAndRole(ctx context.Context, phone, role string) (string, error)
}
