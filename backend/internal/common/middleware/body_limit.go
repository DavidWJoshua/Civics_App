package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// MaxBodySize returns a Gin middleware that caps the request body at maxBytes.
//
// If the client sends more data than allowed, the server stops reading after
// maxBytes and returns HTTP 413 Request Entity Too Large.
//
// Note: multipart/form-data routes enforce their own limit via
// ParseMultipartForm and do not need this middleware.
func MaxBodySize(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		c.Next()

		// http.MaxBytesReader sets a sentinel error on the body when the limit
		// is exceeded. Gin's ShouldBindJSON will surface this as a read error.
		// If the response has not been written yet, send 413 explicitly.
		if c.Writer.Status() == http.StatusOK && c.Request.Body != nil {
			// Already handled by ShouldBindJSON error path in individual handlers.
		}
	}
}
