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

	// Query columns for officer_profiles
	rows, err := conn.Query(context.Background(),
		"SELECT column_name, data_type FROM information_schema.columns WHERE table_name='officer_profiles'")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	fmt.Println("--- officer_profiles columns ---")
	for rows.Next() {
		var name, dtype string
		rows.Scan(&name, &dtype)
		fmt.Printf("%s (%s)\n", name, dtype)
	}
}
