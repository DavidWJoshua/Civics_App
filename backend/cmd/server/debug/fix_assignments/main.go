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

	// 1. Get an active officer
	var officerID string
	err = conn.QueryRow(ctx, "SELECT user_id FROM officer_profiles WHERE is_active = TRUE LIMIT 1").Scan(&officerID)
	if err != nil {
		log.Fatal("No active officer found:", err)
	}
	fmt.Println("Found Officer:", officerID)

	// 2. Find RAISED complaints
	rows, _ := conn.Query(ctx, "SELECT id FROM complaints WHERE status = 'RAISED'")
	var complaintIDs []string
	for rows.Next() {
		var id string
		rows.Scan(&id)
		complaintIDs = append(complaintIDs, id)
	}
	rows.Close()

	if len(complaintIDs) == 0 {
		fmt.Println("No RAISED complaints to assign.")
		return
	}

	fmt.Printf("Assigning %d complaints to officer %s...\n", len(complaintIDs), officerID)

	// 3. Assign them
	for _, cid := range complaintIDs {
		_, err := conn.Exec(ctx, "INSERT INTO work_order_assignments (complaint_id, officer_id, is_active, created_at) VALUES ($1, $2, TRUE, NOW())", cid, officerID)
		if err != nil {
			log.Printf("Failed to assign complaint %s: %v\n", cid, err)
			continue
		}
		_, err = conn.Exec(ctx, "UPDATE complaints SET status = 'ALLOCATED' WHERE id = $1", cid)
		if err != nil {
			log.Printf("Failed to update status for %s: %v\n", cid, err)
		}
		fmt.Println("Assigned:", cid)
	}
	fmt.Println("Done.")
}
