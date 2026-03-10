package auth

import (
	"context"
	"errors"
	"fmt"
	"log"
	"math/rand"
	"time"

	"civic-complaint-system/backend/internal/common/crypto"
	"civic-complaint-system/backend/internal/common/utils"
)

type Service struct {
	Repo *Repository
	SNS  SNSSender
}

/* ---------- OTP GENERATOR ---------- */

func generateOTP() string {
	rand.Seed(time.Now().UnixNano())
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

/* ---------- SEND OTP ---------- */

func (s *Service) SendOTP(ctx context.Context, phone string) (bool, error) {
	otp := generateOTP()
	log.Println("OTP GENERATED:", otp)

	hash, err := crypto.HashOTP(otp)
	if err != nil {
		return false, err
	}

	if err := s.Repo.SaveOTP(ctx, phone, hash); err != nil {
		log.Println("❌ SAVE OTP ERROR:", err)
		return false, err
	}

	message := "Your OTP for Civic Complaint System is: " + otp
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
) (string, string, error) {

	hash, err := s.Repo.GetValidOTPHash(ctx, phone)
	if err != nil {
		return "", "", errors.New("otp expired or not found")
	}

	if !crypto.VerifyOTP(hash, code) {
		return "", "", errors.New("invalid otp")
	}

	_ = s.Repo.MarkOTPUsed(ctx, phone)

	// 1. If role is specified, try to login as that specific role
	if role != "" {
		userID, err := citizenRepo.GetUserByPhoneAndRole(ctx, phone, role)
		if err == nil && userID != "" {
			token, err := utils.GenerateJWT(userID, role)
			return token, role, err
		}

		// If explicitly requested CITIZEN and not found -> Create it
		if role == "CITIZEN" {
			userID, err = citizenRepo.GetOrCreateCitizen(ctx, phone)
			if err != nil {
				return "", "", err
			}
			token, err := utils.GenerateJWT(userID, "CITIZEN")
			return token, "CITIZEN", err
		}

		// If requested another role (e.g. FIELD_OFFICER) and not found -> Error
		// We don't fall back to "any user" here because the user explicitly asked for this role
		return "", "", fmt.Errorf("user not found with role: %s", role)
	}

	// 2. Fallback (Legacy): Get any user by phone
	userID, roleName, err := s.Repo.GetUserByPhone(ctx, phone)
	if err == nil {
		token, err := utils.GenerateJWT(userID, roleName)
		return token, roleName, err
	}

	// 3. Fallback: Create citizen
	userID, err = citizenRepo.GetOrCreateCitizen(ctx, phone)
	if err != nil {
		return "", "", err
	}

	token, err := utils.GenerateJWT(userID, "CITIZEN")
	return token, "CITIZEN", err
}
