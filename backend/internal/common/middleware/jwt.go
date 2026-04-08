package middleware

import (
	"log"
	"net/http"
	"strings"

	"civic-complaint-system/backend/internal/common/utils"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret []byte

// SetJWTSecret is called once from main.go
func SetJWTSecret(secret string) {
	jwtSecret = []byte(secret)
}

func JWTAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")

		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing authorization header"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
			c.Abort()
			return
		}

		tokenStr := parts[1]

		token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
			c.Abort()
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token claims"})
			c.Abort()
			return
		}

		// Ensure it is an access token (not a refresh token used as access)
		if tokenType, _ := claims["type"].(string); tokenType == "refresh" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "refresh tokens cannot be used for API access"})
			c.Abort()
			return
		}

		// Check token blacklist (logged-out tokens)
		if jti, ok := claims["jti"].(string); ok && utils.IsTokenBlacklisted(jti) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "token has been revoked"})
			c.Abort()
			return
		}

		// Attach to context
		log.Printf("🔐 JWT Claims: user_id=%v role=%v", claims["user_id"], claims["role"])
		if uid, ok := claims["user_id"].(string); ok {
			c.Set("user_id", uid)
		} else {
			log.Println("❌ user_id claim is not a string or missing")
		}
		c.Set("role", claims["role"])

		c.Next()
	}
}
