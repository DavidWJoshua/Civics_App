package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"

	"civic-complaint-system/backend/config"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load("../../.env"); err != nil {
		log.Printf("Warning: error loading .env file: %v", err)
	}

	cfg := config.LoadConfig()
	dbUrl := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", cfg.DBUser, cfg.DBPass, cfg.DBHost, cfg.DBPort, cfg.DBName)

	db, err := pgxpool.New(context.Background(), dbUrl)
	if err != nil {
		log.Fatalf("DB error: %v", err)
	}
	defer db.Close()

	// Let's run the query directly to see the error
	query := `SELECT user_id, name, phone_number FROM officer_profiles`
	rows, err := db.Query(context.Background(), query)
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		for rows.Next() {
			var uid, name, phone sql.NullString
			if err := rows.Scan(&uid, &name, &phone); err != nil {
				fmt.Printf("Scan error: %v\n", err)
			} else {
				fmt.Printf("Profile: user_id=%s name=%s phone=%s\n", uid.String, name.String, phone.String)
			}
		}
		rows.Close()
	}
}
