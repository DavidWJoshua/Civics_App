package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// LimitBodySize limits the request body size (e.g. 10MB) to prevent DoS.
func LimitBodySize(maxSize int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxSize)
		c.Next()
	}
}
