package crypto

import "golang.org/x/crypto/bcrypt"

func HashOTP(otp string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(otp), 10)
	return string(bytes), err
}

func VerifyOTP(hash, otp string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(otp)) == nil
}
