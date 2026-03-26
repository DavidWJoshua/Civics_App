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

	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbName := os.Getenv("DB_NAME")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", dbUser, dbPass, dbHost, dbPort, dbName)
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	var badCount int
	err = pool.QueryRow(ctx, "SELECT COUNT(*) FROM stations WHERE id <= 9").Scan(&badCount)
	if err != nil {
		log.Fatal(err)
	}

	if badCount > 0 {
		fmt.Printf("❌ Found %d duplicate stations (IDs <= 9)\n", badCount)
	} else {
		fmt.Println("✅ No duplicate stations found (IDs <= 9 are gone)")
	}

	rows, err := pool.Query(ctx, "SELECT id, name, type FROM stations ORDER BY id")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	fmt.Println("Remaining Stations:")
	for rows.Next() {
		var id int
		var name, sType string
		rows.Scan(&id, &name, &sType)
		fmt.Printf("%d: %s (%s)\n", id, name, sType)
	}
}
