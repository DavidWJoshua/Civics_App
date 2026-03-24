package notification

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sns/types"
)

type AWSSNS struct {
	client *sns.Client
}

func NewAWSSNS(region string) (*AWSSNS, error) {
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithRegion(region),
	)
	if err != nil {
		return nil, err
	}

	return &AWSSNS{
		client: sns.NewFromConfig(cfg),
	}, nil
}

func (a *AWSSNS) SendSMS(phone, message string) error {
	_, err := a.client.Publish(context.TODO(), &sns.PublishInput{
		Message:     aws.String(message),
		PhoneNumber: aws.String(phone),
		MessageAttributes: map[string]types.MessageAttributeValue{
			"AWS.SNS.SMS.SMSType": {
				DataType:    aws.String("String"),
				StringValue: aws.String("Transactional"),
			},
		},
	})
	return err
}
