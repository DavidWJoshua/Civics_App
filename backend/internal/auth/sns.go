package auth

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sns"
)

type SNSSender interface {
	SendSMS(phone string, message string) error
}

type MockSNSSender struct{}

func (m *MockSNSSender) SendSMS(phone string, message string) error {
	log.Printf("📱 MOCK SMS to %s: %s", phone, message)
	return nil
}

type AWSSNSSender struct {
	Client *sns.Client
}

func (s *AWSSNSSender) SendSMS(phone string, message string) error {
	ctx := context.TODO()
	input := &sns.PublishInput{
		Message:     aws.String(message),
		PhoneNumber: aws.String(phone),
	}

	_, err := s.Client.Publish(ctx, input)
	if err != nil {
		log.Printf("❌ AWS SNS Failed: %v", err)
		return err
	}

	log.Printf("✅ AWS SNS sent to %s", phone)
	return nil
}
