package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env
	envPath := "../../.env"
	if err := godotenv.Load(envPath); err != nil {
		log.Printf("⚠️ .env not found at %s", envPath)
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
	migrationPath := "../../database/migrations/009_seed_stations.sql"
	sqlBytes, err := os.ReadFile(migrationPath)
	if err != nil {
		log.Fatalf("❌ Failed to read migration file: %v", err)
	}
	sqlParams := string(sqlBytes)

	log.Println("🚀 Running migration...")
	startTime := time.Now()
	_, err = pool.Exec(ctx, sqlParams)
	if err != nil {
		log.Fatalf("❌ Migration failed: %v", err)
	}

	log.Printf("✅ Migration completed successfully in %v", time.Since(startTime))
}
