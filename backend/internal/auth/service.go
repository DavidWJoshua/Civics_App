package auth

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"math/big"

	"civic-complaint-system/backend/internal/common/crypto"
	"civic-complaint-system/backend/internal/common/utils"
)

type Service struct {
	Repo *Repository
	SNS  SNSSender
}

/* ---------- CRYPTO-SAFE OTP GENERATOR ---------- */

func generateOTP() (string, error) {
	// Use crypto/rand for cryptographically secure OTP
	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", fmt.Errorf("failed to generate secure OTP: %w", err)
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

/* ---------- SEND OTP ---------- */

func (s *Service) SendOTP(ctx context.Context, phone string) (bool, error) {
	// Check if account is locked out (too many failed attempts)
	if s.Repo.IsLockedOut(ctx, phone) {
		return false, errors.New("account temporarily locked due to too many failed attempts")
	}

	otp, err := generateOTP()
	if err != nil {
		return false, err
	}
	log.Println("OTP GENERATED:", otp) // Remove in production — for dev only

	hash, err := crypto.HashOTP(otp)
	if err != nil {
		return false, err
	}

	if err := s.Repo.SaveOTP(ctx, phone, hash); err != nil {
		log.Println("❌ SAVE OTP ERROR:", err)
		return false, err
	}

	message := "Your OTP for Civic Complaint System is: " + otp + ". Valid for 5 minutes. Do not share this code."
	if err := s.SNS.SendSMS(phone, message); err != nil {
		log.Println("❌ SNS SEND ERROR:", err)
		return false, err
	}

	log.Println("📨 OTP SMS SENT")

	// Only used as UI hint (not security)
	return s.Repo.IsOfficer(ctx, phone)
}

/* ---------- VERIFY OTP + LOGIN ---------- */

func (s *Service) VerifyOTPAndLogin(
	ctx context.Context,
	phone string,
	code string,
	role string,
	citizenRepo CitizenRepo,
) (accessToken string, refreshToken string, roleName string, err error) {

	// Check lockout
	if s.Repo.IsLockedOut(ctx, phone) {
		return "", "", "", errors.New("account temporarily locked due to too many failed attempts")
	}

	hash, err := s.Repo.GetValidOTPHash(ctx, phone)
	if err != nil {
		s.Repo.RecordFailedAttempt(ctx, phone)
		return "", "", "", errors.New("otp expired or not found")
	}

	if !crypto.VerifyOTP(hash, code) {
		s.Repo.RecordFailedAttempt(ctx, phone)
		return "", "", "", errors.New("invalid otp")
	}

	// OTP verified — clear failed attempts and mark OTP used
	s.Repo.ClearFailedAttempts(ctx, phone)
	_ = s.Repo.MarkOTPUsed(ctx, phone)

	var userID string

	// 1. If role is specified, try to login as that specific role
	if role != "" {
		userID, err = citizenRepo.GetUserByPhoneAndRole(ctx, phone, role)
		if err == nil && userID != "" {
			return generateTokenPair(userID, role)
		}

		// If explicitly requested CITIZEN and not found -> Create it
		if role == "CITIZEN" {
			userID, err = citizenRepo.GetOrCreateCitizen(ctx, phone)
			if err != nil {
				return "", "", "", err
			}
			return generateTokenPair(userID, "CITIZEN")
		}

		// If requested another role (e.g. FIELD_OFFICER) and not found -> Error
		return "", "", "", fmt.Errorf("user not found with role: %s", role)
	}

	// 2. Fallback (Legacy): Get any user by phone
	userID, roleName, err = s.Repo.GetUserByPhone(ctx, phone)
	if err == nil {
		return generateTokenPair(userID, roleName)
	}

	// 3. Fallback: Create citizen
	userID, err = citizenRepo.GetOrCreateCitizen(ctx, phone)
	if err != nil {
		return "", "", "", err
	}
	return generateTokenPair(userID, "CITIZEN")
}

/* ---------- LOGOUT ---------- */

func (s *Service) Logout(ctx context.Context, accessToken string, refreshToken string) error {
	var errs []error
	if accessToken != "" {
		if err := utils.BlacklistToken(accessToken); err != nil {
			errs = append(errs, fmt.Errorf("access token: %w", err))
		}
	}
	if refreshToken != "" {
		if err := utils.BlacklistToken(refreshToken); err != nil {
			errs = append(errs, fmt.Errorf("refresh token: %w", err))
		}
	}
	if len(errs) > 0 {
		log.Println("⚠️ Logout partial errors:", errs)
	}
	return nil // Always succeed silently for UX
}

/* ---------- REFRESH ACCESS TOKEN ---------- */

func (s *Service) RefreshAccessToken(ctx context.Context, refreshToken string) (string, string, error) {
	claims, err := utils.ParseRefreshToken(refreshToken)
	if err != nil {
		return "", "", err
	}

	userID, _ := claims["user_id"].(string)
	role, _ := claims["role"].(string)

	if userID == "" || role == "" {
		return "", "", errors.New("invalid refresh token claims")
	}

	// Blacklist old refresh token (rotation)
	_ = utils.BlacklistToken(refreshToken)

	// Issue new token pair
	access, refresh, _, err := generateTokenPair(userID, role)
	return access, refresh, err
}

/* ---------- HELPERS ---------- */

func generateTokenPair(userID, role string) (string, string, string, error) {
	access, err := utils.GenerateJWT(userID, role)
	if err != nil {
		return "", "", "", err
	}
	refresh, err := utils.GenerateRefreshToken(userID, role)
	if err != nil {
		return "", "", "", err
	}
	return access, refresh, role, nil
}
