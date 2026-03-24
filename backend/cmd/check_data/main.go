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
		log.Println("⚠️ .env not found in current dir")
	}

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s",
		os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"), os.Getenv("DB_PORT"), os.Getenv("DB_NAME"))

	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	rows, err := pool.Query(context.Background(),
		"SELECT id, voltage, current_reading, hours_reading FROM lifting_daily_logs ORDER BY id DESC LIMIT 5")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	fmt.Println("Latest Lifting Logs:")
	for rows.Next() {
		var id int
		var v, c, h float64
		rows.Scan(&id, &v, &c, &h)
		fmt.Printf("ID: %d | V: %.2f | A: %.2f | Hrs: %.2f\n", id, v, c, h)
	}
}
