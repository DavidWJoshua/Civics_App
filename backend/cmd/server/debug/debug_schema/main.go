package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load("../../../../.env")

	dbURL := fmt.Sprintf("postgres://%s:%s@%s:%s/%s",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
	)

	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close(context.Background())

	ctx := context.Background()

	// Check tables
	fmt.Println("\n--- Tables ---")
	rows, _ := conn.Query(ctx, "SELECT table_name FROM information_schema.tables WHERE table_schema='public'")
	for rows.Next() {
		var name string
		rows.Scan(&name)
		fmt.Println(name)
	}
	rows.Close()

	// Check officer_profiles columns
	fmt.Println("\n--- officer_profiles columns ---")
	rows, _ = conn.Query(ctx, "SELECT column_name FROM information_schema.columns WHERE table_name='officer_profiles'")
	for rows.Next() {
		var name string
		rows.Scan(&name)
		fmt.Println(name)
	}
	rows.Close()

	// Check users columns (if exists)
	fmt.Println("\n--- users columns ---")
	rows, _ = conn.Query(ctx, "SELECT column_name FROM information_schema.columns WHERE table_name='users'")
	for rows.Next() {
		var name string
		rows.Scan(&name)
		fmt.Println(name)
	}
	rows.Close()
}
