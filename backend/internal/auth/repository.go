package auth

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// ─── OTP Session ──────────────────────────────────────────────────────────────

type otpSession struct {
	hash      string
	expiresAt time.Time
	verified  bool
}

var otpStore sync.Map

// ─── Brute-force Lockout Tracking (in-memory) ─────────────────────────────────

type failTracker struct {
	mu      sync.Mutex
	entries map[string]*failEntry
}

type failEntry struct {
	count    int
	lockedAt time.Time
	locked   bool
}

const (
	maxFailedAttempts = 5
	lockoutDuration   = 15 * time.Minute
)

var failStore = &failTracker{entries: make(map[string]*failEntry)}

// ─── Repository ───────────────────────────────────────────────────────────────

type Repository struct {
	DB *pgxpool.Pool
}

// ─── OTP Methods ──────────────────────────────────────────────────────────────

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

// ─── Brute-Force Lockout Methods ──────────────────────────────────────────────

// RecordFailedAttempt increments the fail counter for a phone number.
func (r *Repository) RecordFailedAttempt(ctx context.Context, phone string) {
	failStore.mu.Lock()
	defer failStore.mu.Unlock()

	entry, exists := failStore.entries[phone]
	if !exists {
		entry = &failEntry{}
		failStore.entries[phone] = entry
	}

	entry.count++
	if entry.count >= maxFailedAttempts {
		entry.locked = true
		entry.lockedAt = time.Now()
	}
}

// IsLockedOut returns true if the phone is currently locked out.
func (r *Repository) IsLockedOut(ctx context.Context, phone string) bool {
	failStore.mu.Lock()
	defer failStore.mu.Unlock()

	entry, exists := failStore.entries[phone]
	if !exists {
		return false
	}
	if !entry.locked {
		return false
	}
	// Auto-unlock after lockout period
	if time.Since(entry.lockedAt) > lockoutDuration {
		entry.locked = false
		entry.count = 0
		return false
	}
	return true
}

// ClearFailedAttempts resets the fail tracker for a phone after successful auth.
func (r *Repository) ClearFailedAttempts(ctx context.Context, phone string) {
	failStore.mu.Lock()
	defer failStore.mu.Unlock()
	delete(failStore.entries, phone)
}

// ─── User Lookup Methods ───────────────────────────────────────────────────────

func (r *Repository) IsOfficer(ctx context.Context, phone string) (bool, error) {
	var role string
	err := r.DB.QueryRow(ctx, "SELECT role FROM users WHERE phone_number = $1", phone).Scan(&role)
	if err != nil {
		return false, nil
	}
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
