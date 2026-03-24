package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env from root (adjust path as needed based on where we run this)
	// Assuming running from backend root
	if err := godotenv.Load(".env"); err != nil {
		// Try going up one level if running from inside cmd/migrate_012
		if err := godotenv.Load("../../.env"); err != nil {
			log.Println("⚠️ .env not found, assuming env vars are set")
		}
	}

	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbName := os.Getenv("DB_NAME")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")

	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s",
		dbUser, dbPass, dbHost, dbPort, dbName,
	)

	log.Println("🔌 Connecting to database...")
	ctx := context.Background()
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		log.Fatalf("❌ Unable to parse config: %v", err)
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		log.Fatalf("❌ Unable to connect to database: %v", err)
	}
	defer pool.Close()

	// Read migration file
	// We will look for the file relative to where this command is likely run (backend root)
	migrationPath := "database/migrations/012_fix_stations_and_leaves.sql"

	// Check if file exists, if not try relative to this file location
	if _, err := os.Stat(migrationPath); os.IsNotExist(err) {
		migrationPath = "../../database/migrations/012_fix_stations_and_leaves.sql"
	}

	absPath, _ := filepath.Abs(migrationPath)
	log.Printf("📂 Reading migration from: %s", absPath)

	sqlBytes, err := os.ReadFile(migrationPath)
	if err != nil {
		log.Fatalf("❌ Failed to read migration file: %v", err)
	}
	sqlParams := string(sqlBytes)

	log.Println("🚀 Running migration 012...")
	startTime := time.Now()
	_, err = pool.Exec(ctx, sqlParams)
	if err != nil {
		log.Fatalf("❌ Migration failed: %v", err)
	}

	log.Printf("✅ Migration completed successfully in %v", time.Since(startTime))
}
