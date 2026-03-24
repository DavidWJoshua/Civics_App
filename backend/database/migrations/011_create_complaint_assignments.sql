CREATE TABLE IF NOT EXISTS complaint_assignments (
    id SERIAL PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(id),
    assigned_to_user_id VARCHAR(50) REFERENCES users(phone_number),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Active'
);
