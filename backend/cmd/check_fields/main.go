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

	tables := []string{"lifting_daily_logs", "pumping_daily_logs", "stp_daily_logs"}

	for _, table := range tables {
		fmt.Printf("\nColumns in %s:\n", table)
		rows, err := pool.Query(context.Background(),
			"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = $1", table)
		if err != nil {
			log.Fatal(err)
		}

		for rows.Next() {
			var name, dtype string
			rows.Scan(&name, &dtype)
			fmt.Printf("- %s (%s)\n", name, dtype)
		}
		rows.Close()
	}
}
