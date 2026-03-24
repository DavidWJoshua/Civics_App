package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// windowEntry tracks request count within a sliding window for one IP.
type windowEntry struct {
	mu        sync.Mutex
	count     int
	windowEnd time.Time
}

// ipStore holds one windowEntry per unique IP address.
var ipStore sync.Map

// getEntry returns (or lazily creates) the windowEntry for the given key.
func getEntry(key string) *windowEntry {
	v, _ := ipStore.LoadOrStore(key, &windowEntry{})
	return v.(*windowEntry)
}

// RateLimitMiddleware returns a Gin middleware that allows at most `max`
// requests per `window` duration for each unique client IP.
//
// When the limit is exceeded the request is rejected with HTTP 429.
// The limiter uses a fixed-window counter. No external dependencies.
func RateLimitMiddleware(max int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		entry := getEntry(ip)

		entry.mu.Lock()
		now := time.Now()
		if now.After(entry.windowEnd) {
			// Start a new window
			entry.count = 0
			entry.windowEnd = now.Add(window)
		}
		entry.count++
		count := entry.count
		entry.mu.Unlock()

		if count > max {
			c.Header("Retry-After", entry.windowEnd.Format(time.RFC1123))
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "too many requests, please try again later",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
