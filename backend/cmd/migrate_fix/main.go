package main

import (
	"context"
	"log"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/common/db"

	"github.com/joho/godotenv"
)

func main() {
	// Load .env from root
	if err := godotenv.Load("../../.env"); err != nil {
		log.Println("⚠️ .env not found in partial path, trying absolute or assuming vars set")
	}

	cfg := config.LoadConfig()

	pg, err := db.Connect(db.DBConfig{
		Host: cfg.DBHost,
		Port: cfg.DBPort,
		Name: cfg.DBName,
		User: cfg.DBUser,
		Pass: cfg.DBPass,
	})
	if err != nil {
		log.Fatal("❌ DB connection failed:", err)
	}
	defer pg.Close()
	log.Println("✅ Connected to DB")

	query := `
	CREATE TABLE IF NOT EXISTS complaint_assignments (
		id SERIAL PRIMARY KEY,
		complaint_id UUID REFERENCES complaints(id),
		assigned_to_user_id VARCHAR(50), -- Removed FK for now to avoid 42830 error
		assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		status VARCHAR(50) DEFAULT 'Active'
	);
	`

	_, err = pg.Exec(context.Background(), query)
	if err != nil {
		log.Fatal("❌ Migration failed:", err)
	}
	log.Println("✅ complaint_assignments table created successfully")
}
