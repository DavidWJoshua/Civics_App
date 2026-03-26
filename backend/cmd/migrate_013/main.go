package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Println("⚠️ .env not found")
	}

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s",
		os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"), os.Getenv("DB_PORT"), os.Getenv("DB_NAME"))

	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	sql, err := os.ReadFile("database/migrations/013_add_operator_fields_to_profiles.sql")
	if err != nil {
		log.Fatal(err)
	}

	_, err = pool.Exec(context.Background(), string(sql))
	if err != nil {
		log.Fatalf("Migration failed: %v", err)
	}
	fmt.Println("✅ Migration 013 applied successfully.")
}
