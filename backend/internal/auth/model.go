package auth

type OTPRequest struct {
	// PhoneNumber must be 10–15 chars (E.164 without '+' prefix is 10–15 digits).
	PhoneNumber  string `json:"phone_number" binding:"required,min=10,max=15"`
	CaptchaID    string `json:"captcha_id" binding:"required"`
	CaptchaValue string `json:"captcha_value" binding:"required"`
	Role         string `json:"role"` // Optional, defaults to CITIZEN if empty
}

type OTPVerifyRequest struct {
	// PhoneNumber must be 10–15 chars; Code must be exactly 6 characters.
	PhoneNumber string `json:"phone_number" binding:"required,min=10,max=15"`
	Code        string `json:"code" binding:"required,len=6"`
	Role        string `json:"role"` // Optional, defaults to CITIZEN if empty
}
