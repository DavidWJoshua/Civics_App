package storage

import (
	"context"
	"fmt"
	"mime/multipart"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Client struct {
	client   *s3.Client
	uploader *manager.Uploader
	bucket   string
	region   string
}

func NewS3Client(ctx context.Context, bucket string, region string) (*S3Client, error) {
	// The AWS SDK will automatically look for IAM Roles if running on EC2,
	// or fallback to the .env file credentials when testing locally!
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return nil, fmt.Errorf("unable to load AWS SDK config: %v", err)
	}

	client := s3.NewFromConfig(cfg)
	uploader := manager.NewUploader(client)

	return &S3Client{
		client:   client,
		uploader: uploader,
		bucket:   bucket,
		region:   region,
	}, nil
}

// UploadImage takes a multipart file and uploads it to S3, returning the public URL
func (s *S3Client) UploadImage(ctx context.Context, file multipart.File, filename string) (string, error) {
	_, err := s.uploader.Upload(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(filename),
		Body:        file,
		ContentType: aws.String("image/jpeg"), // We can default to image/jpeg or detect dynamically
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload file to S3: %v", err)
	}

	// Generate and return the public URL
	publicURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucket, s.region, filename)
	return publicURL, nil
}
