CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(15) NOT NULL,
    role VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_phone_role UNIQUE (phone_number, role)
);
CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    citizen_id UUID NOT NULL,

    category VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,

    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,

    location_json JSONB,

    status VARCHAR(20) NOT NULL DEFAULT 'RAISED',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_citizen
        FOREIGN KEY (citizen_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);
CREATE INDEX idx_complaints_citizen ON complaints(citizen_id);
CREATE INDEX idx_complaints_status ON complaints(status);
ALTER TABLE complaints ADD COLUMN image_url TEXT;

ALTER TABLE complaints ADD COLUMN street TEXT;
ALTER TABLE complaints ADD COLUMN area TEXT;
ALTER TABLE complaints ADD COLUMN ward TEXT;
ALTER TABLE complaints ADD COLUMN city TEXT;

ALTER TABLE complaints ADD COLUMN IF NOT EXISTS rating INT;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS feedback_text TEXT;

CREATE TABLE work_order_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    complaint_id UUID NOT NULL,
    officer_id UUID NOT NULL,

    assigned_role VARCHAR(30) NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    is_active BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_assignment_complaint
        FOREIGN KEY (complaint_id)
        REFERENCES complaints(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_assignment_officer
        FOREIGN KEY (officer_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_assignment_complaint ON work_order_assignments(complaint_id);
CREATE INDEX idx_assignment_officer ON work_order_assignments(officer_id);

CREATE TABLE sla_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    complaint_id UUID NOT NULL,

    sla_start_time TIMESTAMP NOT NULL,
    sla_deadline TIMESTAMP NOT NULL,

    current_level VARCHAR(30) NOT NULL,
    is_breached BOOLEAN DEFAULT FALSE,

    last_checked_at TIMESTAMP,

    CONSTRAINT fk_sla_complaint
        FOREIGN KEY (complaint_id)
        REFERENCES complaints(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_sla_deadline ON sla_tracking(sla_deadline);

CREATE TABLE escalation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    complaint_id UUID NOT NULL,

    from_role VARCHAR(30),
    to_role VARCHAR(30),

    escalation_reason VARCHAR(50),
    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_escalation_complaint
        FOREIGN KEY (complaint_id)
        REFERENCES complaints(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_escalation_complaint ON escalation_history(complaint_id);

CREATE TABLE work_order_budget (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    complaint_id UUID NOT NULL,

    estimated_cost NUMERIC(10,2) NOT NULL,
    approved_cost NUMERIC(10,2),

    proposed_by UUID NOT NULL,
    approved_by UUID,

    approval_role VARCHAR(30),
    status VARCHAR(20) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,

    CONSTRAINT fk_budget_complaint
        FOREIGN KEY (complaint_id)
        REFERENCES complaints(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_budget_status ON work_order_budget(status);


CREATE TABLE work_order_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    complaint_id UUID NOT NULL,
    action_by UUID NOT NULL,

    action_type VARCHAR(30) NOT NULL,
    action_reason TEXT,
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_action_complaint
        FOREIGN KEY (complaint_id)
        REFERENCES complaints(id)
        ON DELETE CASCADE
);

CREATE TABLE officer_leaves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    officer_id UUID NOT NULL REFERENCES users(id),
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,

    reason TEXT,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING / APPROVED / REJECTED

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE complaint_rejections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    rejected_by UUID NOT NULL REFERENCES users(id),
    role VARCHAR(30) NOT NULL,
    reason TEXT NOT NULL,

    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE complaints
ADD COLUMN last_modified_role VARCHAR(30);

ALTER TABLE complaints
ADD COLUMN completion_photo_url TEXT,
ADD COLUMN completion_latitude DOUBLE PRECISION,
ADD COLUMN completion_longitude DOUBLE PRECISION,
ADD COLUMN completed_at TIMESTAMP;

ALTER TABLE work_order_actions
ADD COLUMN action_role VARCHAR(30);

-- 1. Create Officer Profiles Table (Linked to Users)
CREATE TABLE IF NOT EXISTS officer_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    shift VARCHAR(50),      -- Morning, Evening, Night
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Insert Profile Details into 'officer_profiles'
-- We select the ID from 'users' based on the phone number to link them correctly

-- Field Officers
INSERT INTO officer_profiles (user_id, name, shift)
SELECT id, 'Field Officer 1', 'Morning' 
FROM users WHERE phone_number = '+919999999901'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO officer_profiles (user_id, name, shift)
SELECT id, 'Field Officer 2', 'Evening' 
FROM users WHERE phone_number = '+919999999902'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO officer_profiles (user_id, name, shift)
SELECT id, 'Field Officer 3', 'Morning' 
FROM users WHERE phone_number = '+919999999903'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO officer_profiles (user_id, name, shift)
SELECT id, 'Field Officer 4', 'Night' 
FROM users WHERE phone_number = '+919999999904'
ON CONFLICT (user_id) DO NOTHING;

-- Junior Engineer
INSERT INTO officer_profiles (user_id, name, shift)
SELECT id, 'Junior Engineer A', 'General' 
FROM users WHERE phone_number = '+919999999905'
ON CONFLICT (user_id) DO NOTHING;

-- Commissioner
INSERT INTO officer_profiles (user_id, name, shift)
SELECT id, 'Commissioner X', 'General' 
FROM users WHERE phone_number = '+919999999906'
ON CONFLICT (user_id) DO NOTHING;

ALTER TABLE work_order_assignments ADD COLUMN created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE officer_profiles
ADD COLUMN phone_number VARCHAR(15);

UPDATE officer_profiles op
SET phone_number = u.phone_number
FROM users u
WHERE op.user_id = u.id;


INSERT INTO work_order_assignments (
    complaint_id,
    officer_id,
    assigned_role,
    is_active
)
SELECT
    c.id,
    'f9b57fbd-dcbd-4c3b-9ec8-c3ca3ca2d7b6', -- your FIELD_OFFICER user_id
    'FIELD_OFFICER',
    true
FROM complaints c
WHERE c.status = 'RAISED';

UPDATE complaints
SET status = 'ALLOCATED'
WHERE id IN (
  SELECT complaint_id
  FROM work_order_assignments
  WHERE is_active = true
);


ALTER TABLE officer_profiles
ADD COLUMN ward_from INT,
ADD COLUMN ward_to INT;

UPDATE complaints
SET ward = NULL
WHERE ward = '';

ALTER TABLE complaints
ALTER COLUMN ward TYPE INT
USING ward::INTEGER;


select * from work_order_budget ;
SELECT * FROM escalation_history;
SELECT * FROM sla_tracking;
SELECT * FROM complaints;
select * from users;

INSERT INTO escalation_history
(id, complaint_id, from_role, to_role, escalation_reason, escalated_at)
VALUES (
gen_random_uuid(),
'dacf8846-63c1-497a-83f5-ee19e51d17ec',
'FIELD_OFFICER',
'JUNIOR_ENGINEER',
'SLA breached',
NOW()
);

SELECT * FROM lifting_daily_logs;
select * from officer_profiles;
select * from complaints;
select * from sla_tracking;
select * from escalation_history;
select * from lifting_daily_logs;
delete from lifting_daily_logs;
delete from lifting_weekly_logs;
delete from lifting_yearly_logs;


CREATE TABLE IF NOT EXISTS leave_applications
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    officer_id UUID NOT NULL REFERENCES officer_profiles(user_id),
    days INT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    applied_at TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_by UUID, -- ID of the reviewing Junior Engineer
    reviewed_at TIMESTAMP
);

INSERT INTO users (phone_number, role) VALUES
	('+919999999901', 'FIELD_OFFICER'),
	('+919999999902', 'FIELD_OFFICER'),
	('+919999999903', 'FIELD_OFFICER'),
	('+919999999904', 'FIELD_OFFICER'),
	('+919999999905', 'JUNIOR_ENGINEER'),
	('+919999999906', 'COMMISSIONER');


select * from stations;
	