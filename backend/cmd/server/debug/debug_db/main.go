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

	// 1. Check Officers
	fmt.Println("\n--- Active Officers ---")
	rows, _ := conn.Query(ctx, "SELECT user_id, name, is_active FROM officer_profiles")
	count := 0
	for rows.Next() {
		var id, name string
		var active bool
		if err := rows.Scan(&id, &name, &active); err != nil {
			log.Println("Scan error:", err)
			continue
		}
		fmt.Printf("ID: %s | Name: %s | Active: %v\n", id, name, active)
		count++
	}
	rows.Close()
	fmt.Printf("Total Active Officers: %d\n", count)

	// 2. Check Complaints
	fmt.Println("\n--- Recent Complaints ---")
	rows, _ = conn.Query(ctx, "SELECT id, category, status FROM complaints ORDER BY created_at DESC LIMIT 5")
	for rows.Next() {
		var id, cat, status string
		rows.Scan(&id, &cat, &status)
		fmt.Printf("ID: %s | Cat: %s | Status: %s\n", id, cat, status)
	}
	rows.Close()

	// 3. Check Assignments
	fmt.Println("\n--- Work Order Assignments ---")
	rows, _ = conn.Query(ctx, "SELECT complaint_id, officer_id, is_active FROM work_order_assignments")
	for rows.Next() {
		var cid, oid string
		var active bool
		rows.Scan(&cid, &oid, &active)
		fmt.Printf("Complaint: %s | Officer: %s | Active: %v\n", cid, oid, active)
	}
	rows.Close()
}
