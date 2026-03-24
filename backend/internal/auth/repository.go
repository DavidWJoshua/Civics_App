package auth

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type otpSession struct {
	hash      string
	expiresAt time.Time
	verified  bool
}

var otpStore sync.Map

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) SaveOTP(ctx context.Context, phone, hash string) error {
	session := otpSession{
		hash:      hash,
		expiresAt: time.Now().Add(5 * time.Minute),
		verified:  false,
	}
	otpStore.Store(phone, session)
	return nil
}

func (r *Repository) GetOTP(ctx context.Context, phone string) (string, error) {
	val, ok := otpStore.Load(phone)
	if !ok {
		return "", errors.New("otp not found")
	}
	session := val.(otpSession)
	if time.Now().After(session.expiresAt) {
		otpStore.Delete(phone)
		return "", errors.New("otp expired")
	}
	return session.hash, nil
}

func (r *Repository) MarkOTPVerified(ctx context.Context, phone string) error {
	val, ok := otpStore.Load(phone)
	if !ok {
		return errors.New("otp not found")
	}
	session := val.(otpSession)
	session.verified = true
	otpStore.Store(phone, session)
	return nil
}

func (r *Repository) IsOTPValid(ctx context.Context, phone string) (string, error) {
	val, ok := otpStore.Load(phone)
	if !ok {
		return "", errors.New("otp not found")
	}
	session := val.(otpSession)
	if session.verified || time.Now().After(session.expiresAt) {
		return "", errors.New("otp invalid or expired")
	}
	return session.hash, nil
}

func (r *Repository) GetValidOTPHash(ctx context.Context, phone string) (string, error) {
	return r.IsOTPValid(ctx, phone)
}

func (r *Repository) MarkOTPUsed(ctx context.Context, phone string) error {
	return r.MarkOTPVerified(ctx, phone)
}

func (r *Repository) IsOfficer(ctx context.Context, phone string) (bool, error) {
	var role string
	// Check if user exists and has a role other than CITIZEN
	err := r.DB.QueryRow(ctx, "SELECT role FROM users WHERE phone_number = $1", phone).Scan(&role)
	if err != nil {
		// User not found or error, likely not an officer (or new citizen)
		return false, nil
	}
	// If role is ANY of the staff roles, return true
	return role != "CITIZEN", nil
}
func (r *Repository) GetUserByPhone(ctx context.Context, phone string) (string, string, error) {
	var userID string
	var role string

	err := r.DB.QueryRow(ctx, `
		SELECT id, role
		FROM users
		WHERE phone_number = $1
	`, phone).Scan(&userID, &role)

	if err != nil {
		return "", "", err
	}

	return userID, role, nil
}
