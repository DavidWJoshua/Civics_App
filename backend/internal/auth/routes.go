package auth

import (
	"civic-complaint-system/backend/internal/common/middleware"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup, h *Handler) {
	// Public auth routes — apply rate limiting
	r.POST("/citizen/send-otp", middleware.OTPSendRateLimit(), h.SendOTP)
	r.POST("/citizen/verify-otp", middleware.OTPVerifyRateLimit(), h.VerifyOTP)
	r.POST("/refresh", h.RefreshToken)
	r.GET("/citizen/captcha", h.GenerateCaptcha)
	r.GET("/citizen/captcha/:id", h.ServeCaptchaImage)

	// Protected logout route (requires valid JWT)
	r.POST("/logout", middleware.JWTAuthMiddleware(), h.Logout)
}
