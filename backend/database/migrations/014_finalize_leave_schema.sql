-- Finalize Leave Schema to use UUIDs as requested
CREATE TABLE IF NOT EXISTS leave_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    officer_id UUID NOT NULL REFERENCES officer_profiles(user_id),
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    applied_at TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_by UUID, -- ID of the reviewing Junior Engineer
    reviewed_at TIMESTAMP
);

-- Index for performance on leave checks
CREATE INDEX IF NOT EXISTS idx_leave_apps_officer_dates ON leave_applications(officer_id, from_date, to_date) WHERE status = 'APPROVED';
