package auth

import (
	"net/http"

	"github.com/dchest/captcha"
	"github.com/gin-gonic/gin"
)

func (h *Handler) GenerateCaptcha(c *gin.Context) {
	id := captcha.New()
	c.JSON(http.StatusOK, gin.H{"captcha_id": id})
}

func (h *Handler) ServeCaptchaImage(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing captcha id"})
		return
	}

	c.Writer.Header().Set("Content-Type", "image/png")
	if err := captcha.WriteImage(c.Writer, id, 240, 80); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate image"})
		return
	}
}
