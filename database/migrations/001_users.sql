CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(15) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role = 'CITIZEN'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (phone_number, role)
);
