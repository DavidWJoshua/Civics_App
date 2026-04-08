package middleware

import (
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

// allowedOrigins loads from ALLOWED_ORIGINS env var (comma-separated) or defaults to localhost.
func getAllowedOrigins() []string {
	raw := os.Getenv("ALLOWED_ORIGINS")
	if raw == "" {
		// Default: permit local dev origins
		return []string{
			"http://localhost:3000",
			"http://localhost:8080",
			"http://localhost:4200",
		}
	}
	parts := strings.Split(raw, ",")
	for i := range parts {
		parts[i] = strings.TrimSpace(parts[i])
	}
	return parts
}

func isOriginAllowed(origin string, allowed []string) bool {
	for _, a := range allowed {
		if a == "*" || a == origin {
			return true
		}
	}
	return false
}

func CORSMiddleware() gin.HandlerFunc {
	allowedOrigins := getAllowedOrigins()

	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		if origin != "" && isOriginAllowed(origin, allowedOrigins) {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
			c.Writer.Header().Set("Vary", "Origin") // Required for proper caching
		}
		// Do NOT set Access-Control-Allow-Origin: * — this exposes APIs to any site

		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Writer.Header().Set("Access-Control-Max-Age", "300") // Cache preflight for 5 min

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
