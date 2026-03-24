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

	rows, err := conn.Query(context.Background(), "SELECT user_id, name, shift, is_active FROM officer_profiles")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	fmt.Println("--- officer_profiles data ---")
	for rows.Next() {
		var uid, name, shift string
		var active bool
		rows.Scan(&uid, &name, &shift, &active)
		fmt.Printf("UserID: %s, Name: %s, Shift: %s, Active: %v\n", uid, name, shift, active)
	}
}
