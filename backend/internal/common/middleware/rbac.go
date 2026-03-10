package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// RequireRole is a generic RBAC middleware
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		role := c.GetString("role")

		// Role must be present (JWT middleware should set this)
		if role == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Unauthorized: role missing",
			})
			c.Abort()
			return
		}

		for _, allowed := range allowedRoles {
			if role == allowed {
				c.Next()
				return
			}
		}

		c.JSON(http.StatusForbidden, gin.H{
			"error": "Access denied for role: " + role,
		})
		c.Abort()
	}
}

// ---- Convenience wrappers ----

// Field Officer only
func RequireFieldOfficer() gin.HandlerFunc {
	return RequireRole("FIELD_OFFICER")
}

// Junior Engineer only
func RequireJuniorEngineer() gin.HandlerFunc {
	return RequireRole("JUNIOR_ENGINEER")
}

// Commissioner only
func RequireCommissioner() gin.HandlerFunc {
	return RequireRole("COMMISSIONER")
}
