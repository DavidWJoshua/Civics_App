package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// visitor tracks request count in a time window
type visitor struct {
	count     int
	windowEnd time.Time
	blocked   bool
	blockEnd  time.Time
}

type rateLimiter struct {
	mu       sync.Mutex
	visitors map[string]*visitor
	limit    int
	window   time.Duration
	lockout  time.Duration
}

func newRateLimiter(limit int, window, lockout time.Duration) *rateLimiter {
	rl := &rateLimiter{
		visitors: make(map[string]*visitor),
		limit:    limit,
		window:   window,
		lockout:  lockout,
	}
	// Clean up old entries every 5 minutes
	go func() {
		for {
			time.Sleep(5 * time.Minute)
			rl.mu.Lock()
			now := time.Now()
			for k, v := range rl.visitors {
				if now.After(v.windowEnd) && (!v.blocked || now.After(v.blockEnd)) {
					delete(rl.visitors, k)
				}
			}
			rl.mu.Unlock()
		}
	}()
	return rl
}

func (rl *rateLimiter) allow(key string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	v, exists := rl.visitors[key]
	if !exists {
		rl.visitors[key] = &visitor{
			count:     1,
			windowEnd: now.Add(rl.window),
		}
		return true
	}

	// Check if currently blocked
	if v.blocked {
		if now.Before(v.blockEnd) {
			return false
		}
		// Unblock
		v.blocked = false
		v.count = 0
		v.windowEnd = now.Add(rl.window)
	}

	// Reset window if expired
	if now.After(v.windowEnd) {
		v.count = 0
		v.windowEnd = now.Add(rl.window)
	}

	v.count++
	if v.count > rl.limit {
		v.blocked = true
		v.blockEnd = now.Add(rl.lockout)
		return false
	}
	return true
}

// Pre-configured limiters
var (
	// OTP send: 5 requests per 15 minutes per IP, lockout 15 min
	otpSendLimiter = newRateLimiter(5, 15*time.Minute, 15*time.Minute)

	// OTP verify: 5 attempts per 10 minutes per IP (brute-force protection), lockout 15 min
	otpVerifyLimiter = newRateLimiter(5, 10*time.Minute, 15*time.Minute)

	// General API: 120 req/min per IP
	generalLimiter = newRateLimiter(120, time.Minute, 5*time.Minute)
)

// OTPSendRateLimit limits OTP send requests
func OTPSendRateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !otpSendLimiter.allow(ip) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Too many OTP requests. Please try again in 15 minutes.",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// OTPVerifyRateLimit limits OTP verification attempts (brute-force protection)
func OTPVerifyRateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !otpVerifyLimiter.allow(ip) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Too many verification attempts. Please try again in 15 minutes.",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// GeneralRateLimit applies a general request rate limit
func GeneralRateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !generalLimiter.allow(ip) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded. Please slow down.",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}
