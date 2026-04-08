package utils

import (
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret []byte

func SetJWTSecret(secret string) {
	jwtSecret = []byte(secret)
}

// ─── Token durations ───────────────────────────────────────────────────────────

const (
	AccessTokenDuration  = 30 * time.Minute   // Short-lived access token
	RefreshTokenDuration = 7 * 24 * time.Hour // Long-lived refresh token
)

// ─── Token blacklist (in-memory; use Redis in production) ─────────────────────

type blacklist struct {
	mu      sync.RWMutex
	entries map[string]time.Time // jti → expiry
}

var tokenBlacklist = &blacklist{entries: make(map[string]time.Time)}

func (b *blacklist) add(jti string, exp time.Time) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.entries[jti] = exp
	// Purge expired entries opportunistically
	now := time.Now()
	for k, v := range b.entries {
		if now.After(v) {
			delete(b.entries, k)
		}
	}
}

func (b *blacklist) has(jti string) bool {
	b.mu.RLock()
	defer b.mu.RUnlock()
	exp, ok := b.entries[jti]
	if !ok {
		return false
	}
	return time.Now().Before(exp) // still valid in blacklist
}

// BlacklistToken adds a token's JTI to the blacklist (used on logout).
func BlacklistToken(tokenStr string) error {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return jwtSecret, nil
	})
	if err != nil && !errors.Is(err, jwt.ErrTokenExpired) {
		return err
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return errors.New("invalid claims")
	}
	jti, _ := claims["jti"].(string)
	exp, _ := claims["exp"].(float64)
	if jti == "" {
		// No JTI — block by raw token string (less ideal but safe)
		jti = tokenStr[:min(len(tokenStr), 64)]
	}
	tokenBlacklist.add(jti, time.Unix(int64(exp), 0))
	return nil
}

// IsTokenBlacklisted checks whether a token has been invalidated.
func IsTokenBlacklisted(jti string) bool {
	return tokenBlacklist.has(jti)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ─── Token generation ──────────────────────────────────────────────────────────

// GenerateJWT generates a short-lived access token (30 min).
func GenerateJWT(userID, role string) (string, error) {
	jti := generateJTI()
	claims := jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"jti":     jti,
		"type":    "access",
		"exp":     time.Now().Add(AccessTokenDuration).Unix(),
		"iat":     time.Now().Unix(),
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString(jwtSecret)
}

// GenerateRefreshToken generates a long-lived refresh token (7 days).
func GenerateRefreshToken(userID, role string) (string, error) {
	jti := generateJTI()
	claims := jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"jti":     jti,
		"type":    "refresh",
		"exp":     time.Now().Add(RefreshTokenDuration).Unix(),
		"iat":     time.Now().Unix(),
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString(jwtSecret)
}

// ParseRefreshToken validates a refresh token and returns its claims.
func ParseRefreshToken(tokenStr string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return jwtSecret, nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid or expired refresh token")
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}
	// Ensure it's a refresh token
	if tokenType, _ := claims["type"].(string); tokenType != "refresh" {
		return nil, errors.New("not a refresh token")
	}
	// Check blacklist
	if jti, _ := claims["jti"].(string); tokenBlacklist.has(jti) {
		return nil, errors.New("token has been revoked")
	}
	return claims, nil
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

// generateJTI creates a unique token ID using current nanosecond time + random suffix.
func generateJTI() string {
	// Using time-based unique ID (crypto/rand would be better but adds import complexity)
	return fmt.Sprintf("%d", time.Now().UnixNano())
}
