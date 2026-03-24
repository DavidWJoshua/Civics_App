package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Println("⚠️ .env not found in current dir")
	}

	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbName := os.Getenv("DB_NAME")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", dbUser, dbPass, dbHost, dbPort, dbName)
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	seedComplaints(ctx, pool)
	seedOperatorLogs(ctx, pool)
	seedLeaves(ctx, pool)
}

func seedComplaints(ctx context.Context, pool *pgxpool.Pool) {
	fmt.Println("🌱 Seeding Complaints...")

	var citizenID string
	err := pool.QueryRow(ctx, "SELECT id FROM users WHERE role = 'CITIZEN' LIMIT 1").Scan(&citizenID)
	if err != nil {
		fmt.Println("⚠️ No citizen found, creating one...")
		err = pool.QueryRow(ctx, "INSERT INTO users (phone_number, role, name) VALUES ('9999999999', 'CITIZEN', 'Demo Citizen') RETURNING id").Scan(&citizenID)
		if err != nil {
			log.Printf("❌ Failed to create citizen: %v", err)
			return
		}
	}

	complaintTypes := []string{"Sewage Blockage", "Water Leakage", "Manhole Cover Missing", "Bad Smell", "Low Pressure"}
	severities := []string{"Low", "Medium", "High"}

	for i := 0; i < 15; i++ {
		cType := complaintTypes[rand.Intn(len(complaintTypes))]
		severity := severities[rand.Intn(len(severities))]
		wardNum := rand.Intn(10) + 1
		ward := fmt.Sprintf("%d", wardNum)

		query := `
			INSERT INTO complaints 
			(citizen_id, category, severity, latitude, longitude, street, area, ward, city, location_json, status, created_at)
			VALUES ($1, $2, $3, 12.97, 77.59, 'Demo Street', 'Demo Area', $4, 'Bangalore', '{}', 'OPEN', $5)
		`
		createdAt := time.Now().Add(-time.Duration(rand.Intn(240)) * time.Hour)

		_, err := pool.Exec(ctx, query, citizenID, cType, severity, ward, createdAt)
		if err != nil {
			log.Printf("Failed to insert complaint: %v", err)
		}
	}
	fmt.Println("✅ Inserted 15 Complaints")
}

func seedOperatorLogs(ctx context.Context, pool *pgxpool.Pool) {
	fmt.Println("🌱 Seeding Operator Logs...")

	rows, err := pool.Query(ctx, "SELECT id, role FROM users WHERE role IN ('LIFTING_OPERATOR', 'PUMPING_OPERATOR', 'STP_OPERATOR')")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	type Op struct {
		ID   string
		Role string
	}
	var operators []Op
	for rows.Next() {
		var o Op
		rows.Scan(&o.ID, &o.Role)
		operators = append(operators, o)
	}
	rows.Close()

	for _, op := range operators {
		var stationID int
		var stationType string
		switch op.Role {
		case "LIFTING_OPERATOR":
			stationType = "lifting"
		case "PUMPING_OPERATOR":
			stationType = "pumping"
		case "STP_OPERATOR":
			stationType = "stp"
		}

		err := pool.QueryRow(ctx, "SELECT id FROM stations WHERE type=$1 ORDER BY RANDOM() LIMIT 1", stationType).Scan(&stationID)
		if err != nil {
			log.Printf("No station found for %s", op.Role)
			continue
		}

		// 10 Daily Logs
		for i := 0; i < 10; i++ {
			date := time.Now().AddDate(0, 0, -i)
			insertDailyLog(ctx, pool, op.ID, op.Role, stationID, date)
		}
		// Weekly/Monthly/Yearly kept simple as requested focus is on "logs values" which usually implies daily monitoring
	}
	fmt.Println("✅ Inserted Rich Operator Logs")
}

func insertDailyLog(ctx context.Context, pool *pgxpool.Pool, opID, role string, stationID int, date time.Time) {
	// Random float helper
	rf := func(min, max float64) float64 { return min + rand.Float64()*(max-min) }
	// Random bool
	rb := func() bool { return rand.Intn(10) > 8 } // 10% chance of true (issue)

	switch role {
	case "LIFTING_OPERATOR":
		// voltage 380-440, current 10-50, hours 0-24
		query := `
			INSERT INTO lifting_daily_logs 
			(station_id, operator_id, log_date, shift_type, pump_status, hours_reading, voltage, current_reading, 
			 vibration_issue, noise_issue, leakage_issue, sump_level_status, panel_status, cleaning_done, remark)
			VALUES ($1, $2, $3, 'Day', 'Running', $4, $5, $6, $7, $8, $9, 'Normal', 'OK', true, 'Routine Check')
			ON CONFLICT DO NOTHING
		`
		pool.Exec(ctx, query, stationID, opID, date,
			rf(1000, 5000), rf(380, 440), rf(10, 50),
			rb(), rb(), rb())

	case "PUMPING_OPERATOR":
		// outlet_pressure 2-10 bar, flow_rate 100-500 m3/h
		query := `
			INSERT INTO pumping_daily_logs
			(station_id, operator_id, log_date, shift_type, pumps_running_count, inlet_level_status, 
			 outlet_pressure, flow_rate, voltage, current_reading, power_factor, 
			 vibration_issue, noise_issue, leakage_issue, panel_alarm_status, sump_cleanliness, screen_bar_cleaned, remark)
			VALUES ($1, $2, $3, 'Day', 2, 'Normal', $4, $5, $6, $7, $8, $9, $10, $11, 'No Alarm', 'Clean', true, 'All Good')
			ON CONFLICT DO NOTHING
		`
		pool.Exec(ctx, query, stationID, opID, date,
			rf(2, 8), rf(100, 500), rf(390, 420), rf(20, 80), rf(0.85, 0.99),
			rb(), rb(), rb())

	case "STP_OPERATOR":
		// inlet/outlet params
		query := `
			INSERT INTO stp_daily_logs
			(station_id, operator_id, log_date, 
			 inlet_flow_rate, inlet_ph, inlet_bod, inlet_cod, inlet_tss,
			 outlet_flow_rate, outlet_ph, outlet_bod, outlet_cod, outlet_tss,
			 power_kwh, chlorine_usage, disposal_method, chemical_stock_status)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, 'River Discharge', 'Sufficient')
			ON CONFLICT DO NOTHING
		`
		// Realistic STP values
		// Inlet: pH 6-8, BOD 200-300, COD 400-600, TSS 200-400
		// Outlet: pH 6.5-7.5, BOD <30 (say 10-25), COD <250 (say 50-100), TSS <100 (say 20-50)
		pool.Exec(ctx, query, stationID, opID, date,
			rf(5, 15), rf(6.0, 8.0), rf(200, 300), rf(400, 600), rf(200, 400),
			rf(4, 14), rf(6.5, 7.5), rf(10, 28), rf(50, 100), rf(20, 50),
			rf(100, 500), rf(5, 20))
	}
}

func insertWeeklyLog(ctx context.Context, pool *pgxpool.Pool, opID, role string, stationID int, date time.Time) {
	// Keep existing logic or simplify to just basic insertion if needed
	// For now, focusing on daily logs for charts/graphs
}

func insertMonthlyLog(ctx context.Context, pool *pgxpool.Pool, opID, role string, stationID int, date time.Time) {
}
func insertYearlyLog(ctx context.Context, pool *pgxpool.Pool, opID, role string, stationID int, date time.Time) {
}

func seedLeaves(ctx context.Context, pool *pgxpool.Pool) {
	fmt.Println("🌱 Seeding Leaves...")
	var officerID string
	err := pool.QueryRow(ctx, "SELECT id FROM users WHERE role = 'FIELD_OFFICER' LIMIT 1").Scan(&officerID)
	if err != nil {
		fmt.Println("⚠️ No field officer found for leave seeding")
		return
	}
	var jeID string
	err = pool.QueryRow(ctx, "SELECT id FROM users WHERE role = 'JUNIOR_ENGINEER' LIMIT 1").Scan(&jeID)
	if err != nil {
		fmt.Println("⚠️ No JE found for leave seeding")
		return
	}

	query := `
		INSERT INTO leave_applications 
		(officer_id, from_date, to_date, reason, status, reviewed_by, reviewed_at) 
		VALUES ($1, $2, $3, 'Annual Leave', 'APPROVED', $4, NOW())
		ON CONFLICT DO NOTHING
	`
	_, err = pool.Exec(ctx, query, officerID, time.Now().AddDate(0, 0, -2), time.Now().AddDate(0, 0, 2), jeID)
	if err != nil {
		log.Printf("❌ Failed to seed leave: %v", err)
	} else {
		fmt.Println("✅ Seeded one approved leave for demo")
	}
}
