package main

import (
	"context"
	"log"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/common/db"

	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load(".env")
	cfg := config.LoadConfig()
	pg, err := db.Connect(db.DBConfig{
		Host: cfg.DBHost,
		Port: cfg.DBPort,
		Name: cfg.DBName,
		User: cfg.DBUser,
		Pass: cfg.DBPass,
	})
	if err != nil {
		log.Fatal(err)
	}

	queries := []string{
		// 1. Drop constraints
		`ALTER TABLE IF EXISTS work_order_assignments DROP CONSTRAINT IF EXISTS work_order_assignments_complaint_id_fkey;`,
		`ALTER TABLE IF EXISTS complaint_assignments DROP CONSTRAINT IF EXISTS complaint_assignments_complaint_id_fkey;`,
		`ALTER TABLE IF EXISTS complaint_rejections DROP CONSTRAINT IF EXISTS complaint_rejections_complaint_id_fkey;`,
		`ALTER TABLE IF EXISTS work_order_budget DROP CONSTRAINT IF EXISTS work_order_budget_complaint_id_fkey;`,
		`ALTER TABLE IF EXISTS sla_tracking DROP CONSTRAINT IF EXISTS sla_tracking_complaint_id_fkey;`,
		`ALTER TABLE IF EXISTS escalation_history DROP CONSTRAINT IF EXISTS escalation_history_complaint_id_fkey;`,
		`ALTER TABLE IF EXISTS work_order_actions DROP CONSTRAINT IF EXISTS work_order_actions_complaint_id_fkey;`,
		`ALTER TABLE complaints DROP CONSTRAINT IF EXISTS complaints_pkey CASCADE;`,

		// 2. Change types
		`ALTER TABLE complaints ALTER COLUMN id DROP DEFAULT;`,
		`ALTER TABLE complaints ALTER COLUMN id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS work_order_assignments ALTER COLUMN complaint_id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS complaint_assignments ALTER COLUMN complaint_id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS complaint_rejections ALTER COLUMN complaint_id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS work_order_budget ALTER COLUMN complaint_id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS sla_tracking ALTER COLUMN complaint_id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS escalation_history ALTER COLUMN complaint_id TYPE VARCHAR(50);`,
		`ALTER TABLE IF EXISTS work_order_actions ALTER COLUMN complaint_id TYPE VARCHAR(50);`,

		// 3. Re-add constraints
		`ALTER TABLE complaints ADD PRIMARY KEY (id);`,
		`ALTER TABLE IF EXISTS work_order_assignments ADD CONSTRAINT work_order_assignments_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
		`ALTER TABLE IF EXISTS complaint_assignments ADD CONSTRAINT complaint_assignments_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
		`ALTER TABLE IF EXISTS complaint_rejections ADD CONSTRAINT complaint_rejections_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
		`ALTER TABLE IF EXISTS work_order_budget ADD CONSTRAINT work_order_budget_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
		`ALTER TABLE IF EXISTS sla_tracking ADD CONSTRAINT sla_tracking_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
		`ALTER TABLE IF EXISTS escalation_history ADD CONSTRAINT escalation_history_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
		`ALTER TABLE IF EXISTS work_order_actions ADD CONSTRAINT work_order_actions_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;`,
	}

	for _, q := range queries {
		_, err := pg.Exec(context.Background(), q)
		if err != nil {
			log.Println("Error executing:", q, err)
		} else {
			log.Println("Success:", q)
		}
	}
}
