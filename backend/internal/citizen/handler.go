package citizen

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Repo *Repository
}

func (h *Handler) CitizenHome(c *gin.Context) {
	// Values set by JWT middleware
	citizenID := c.GetString("user_id")
	role := c.GetString("role")

	if role != "CITIZEN" {
		c.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
		return
	}

	// For now, return static counts
	c.JSON(http.StatusOK, gin.H{
		"citizen_id":       citizenID,
		"total_complaints": 0,
		"pending":          0,
		"completed":        0,
	})
}
