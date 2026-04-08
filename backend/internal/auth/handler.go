package auth

import (
	"log"
	"net/http"
	"strings"

	"github.com/dchest/captcha"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service     *Service
	CitizenRepo CitizenRepo
}

/* ---------- SEND OTP ---------- */

func (h *Handler) SendOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Basic phone validation
	if len(req.PhoneNumber) < 10 || len(req.PhoneNumber) > 15 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid phone number"})
		return
	}

	log.Printf("🔹 Captcha check: %s", req.CaptchaID)
	if !captcha.VerifyString(req.CaptchaID, req.CaptchaValue) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid captcha"})
		return
	}

	isOfficer, err := h.Service.SendOTP(c, req.PhoneNumber)
	if err != nil {
		if strings.Contains(err.Error(), "locked") {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":    "OTP sent successfully",
		"is_officer": isOfficer, // UI hint only
	})
}

/* ---------- VERIFY OTP ---------- */

func (h *Handler) VerifyOTP(c *gin.Context) {
	var req OTPVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Basic phone validation
	if len(req.PhoneNumber) < 10 || len(req.PhoneNumber) > 15 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid phone number"})
		return
	}

	// OTP format validation: must be 6 digits
	if len(req.Code) != 6 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "OTP must be 6 digits"})
		return
	}

	accessToken, refreshToken, roleName, err := h.Service.VerifyOTPAndLogin(
		c,
		req.PhoneNumber,
		req.Code,
		req.Role,
		h.CitizenRepo,
	)
	if err != nil {
		if strings.Contains(err.Error(), "locked") {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	log.Printf("✅ Login success: %s role=%s", req.PhoneNumber, roleName)

	c.JSON(http.StatusOK, gin.H{
		"token":         accessToken,
		"refresh_token": refreshToken,
		"role":          roleName,
		"expires_in":    1800, // 30 minutes in seconds
	})
}

/* ---------- REFRESH TOKEN ---------- */

func (h *Handler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "refresh_token is required"})
		return
	}

	accessToken, refreshToken, err := h.Service.RefreshAccessToken(c, req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":         accessToken,
		"refresh_token": refreshToken,
		"expires_in":    1800,
	})
}

/* ---------- LOGOUT ---------- */

func (h *Handler) Logout(c *gin.Context) {
	// Get access token from Authorization header
	authHeader := c.GetHeader("Authorization")
	accessToken := ""
	if strings.HasPrefix(authHeader, "Bearer ") {
		accessToken = strings.TrimPrefix(authHeader, "Bearer ")
	}

	// Get refresh token from body (optional)
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	_ = c.ShouldBindJSON(&req) // Optional — don't fail if body is empty

	if err := h.Service.Logout(c, accessToken, req.RefreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "logout failed"})
		return
	}

	log.Printf("🚪 User logged out: user_id=%s", c.GetString("user_id"))
	c.JSON(http.StatusOK, gin.H{"message": "logged out successfully"})
}
