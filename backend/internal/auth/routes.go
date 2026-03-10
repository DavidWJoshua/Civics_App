package auth

import "github.com/gin-gonic/gin"

func RegisterRoutes(r *gin.RouterGroup, h *Handler) {
	r.POST("/citizen/send-otp", h.SendOTP)
	r.GET("/citizen/captcha", h.GenerateCaptcha)
	r.GET("/citizen/captcha/:id", h.ServeCaptchaImage)
}
