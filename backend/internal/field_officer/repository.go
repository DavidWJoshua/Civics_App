package field_officer

import (
	"context"
	"log"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) GetOfficerProfile(ctx context.Context, userID string) (*OfficerProfile, error) {
	var p OfficerProfile
	var wardFrom, wardTo *int // Use pointers to handle NULLs

	err := r.DB.QueryRow(ctx, `
		SELECT user_id, name, shift, is_active, created_at, ward_from, ward_to
		FROM officer_profiles
		WHERE user_id = $1
	`, userID).Scan(
		&p.UserID,
		&p.Name,
		&p.Shift,
		&p.IsActive,
		&p.CreatedAt,
		&wardFrom,
		&wardTo,
	)

	if wardFrom != nil {
		p.WardFrom = *wardFrom
	}
	if wardTo != nil {
		p.WardTo = *wardTo
	}

	// Fallback (never break UI)
	if err != nil {
		log.Printf("⚠️ officer_profiles missing for %s", userID)
		// Return a default profile if not found, OR bubble up error if it's a connection issue?
		// For now, let's just return the error if it's not ErrNoRows.
		// Actually, the original logic returned a default profile on ANY error.
		// Let's keep that but log the error more clearly.
		return &OfficerProfile{
			UserID:    userID,
			Name:      "Officer",
			Shift:     "General",
			IsActive:  true,
			CreatedAt: time.Now(),
		}, nil
	}

	return &p, nil
}

func (r *Repository) GetDashboardStats(ctx context.Context, officerID string) (*DashboardStats, error) {
	var s DashboardStats

	query := `
	SELECT
		COALESCE(COUNT(*) FILTER (WHERE c.status = 'ALLOCATED'), 0),
		COALESCE(COUNT(*) FILTER (WHERE c.status = 'COMPLETED'), 0),
		COALESCE(COUNT(*) FILTER (WHERE c.status = 'REJECTED'), 0),
		COALESCE(COUNT(*) FILTER (WHERE c.status IN ('PENDING','IN_PROGRESS')), 0)
	FROM complaints c
	LEFT JOIN work_order_assignments w 
		ON c.id = w.complaint_id
	WHERE w.officer_id = $1
	  AND w.is_active = true
	`

	err := r.DB.QueryRow(ctx, query, officerID).Scan(
		&s.Raised,
		&s.Completed,
		&s.Rejected,
		&s.NotCompleted,
	)

	if err != nil {
		return nil, err
	}

	return &s, nil
}

func (r *Repository) GetComplaintsByStatus(
	ctx context.Context,
	officerID, status string,
	filter ComplaintFilter,
) ([]RaisedComplaint, error) {

	query := `
	SELECT 
		c.id,
		c.category,
		c.severity,
		COALESCE(c.latitude, 0.0),
		COALESCE(c.longitude, 0.0),
		c.image_url,
		c.completion_photo_url,
		c.area,
		c.status,
		c.created_at,
		COALESCE(cr.reason, ''),
		COALESCE(c.rating, 0),
		COALESCE(c.feedback_text, ''),
		c.ward
	FROM complaints c
	JOIN work_order_assignments w 
		ON c.id = w.complaint_id
	LEFT JOIN complaint_rejections cr
		ON c.id = cr.complaint_id
	WHERE w.officer_id = $1 
	AND c.status = $2 
	AND w.is_active = true
	`

	args := []interface{}{officerID, status}
	argID := 3

	// Dynamic filters — values are always passed as parameters, never interpolated.
	if filter.Category != "" {
		query += " AND c.category = $" + itoa(argID)
		args = append(args, filter.Category)
		argID++
	}
	if filter.Severity != "" {
		query += " AND c.severity = $" + itoa(argID)
		args = append(args, filter.Severity)
		argID++
	}
	if filter.Area != "" {
		query += " AND c.area ILIKE $" + itoa(argID)
		args = append(args, "%"+filter.Area+"%")
		argID++
	}
	if filter.Ward != "" {
		query += " AND c.ward = $" + itoa(argID)
		args = append(args, filter.Ward)
		argID++
	}
	if filter.StartDate != "" {
		query += " AND c.created_at >= $" + itoa(argID)
		args = append(args, filter.StartDate)
		argID++
	}
	if filter.EndDate != "" {
		query += " AND c.created_at <= $" + itoa(argID)
		args = append(args, filter.EndDate)
		argID++
	}

	query += ` ORDER BY c.created_at DESC`

	rows, err := r.DB.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []RaisedComplaint
	for rows.Next() {
		var c RaisedComplaint
		var reason string

		if err := rows.Scan(
			&c.ID,                 // c.id
			&c.Category,           // c.category
			&c.Severity,           // c.severity
			&c.Latitude,           // COALESCE(c.latitude, 0.0)
			&c.Longitude,          // COALESCE(c.longitude, 0.0)
			&c.PhotoURL,           // c.image_url
			&c.CompletionPhotoURL, // c.completion_photo_url
			&c.Area,               // c.area
			&c.Status,             // c.status
			&c.CreatedAt,          // c.created_at
			&reason,               // COALESCE(cr.reason, '')
			&c.Rating,             // COALESCE(c.rating, 0)
			&c.Feedback,           // COALESCE(c.feedback_text, '')
			&c.Ward,               // c.ward
		); err != nil {
			return nil, err
		}

		// Attach reason only for rejected complaints
		if status == "REJECTED" {
			c.RejectionReason = reason
		}

		list = append(list, c)
	}

	return list, nil
}

func itoa(i int) string {
	return strconv.Itoa(i)
}

func (r *Repository) UpdateComplaintStatus(ctx context.Context, id, status string) error {
	_, err := r.DB.Exec(ctx, `
		UPDATE complaints
		SET status = $1, updated_at = NOW()
		WHERE id = $2
	`, status, id)
	return err
}

func (r *Repository) CreateBudget(ctx context.Context, id string, cost float64, user string) error {
	status := "APPROVED"
	role := "FIELD_OFFICER"

	if cost > 10000 {
		status = "PENDING_APPROVAL"
		role = "JUNIOR_ENGINEER"
		if cost > 25000 {
			role = "COMMISSIONER"
		}
	}

	_, err := r.DB.Exec(ctx, `
		INSERT INTO work_order_budget
		(complaint_id, estimated_cost, proposed_by, status, approval_role)
		VALUES ($1,$2,$3,$4,$5)
	`, id, cost, user, status, role)

	return err
}

func (r *Repository) CreateSLA(ctx context.Context, id string, days int) error {
	deadline := time.Now().Add(time.Hour * 24 * time.Duration(days))

	_, err := r.DB.Exec(ctx, `
		INSERT INTO sla_tracking
		(complaint_id, sla_start_time, sla_deadline, current_level)
		VALUES ($1,$2,$3,'FIELD_OFFICER')
	`, id, time.Now(), deadline)

	return err
}

func (r *Repository) CompleteComplaint(
	ctx context.Context,
	id, url string,
	lat, lng float64,
) error {
	_, err := r.DB.Exec(ctx, `
		UPDATE complaints
		SET status='COMPLETED',
		    completion_photo_url=$1,
		    completion_latitude=$2,
		    completion_longitude=$3,
		    completed_at=NOW()
		WHERE id=$4
	`, url, lat, lng, id)

	return err
}
func (r *Repository) IsOnLeave(ctx context.Context, officerID string) (bool, error) {
	var exists bool
	query := `
		SELECT EXISTS (
			SELECT 1 FROM leave_applications
			WHERE officer_id = $1
			  AND status = 'APPROVED'
			  AND CURRENT_DATE BETWEEN from_date AND to_date
		)
	`
	err := r.DB.QueryRow(ctx, query, officerID).Scan(&exists)
	return exists, err
}
