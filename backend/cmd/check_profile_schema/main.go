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
		"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'officer_profiles'")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	tables := []string{"officer_profiles", "users"}
	for _, t := range tables {
		fmt.Printf("\nColumns in %s:\n", t)
		rows, err := pool.Query(context.Background(),
			"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = $1", t)
		if err != nil {
			log.Fatal(err)
		}
		for rows.Next() {
			var name, dtype string
			rows.Scan(&name, &dtype)
			fmt.Printf("%s (%s)\n", name, dtype)
		}
		rows.Close()
	}
}
