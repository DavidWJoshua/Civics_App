package middleware

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var jwtSecret []byte

// SetJWTSecret is called once from main.go
func SetJWTSecret(secret string) {
	jwtSecret = []byte(secret)
}

func JWTAuthMiddleware(db *pgxpool.Pool) gin.HandlerFunc {
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

		// Validate JTI against sessions
		if jti, ok := claims["jti"].(string); ok {
			var exists bool
			err := db.QueryRow(c.Request.Context(), "SELECT EXISTS(SELECT 1 FROM user_sessions WHERE jti = $1)", jti).Scan(&exists)
			if err != nil || !exists {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "session expired or logged out"})
				c.Abort()
				return
			}
			c.Set("jti", jti)
		} else {
			// Backwards compatibility for existing tokens without jti
			log.Println("⚠️ JWT missing jti, allowing legacy token temporarily")
		}

		// Attach to context
		log.Printf("🔐 JWT Claims: %+v", claims)
		if uid, ok := claims["user_id"].(string); ok {
			c.Set("user_id", uid)
		} else {
			log.Println("❌ user_id claim is not a string or missing")
		}
		c.Set("role", claims["role"])

		c.Next()
	}
}
