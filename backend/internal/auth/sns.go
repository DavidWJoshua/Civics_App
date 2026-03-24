package auth

import "log"

type SNSSender interface {
	SendSMS(phone string, message string) error
}

type MockSNSSender struct{}

func (m *MockSNSSender) SendSMS(phone string, message string) error {
	log.Printf("📱 MOCK SMS to %s: %s", phone, message)
	return nil
}
