package config

import "os"

type Config struct {
	DBHost          string
	DBPort          string
	DBName          string
	DBUser          string
	DBPass          string
	AWSRegion       string
	AWSAccessKey    string
	AWSSecretKey    string
	JWTSecret       string
	MLServiceURL    string
	UploadDir       string
	AESKey          string
	AllowedOrigins  string
}

func LoadConfig() *Config {
	mlURL := os.Getenv("ML_SERVICE_URL")
	if mlURL == "" {
		mlURL = "http://localhost:5001"
	}
	return &Config{
		DBHost:         os.Getenv("DB_HOST"),
		DBPort:         os.Getenv("DB_PORT"),
		DBName:         os.Getenv("DB_NAME"),
		DBUser:         os.Getenv("DB_USER"),
		DBPass:         os.Getenv("DB_PASSWORD"),
		AWSRegion:      os.Getenv("AWS_REGION"),
		AWSAccessKey:   os.Getenv("AWS_ACCESS_KEY_ID"),
		AWSSecretKey:   os.Getenv("AWS_SECRET_ACCESS_KEY"),
		JWTSecret:      os.Getenv("JWT_SECRET"),
		MLServiceURL:   mlURL,
		UploadDir:      getEnv("UPLOAD_DIR", "./uploads"),
		AESKey:         getEnv("AES_KEY", "default-32-byte-key-change-this!!"),
		AllowedOrigins: getEnv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080"),
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
