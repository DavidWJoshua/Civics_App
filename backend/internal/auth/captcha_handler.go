package auth

import (
	"bytes"
	"net/http"
	"strings"

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

	// Remove .png extension if the frontend appends it
	id = strings.TrimSuffix(id, ".png")

	var buf bytes.Buffer
	if err := captcha.WriteImage(&buf, id, 240, 80); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate image"})
		return
	}

	c.Data(http.StatusOK, "image/png", buf.Bytes())
}
