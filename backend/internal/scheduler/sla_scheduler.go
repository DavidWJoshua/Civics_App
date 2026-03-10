package scheduler

import (
	"context"
	"log"
	"time"

	"civic-complaint-system/backend/internal/junior_engineer"
)

func StartSLACron(repo *junior_engineer.Repository) {

	ticker := time.NewTicker(1 * time.Minute)

	go func() {
		for range ticker.C {
			err := repo.EscalateBreachedComplaints(context.Background())
			if err != nil {
				log.Println("❌ SLA Escalation Failed:", err)
			} else {
				log.Println("✅ SLA Escalation Check Completed")
			}
		}
	}()
}
