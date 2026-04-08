package main

import (
	"context"
	"log"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/common/db"
	"civic-complaint-system/backend/internal/field_officer"

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

	repo := field_officer.Repository{DB: pg}
	officerID := "da0be945-6d0b-4733-99eb-2eeace7d7f68"

	_, err = repo.GetComplaintsByStatus(context.Background(), officerID, "ALLOCATED", field_officer.ComplaintFilter{})
	log.Printf("Error string verbatim: [%v]", err)
}
