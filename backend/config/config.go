package config

import "os"

type Config struct {
	DBHost       string
	DBPort       string
	DBName       string
	DBUser       string
	DBPass       string
	AWSRegion    string
	JWTSecret    string
	MLServiceURL string
	UploadDir    string
}

func LoadConfig() *Config {
	mlURL := os.Getenv("ML_SERVICE_URL")
	if mlURL == "" {
		mlURL = "http://localhost:5001"
	}
	return &Config{
		DBHost:       os.Getenv("DB_HOST"),
		DBPort:       os.Getenv("DB_PORT"),
		DBName:       os.Getenv("DB_NAME"),
		DBUser:       os.Getenv("DB_USER"),
		DBPass:       os.Getenv("DB_PASSWORD"),
		AWSRegion:    os.Getenv("AWS_REGION"),
		JWTSecret:    os.Getenv("JWT_SECRET"),
		MLServiceURL: mlURL,
		UploadDir:    getEnv("UPLOAD_DIR", "./uploads"),
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
