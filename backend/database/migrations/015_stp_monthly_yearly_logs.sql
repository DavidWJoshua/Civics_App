-- ==========================================
-- STP MONTHLY & YEARLY LOGS
-- ==========================================

CREATE TABLE IF NOT EXISTS stp_monthly_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    pump_maint_status VARCHAR(50),
    motor_service_done VARCHAR(50),
    valve_lubrication VARCHAR(50),
    panel_inspection VARCHAR(50),
    emergency_power_test BOOLEAN,
    sand_filter_status VARCHAR(50),
    carbon_filter_status VARCHAR(50),
    remark TEXT,
    photo_url TEXT
);

CREATE TABLE IF NOT EXISTS stp_yearly_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    structural_audit BOOLEAN,
    tank_cleaning BOOLEAN,
    sludge_unit_overhaul BOOLEAN,
    electrical_safety_audit BOOLEAN,
    instrument_calibration VARCHAR(50),
    grit_chamber_service VARCHAR(50),
    remark TEXT,
    photo_url TEXT
);
