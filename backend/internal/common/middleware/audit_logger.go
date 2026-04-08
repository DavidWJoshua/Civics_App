package middleware

import (
	"log"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// AuditLogger logs security-relevant events: login attempts, auth failures, suspicious activity.
func AuditLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		// Capture IP, method, path, user-agent
		ip := c.ClientIP()
		method := c.Request.Method
		path := c.Request.URL.Path
		ua := c.Request.UserAgent()

		c.Next()

		status := c.Writer.Status()
		latency := time.Since(start)

		// Classify what to log
		isAuthRoute := strings.Contains(path, "/auth/")
		isSuspicious := status == 401 || status == 403 || status == 429

		if isAuthRoute || isSuspicious {
			severity := "INFO"
			if isSuspicious {
				severity = "WARN"
			}
			if status == 429 {
				severity = "ALERT"
			}

			userID := c.GetString("user_id")
			if userID == "" {
				userID = "<unauthenticated>"
			}

			log.Printf(
				"[AUDIT] [%s] %s %s %s | Status=%d | User=%s | IP=%s | Latency=%s | UA=%s",
				severity, method, path, ip, status, userID, ip, latency, ua,
			)

			// Flag brute force / lockout events
			if status == 429 {
				log.Printf(
					"[SECURITY ALERT] 🚨 Rate limit hit — possible brute force | IP=%s | Path=%s",
					ip, path,
				)
			}
			if status == 401 && isAuthRoute {
				log.Printf(
					"[SECURITY] ⚠️ Auth failure | IP=%s | Path=%s",
					ip, path,
				)
			}
		}
	}
}
