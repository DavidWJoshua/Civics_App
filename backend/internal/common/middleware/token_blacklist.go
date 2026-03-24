package middleware

import (
	"sync"
	"time"
)

type blacklistedToken struct {
	expiresAt time.Time
}

var (
	tokenBlacklist   sync.Map
	blacklistCleanup sync.Once
)

// BlacklistToken adds a token to the blacklist until its natural expiry.
func BlacklistToken(tokenStr string, expiresAt time.Time) {
	blacklistCleanup.Do(func() {
		go func() {
			ticker := time.NewTicker(30 * time.Minute)
			defer ticker.Stop()
			for range ticker.C {
				now := time.Now()
				tokenBlacklist.Range(func(key, value any) bool {
					entry := value.(blacklistedToken)
					if now.After(entry.expiresAt) {
						tokenBlacklist.Delete(key)
					}
					return true
				})
			}
		}()
	})
	tokenBlacklist.Store(tokenStr, blacklistedToken{expiresAt: expiresAt})
}

// IsBlacklisted returns true if the token has been revoked.
func IsBlacklisted(tokenStr string) bool {
	val, ok := tokenBlacklist.Load(tokenStr)
	if !ok {
		return false
	}
	entry := val.(blacklistedToken)
	if time.Now().After(entry.expiresAt) {
		tokenBlacklist.Delete(tokenStr)
		return false
	}
	return true
}
