package main

import (
	"context"
	"encoding/json"
	"log"
	"os"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/common/db"

	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load(".env")
	cfg := config.LoadConfig()
	pg, err := db.Connect(context.Background(), db.DBConfig{
		Host: cfg.DBHost,
		Port: cfg.DBPort,
		Name: cfg.DBName,
		User: cfg.DBUser,
		Pass: cfg.DBPass,
	})
	if err != nil {
		log.Fatal(err)
	}

	rows, err := pg.Query(context.Background(), `
		SELECT c.id, c.status, c.ward, w.officer_id 
		FROM complaints c 
		LEFT JOIN work_order_assignments w ON c.id = w.complaint_id 
		ORDER BY c.created_at DESC LIMIT 5
	`)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	var out []map[string]string
	for rows.Next() {
		var id, status, ward string
		var officerID *string
		if err := rows.Scan(&id, &status, &ward, &officerID); err != nil {
			log.Fatal(err)
		}
		
		off := "NULL"
		if officerID != nil {
			off = *officerID
		}
		out = append(out, map[string]string{"id": id, "status": status, "ward": ward, "officer_id": off})
	}
	
	bytes, _ := json.MarshalIndent(out, "", "  ")
	os.WriteFile("debug_out.json", bytes, 0644)
}
