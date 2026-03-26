-- Drop the restrictive check constraint on role if it exists
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Create Stations Table
CREATE TABLE IF NOT EXISTS stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'lifting', 'pumping', 'stp'
    ward_number VARCHAR(50),
    capacity FLOAT, -- For STP (MLD)
    process_type VARCHAR(50) -- For STP (ASP, SBR, etc.)
);

-- Master Data: Equipment (Pumps, Motors, etc.)
CREATE TABLE IF NOT EXISTS equipment (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'pump', 'motor', 'blower', 'clarifier'
    details JSONB -- specific technical details
);

-- ==========================================
-- LIFTING STATION MODULE
-- ==========================================

CREATE TABLE IF NOT EXISTS lifting_daily_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id), -- Changed to UUID for users table compatibility
    log_date DATE NOT NULL,
    shift_type VARCHAR(20), -- 'day', 'night'
    equipment_id INTEGER REFERENCES equipment(id),
    pump_status VARCHAR(20),
    hours_reading FLOAT,
    voltage FLOAT,
    current_reading FLOAT,
    vibration_issue BOOLEAN,
    noise_issue BOOLEAN,
    leakage_issue BOOLEAN,
    sump_level_status VARCHAR(20),
    panel_status VARCHAR(20),
    cleaning_done BOOLEAN,
    remark TEXT,
    photo_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lifting_weekly_logs (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    lubrication_done BOOLEAN,
    belt_check_status VARCHAR(50),
    valve_status VARCHAR(50),
    panel_cleaned BOOLEAN,
    earthing_status VARCHAR(50),
    standby_pump_test BOOLEAN,
    minor_fault BOOLEAN,
    remark TEXT,
    photo_url TEXT
);

CREATE TABLE IF NOT EXISTS lifting_monthly_logs (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    insulation_test_status VARCHAR(50),
    bearing_condition VARCHAR(50),
    alignment_status VARCHAR(50),
    foundation_bolt_status VARCHAR(50),
    starter_panel_status VARCHAR(50),
    load_test_done BOOLEAN,
    energy_consumption FLOAT
);

CREATE TABLE IF NOT EXISTS lifting_yearly_logs (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    overhaul_done BOOLEAN,
    rewinding_done BOOLEAN,
    impeller_condition VARCHAR(50),
    seal_replaced BOOLEAN,
    calibration_done BOOLEAN,
    capacity_test_result VARCHAR(50),
    safety_audit_done BOOLEAN,
    third_party_inspection BOOLEAN,
    certificate_url TEXT
);

-- ==========================================
-- PUMPING STATION MODULE
-- ==========================================

CREATE TABLE IF NOT EXISTS pumping_daily_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    shift_type VARCHAR(20),
    pumps_running_count INTEGER,
    inlet_level_status VARCHAR(50),
    outlet_pressure FLOAT,
    flow_rate FLOAT,
    voltage FLOAT,
    current_reading FLOAT,
    power_factor FLOAT,
    vibration_issue BOOLEAN,
    noise_issue BOOLEAN,
    leakage_issue BOOLEAN,
    panel_alarm_status VARCHAR(50),
    sump_cleanliness VARCHAR(50),
    screen_bar_cleaned BOOLEAN,
    remark TEXT,
    photo_url TEXT
);

CREATE TABLE IF NOT EXISTS pumping_weekly_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE,
    lubrication_done BOOLEAN,
    valve_check VARCHAR(50),
    standby_test BOOLEAN,
    panel_cleaned BOOLEAN,
    earthing_status VARCHAR(50),
    cable_condition VARCHAR(50),
    minor_fault BOOLEAN,
    remark TEXT,
    photo_url TEXT
);

CREATE TABLE IF NOT EXISTS pumping_monthly_logs (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE,
    insulation_resistance FLOAT,
    bearing_condition VARCHAR(50),
    alignment_status VARCHAR(50),
    foundation_bolt_status VARCHAR(50),
    starter_test_status VARCHAR(50),
    load_test_done BOOLEAN,
    energy_consumption FLOAT,
    preventive_action TEXT,
    remark TEXT
);

CREATE TABLE IF NOT EXISTS pumping_yearly_logs (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE,
    overhaul_done BOOLEAN,
    rewinding_done BOOLEAN,
    impeller_condition VARCHAR(50),
    seal_replaced BOOLEAN,
    calibration_done BOOLEAN,
    capacity_test_result VARCHAR(50),
    safety_audit_done BOOLEAN,
    inspection_flag BOOLEAN,
    remark TEXT
);

-- ==========================================
-- STP MODULE
-- ==========================================

CREATE TABLE IF NOT EXISTS stp_daily_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE NOT NULL,
    inlet_flow_rate FLOAT,
    inlet_ph FLOAT,
    inlet_bod FLOAT,
    inlet_cod FLOAT,
    inlet_tss FLOAT,
    inlet_oil_grease FLOAT,
    inlet_temp FLOAT,
    inlet_color_odour VARCHAR(50),
    do_level FLOAT,
    mlss FLOAT,
    mcrt FLOAT,
    sv30 FLOAT,
    fm_ratio FLOAT,
    blower_hours FLOAT,
    sludge_depth FLOAT,
    ras_flow FLOAT,
    was_flow FLOAT,
    scum_present BOOLEAN,
    outlet_flow_rate FLOAT,
    outlet_ph FLOAT,
    outlet_bod FLOAT,
    outlet_cod FLOAT,
    outlet_tss FLOAT,
    outlet_oil_grease FLOAT,
    outlet_fecal_coliform FLOAT,
    residual_chlorine FLOAT,
    sludge_generated FLOAT,
    sludge_dried FLOAT,
    moisture_content FLOAT,
    disposal_method VARCHAR(50),
    drying_bed_condition VARCHAR(50),
    power_kwh FLOAT,
    energy_per_mld FLOAT,
    chlorine_usage FLOAT,
    polymer_usage FLOAT,
    chemical_stock_status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS stp_maintenance_logs (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    operator_id UUID REFERENCES users(id),
    log_date DATE,
    type VARCHAR(20), -- 'weekly' or 'monthly'
    blower_maint_done BOOLEAN,
    diffuser_cleaning_done BOOLEAN,
    clarifier_check VARCHAR(50),
    lab_calibrated BOOLEAN,
    analyzer_status VARCHAR(50)
);

-- ==========================================
-- FAULT & ESCALATION
-- ==========================================

CREATE TABLE IF NOT EXISTS faults (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id),
    equipment_id INTEGER REFERENCES equipment(id),
    reported_by UUID REFERENCES users(id),
    report_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fault_type VARCHAR(50), -- Electrical, Mechanical, Civil
    severity VARCHAR(20), -- Low, Medium, High
    emergency_shutdown BOOLEAN,
    escalation_required BOOLEAN,
    escalated_to_role VARCHAR(50), -- JE, AE
    escalation_reason TEXT,
    rectification_status VARCHAR(50) DEFAULT 'Pending', -- Pending, Completed
    rectified_at TIMESTAMP,
    rectification_remark TEXT
);


-- ==========================================
-- SEED OPERATOR USERS
-- ==========================================

-- Lifting Operators
INSERT INTO users (phone_number, role) VALUES 
('+919888888801', 'LIFTING_OPERATOR'),
('+919888888802', 'LIFTING_OPERATOR'),
('+919888888803', 'LIFTING_OPERATOR'),
('+919888888804', 'LIFTING_OPERATOR')
ON CONFLICT (phone_number, role) DO NOTHING;

-- Pumping Operators
INSERT INTO users (phone_number, role) VALUES 
('+919888888805', 'PUMPING_OPERATOR'),
('+919888888806', 'PUMPING_OPERATOR'),
('+919888888807', 'PUMPING_OPERATOR')
ON CONFLICT (phone_number, role) DO NOTHING;

-- STP Operators
INSERT INTO users (phone_number, role) VALUES 
('+919888888808', 'STP_OPERATOR'),
('+919888888809', 'STP_OPERATOR')
ON CONFLICT (phone_number, role) DO NOTHING;

-- Field Officers
INSERT INTO users (phone_number, role) VALUES 
('+919999999901', 'FIELD_OFFICER'),
('+919999999902', 'FIELD_OFFICER'),
('+919999999903', 'FIELD_OFFICER'),
('+919999999904', 'FIELD_OFFICER')
ON CONFLICT (phone_number, role) DO NOTHING;

-- Junior Engineer & Commissioner
INSERT INTO users (phone_number, role) VALUES 
('+919999999905', 'JUNIOR_ENGINEER'),
('+919999999906', 'COMMISSIONER')
ON CONFLICT (phone_number, role) DO NOTHING;
