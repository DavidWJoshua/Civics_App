package middleware

import (
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

// getAllowedOrigins reads the ALLOWED_ORIGINS environment variable (comma-separated).
// Example: ALLOWED_ORIGINS=http://localhost:3000,https://yourapp.com
// If the variable is not set or empty, an empty slice is returned, which means
// all origins are reflected (permissive dev mode).
func getAllowedOrigins() []string {
	env := os.Getenv("ALLOWED_ORIGINS")
	if env == "" {
		return nil
	}
	var origins []string
	for _, o := range strings.Split(env, ",") {
		o = strings.TrimSpace(o)
		if o != "" {
			origins = append(origins, o)
		}
	}
	return origins
}

// isAllowedOrigin returns true if origin is present in the allowlist.
// If the allowlist is empty (dev mode), all origins are allowed.
func isAllowedOrigin(origin string, allowed []string) bool {
	if len(allowed) == 0 {
		return true // dev mode: permissive
	}
	for _, a := range allowed {
		if a == origin {
			return true
		}
	}
	return false
}

func CORSMiddleware() gin.HandlerFunc {
	allowedOrigins := getAllowedOrigins()

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if isAllowedOrigin(origin, allowedOrigins) {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
			// Vary: Origin tells caches this response differs by origin.
			c.Writer.Header().Add("Vary", "Origin")
		}

		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
