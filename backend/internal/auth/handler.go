package auth

import (
	"log"
	"net/http"

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

	log.Printf("🔹 Captcha check: %s", req.CaptchaID)
	if !captcha.VerifyString(req.CaptchaID, req.CaptchaValue) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid captcha"})
		return
	}

	isOfficer, err := h.Service.SendOTP(c, req.PhoneNumber)
	if err != nil {
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

	token, roleName, err := h.Service.VerifyOTPAndLogin(
		c,
		req.PhoneNumber,
		req.Code,
		req.Role, // ⚠️ ignored internally
		h.CitizenRepo,
	)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	log.Printf("✅ Login success: %s", req.PhoneNumber)

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"role":  roleName,
	})
}
