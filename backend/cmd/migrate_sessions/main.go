package main

import (
	"context"
	"log"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/common/db"

	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load(".env")
	cfg := config.LoadConfig()
	pg, err := db.Connect(db.DBConfig{
		Host: cfg.DBHost,
		Port: cfg.DBPort,
		Name: cfg.DBName,
		User: cfg.DBUser,
		Pass: cfg.DBPass,
	})
	if err != nil {
		log.Fatal(err)
	}

	query := `
	CREATE TABLE IF NOT EXISTS user_sessions (
		jti VARCHAR(50) PRIMARY KEY,
		user_id VARCHAR(50) NOT NULL,
		role VARCHAR(50) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		expires_at TIMESTAMP NOT NULL
	);
	`
	_, err = pg.Exec(context.Background(), query)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Successfully created user_sessions table!")
}
