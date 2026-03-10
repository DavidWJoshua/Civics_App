-- Add columns for Operator Profile to officer_profiles
ALTER TABLE officer_profiles 
ADD COLUMN IF NOT EXISTS station_id INTEGER REFERENCES stations(id),
ADD COLUMN IF NOT EXISTS station_type VARCHAR(20),
ADD COLUMN IF NOT EXISTS ward_number VARCHAR(10),
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
