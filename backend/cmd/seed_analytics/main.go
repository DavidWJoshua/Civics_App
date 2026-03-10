package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"

	"civic-complaint-system/backend/config"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env
	if err := godotenv.Load(); err != nil {
		fmt.Println("⚠️ .env not found, relying on environment variables")
	}

	cfg := config.LoadConfig()

	dbURL := fmt.Sprintf("postgres://%s:%s@%s:%s/%s",
		cfg.DBUser, cfg.DBPass, cfg.DBHost, cfg.DBPort, cfg.DBName)

	if cfg.DBHost == "" {
		dbURL = "postgres://postgres:postgres@localhost:5432/civic_db"
		fmt.Println("⚠️ Config empty, using default localhost URL")
	}

	dbConf, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		log.Fatalf("Unable to parse config: %v", err)
	}

	db, err := pgxpool.NewWithConfig(context.Background(), dbConf)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer db.Close()

	ctx := context.Background()

	fmt.Println("🌱 Seeding Analytics Data based on 008_operator_module.sql...")

	seedLifting(ctx, db)
	seedPumping(ctx, db)
	seedSTP(ctx, db)

	fmt.Println("✅ Seeding Complete!")
}

func seedLifting(ctx context.Context, db *pgxpool.Pool) {
	rows, err := db.Query(ctx, "SELECT id FROM stations WHERE type ILIKE 'lifting'")
	if err != nil {
		log.Fatalf("Error querying stations: %v", err)
	}
	var stations []int
	for rows.Next() {
		var id int
		rows.Scan(&id)
		stations = append(stations, id)
	}
	rows.Close()

	if len(stations) == 0 {
		fmt.Println("⚠️ No Lifting Stations found. Skipping.")
		return
	}

	// Get an operator (LIFTING_OPERATOR or generic OPERATOR)
	var operatorID string
	err = db.QueryRow(ctx, "SELECT id FROM users WHERE role IN ('LIFTING_OPERATOR', 'OPERATOR') LIMIT 1").Scan(&operatorID)
	if err != nil {
		// Try finding ANY user if specific role fails, or create one
		fmt.Println("⚠️ No LIFTING_OPERATOR found. Trying to create dummy.")
		operatorID = "00000000-0000-0000-0000-000000000001"
		_, err = db.Exec(ctx, "INSERT INTO users (id, phone_number, role, password_hash) VALUES ($1, '+919888888999', 'LIFTING_OPERATOR', 'hash') ON CONFLICT DO NOTHING", operatorID)
		// Note: migration 008 uses phone_number, not email/name in some inserts, but schema has name/email usually. Check migration again?
		// Migration 008 inserts: phone_number, role.
	}

	for _, sID := range stations {
		var exists bool
		db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM lifting_daily_logs WHERE station_id=$1 AND log_date::date = CURRENT_DATE)", sID).Scan(&exists)
		if exists {
			continue
		}

		_, err = db.Exec(ctx, `
			INSERT INTO lifting_daily_logs (
				station_id, operator_id, log_date, 
                shift_type, pump_status, hours_reading,
                voltage, current_reading,
                vibration_issue, noise_issue, leakage_issue,
                sump_level_status, panel_status,
                cleaning_done, remark, created_at
			) VALUES (
				$1, $2, CURRENT_DATE,
                'Morning', 'Running', $3,
                230.5, 12.5,
                $4, $5, $6,
                'Normal', 'Normal',
                TRUE, 'Auto-generated log', NOW()
			)
		`, sID, operatorID,
			rand.Float64()*10+2, // Hours
			rand.Intn(10) > 8,   // Vibration
			rand.Intn(10) > 8,   // Noise
			rand.Intn(10) > 9,   // Leakage
		)
		if err != nil {
			fmt.Printf("Error seeding lifting log for %d: %v\n", sID, err)
		} else {
			fmt.Printf("Inserted Lifting Log for %d\n", sID)
		}
	}
}

func seedPumping(ctx context.Context, db *pgxpool.Pool) {
	rows, err := db.Query(ctx, "SELECT id FROM stations WHERE type ILIKE 'pumping'")
	if err != nil {
		log.Fatalf("Error querying pumping stations: %v", err)
	}
	var stations []int
	for rows.Next() {
		var id int
		rows.Scan(&id)
		stations = append(stations, id)
	}
	rows.Close()

	if len(stations) == 0 {
		fmt.Println("⚠️ No Pumping Stations found. Skipping.")
		return
	}

	var operatorID string
	db.QueryRow(ctx, "SELECT id FROM users WHERE role IN ('PUMPING_OPERATOR', 'OPERATOR') LIMIT 1").Scan(&operatorID)
	if operatorID == "" {
		operatorID = "00000000-0000-0000-0000-000000000002" // Dummy
		db.Exec(ctx, "INSERT INTO users (id, phone_number, role, password_hash) VALUES ($1, '+919888888998', 'PUMPING_OPERATOR', 'hash') ON CONFLICT DO NOTHING", operatorID)
	}

	for _, sID := range stations {
		var exists bool
		db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM pumping_daily_logs WHERE station_id=$1 AND log_date::date = CURRENT_DATE)", sID).Scan(&exists)
		if exists {
			continue
		}

		_, err = db.Exec(ctx, `
			INSERT INTO pumping_daily_logs (
				station_id, operator_id, log_date,
                shift_type, pumps_running_count,
                outlet_pressure, flow_rate,
                voltage, current_reading, power_factor,
                vibration_issue, noise_issue, leakage_issue,
                panel_alarm_status, sump_cleanliness,
                screen_bar_cleaned, remark
			) VALUES (
				$1, $2, CURRENT_DATE,
                'Morning', 1,
                $3, $4,
                415.0, 45.5, $5,
                FALSE, FALSE, FALSE,
                'Normal', 'Clean',
                TRUE, 'Auto-generated log'
			)
		`, sID, operatorID,
			4.5+rand.Float64()*1.5,  // Pressure
			1000+rand.Float64()*500, // Flow
			0.85+rand.Float64()*0.1, // PF
		)
		if err != nil {
			fmt.Printf("Error seeding pumping log for %d: %v\n", sID, err)
		} else {
			fmt.Printf("Inserted Pumping Log for %d\n", sID)
		}
	}
}

func seedSTP(ctx context.Context, db *pgxpool.Pool) {
	rows, err := db.Query(ctx, "SELECT id FROM stations WHERE type ILIKE 'stp'")
	if err != nil {
		log.Fatalf("Error querying stp stations: %v", err)
	}
	var stations []int
	for rows.Next() {
		var id int
		rows.Scan(&id)
		stations = append(stations, id)
	}
	rows.Close()

	if len(stations) == 0 {
		fmt.Println("⚠️ No STP Stations found. Skipping.")
		return
	}

	var operatorID string
	db.QueryRow(ctx, "SELECT id FROM users WHERE role IN ('STP_OPERATOR', 'OPERATOR') LIMIT 1").Scan(&operatorID)
	if operatorID == "" {
		operatorID = "00000000-0000-0000-0000-000000000003"
		db.Exec(ctx, "INSERT INTO users (id, phone_number, role, password_hash) VALUES ($1, '+919888888997', 'STP_OPERATOR', 'hash') ON CONFLICT DO NOTHING", operatorID)
	}

	for _, sID := range stations {
		var exists bool
		db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM stp_daily_logs WHERE station_id=$1 AND log_date::date = CURRENT_DATE)", sID).Scan(&exists)
		if exists {
			continue
		}

		// NO shift_type in STP logs!
		_, err = db.Exec(ctx, `
			INSERT INTO stp_daily_logs (
				station_id, operator_id, log_date,
                inlet_flow_rate, outlet_flow_rate,
                inlet_bod, outlet_bod,
                inlet_cod, outlet_cod,
                inlet_tss, outlet_tss,
                inlet_ph, outlet_ph,
                do_level, mlss, 
                chlorine_usage, chemical_stock_status,
                remark
			) VALUES (
				$1, $2, CURRENT_DATE,
                5.5, 5.2,
                250, 20,
                400, 45,
                300, 25,
                7.2, 7.5,
                2.5, 2500,
                5.0, 'Available',
                'Auto-generated log'
			)
		`, sID, operatorID)
		if err != nil {
			fmt.Printf("Error seeding STP log for %d: %v\n", sID, err)
		} else {
			fmt.Printf("Inserted STP Log for %d\n", sID)
		}
	}
}
