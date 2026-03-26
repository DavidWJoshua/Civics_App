-- 1. Fix Stations Data
-- Remove duplicates and specific entries (IDs 1-9 mostly have 0 capacity or NULL)
-- We will keep the entries with higher IDs (10-18) as they have valid capacity data/process types
-- But first, we must update foreign keys if any operator logs or equipment point to the old stations.

-- NOTE: Assuming for now we can just delete the old ones if no data is linked, or we default to keeping the new ones.
-- The user request is: "Remove the duplicate from this table and it should contain 4 lifting , 3 pumping and 2 stp operators only ."
-- The "good" rows seem to be:
-- 10, Lifting 1, 5
-- 11, Lifting 2, 4.5
-- 12, Lifting 3, 6
-- 13, Lifting 4, 5.5
-- 14, Pumping 1, 10
-- 15, Pumping 2, 12
-- 16, Pumping 3, 8
-- 17, STP 1, 20
-- 18, STP 2, 25

-- IDs 1-9 are the ones to remove.
-- However, we must ensure constraint safety.

ALTER TABLE equipment DROP CONSTRAINT IF EXISTS equipment_station_id_fkey;
ALTER TABLE lifting_daily_logs DROP CONSTRAINT IF EXISTS lifting_daily_logs_station_id_fkey;
ALTER TABLE pumping_daily_logs DROP CONSTRAINT IF EXISTS pumping_daily_logs_station_id_fkey;
ALTER TABLE stp_daily_logs DROP CONSTRAINT IF EXISTS stp_daily_logs_station_id_fkey;
ALTER TABLE faults DROP CONSTRAINT IF EXISTS faults_station_id_fkey;

-- Re-map before delete (Safe update)
UPDATE equipment SET station_id = station_id + 9 WHERE station_id <= 9;
UPDATE lifting_daily_logs SET station_id = station_id + 9 WHERE station_id <= 9;
UPDATE pumping_daily_logs SET station_id = station_id + 9 WHERE station_id <= 9;
UPDATE stp_daily_logs SET station_id = station_id + 9 WHERE station_id <= 9;
UPDATE faults SET station_id = station_id + 9 WHERE station_id <= 9;

-- Delete old stations
DELETE FROM stations WHERE id <= 9;

-- Restore FKs
ALTER TABLE equipment ADD CONSTRAINT equipment_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id);
ALTER TABLE lifting_daily_logs ADD CONSTRAINT lifting_daily_logs_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id);
ALTER TABLE pumping_daily_logs ADD CONSTRAINT pumping_daily_logs_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id);
ALTER TABLE stp_daily_logs ADD CONSTRAINT stp_daily_logs_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id);
ALTER TABLE faults ADD CONSTRAINT faults_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id);

-- 2. Create Field Officer Leaves Table (if not exists)
CREATE TABLE IF NOT EXISTS officer_leaves (
    id SERIAL PRIMARY KEY,
    officer_id VARCHAR(50) REFERENCES users(phone_number),
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    reason TEXT,
    attachment_url TEXT,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    approved_by VARCHAR(50) REFERENCES users(phone_number),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create Work Order Actions Table (for reassignment history)
CREATE TABLE IF NOT EXISTS work_order_actions (
    id SERIAL PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(id),
    previous_officer_id VARCHAR(50),
    new_officer_id VARCHAR(50),
    action_type VARCHAR(50), -- 'REASSIGNMENT', 'ESCALATION'
    reason TEXT,
    performed_by VARCHAR(50), -- System or User ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create Escalation History (if not exists, as mentioned in prompt)
CREATE TABLE IF NOT EXISTS escalation_history (
    id SERIAL PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(id),
    change_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Add Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_leaves_officer_dates ON officer_leaves(officer_id, from_date, to_date);
-- CREATE INDEX IF NOT EXISTS idx_assignments_officer_active ON work_order_assignments(officer_id, is_active); -- Table might not exist yet if missed migration
