package middleware

import "github.com/gin-gonic/gin"

// SecurityHeaders adds security-related HTTP response headers (Helmet.js equivalent for Go).
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Prevent MIME-type sniffing
		c.Header("X-Content-Type-Options", "nosniff")

		// Prevent clickjacking
		c.Header("X-Frame-Options", "DENY")

		// Enable XSS protection in older browsers
		c.Header("X-XSS-Protection", "1; mode=block")

		// Enforce HTTPS (uncomment in production with HTTPS):
		// c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")

		// Restrict referrer information
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")

		// Content Security Policy — restricts resource loading
		c.Header("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'")

		// Disable caching for sensitive API responses
		c.Header("Cache-Control", "no-store, no-cache, must-revalidate, private")
		c.Header("Pragma", "no-cache")

		// Prevent cross-origin information leakage
		c.Header("Cross-Origin-Opener-Policy", "same-origin")
		c.Header("Cross-Origin-Resource-Policy", "same-origin")

		c.Next()
	}
}
