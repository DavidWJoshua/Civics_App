package complaint

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) CreateComplaintWithAssignmentTx(
	ctx context.Context,
	citizenID string,
	req CreateComplaintRequest,
) (string, error) {

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx)

	locationJSON, _ := json.Marshal(req.Location)

	// Generate ID: MM-DD-YYYY-XXXXXX
	now := time.Now()
	complaintID := fmt.Sprintf("%02d-%02d-%04d-%06d", now.Month(), now.Day(), now.Year(), rand.Intn(1000000))

	// 1️⃣ Insert Complaint
	_, err = tx.Exec(ctx,
		`INSERT INTO complaints
		(id, citizen_id, category, severity, latitude, longitude, street, area, ward, city, location_json, image_url)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
		complaintID,
		citizenID,
		req.Category,
		req.Severity,
		req.Latitude,
		req.Longitude,
		req.Street,
		req.Area,
		req.Ward,
		req.City,
		locationJSON,
		req.ImageURL,
	)

	if err != nil {
		return "", err
	}

	// 2️⃣ Ward + Leave Aware Officer Selection
	var officerID string
	err = tx.QueryRow(ctx,
		`SELECT op.user_id
		 FROM officer_profiles op
		 WHERE op.ward_from <= $1
		   AND op.ward_to >= $1
		   AND op.is_active = TRUE
		   AND NOT EXISTS (
		       SELECT 1 FROM leave_applications ol
		       WHERE ol.officer_id = op.user_id
		         AND ol.status = 'APPROVED'
		         AND CURRENT_DATE BETWEEN ol.from_date AND ol.to_date
		   )
		 LIMIT 1`,
		req.Ward,
	).Scan(&officerID)

	// If no officer available → keep as RAISED
	if err != nil {
		tx.Commit(ctx)
		return complaintID, nil
	}

	// 3️⃣ Insert Assignment
	_, err = tx.Exec(ctx,
		`INSERT INTO work_order_assignments
		 (complaint_id, officer_id, assigned_role, is_active, created_at)
		 VALUES ($1,$2,'FIELD_OFFICER',TRUE,NOW())`,
		complaintID,
		officerID,
	)
	if err != nil {
		return "", err
	}

	// 4️⃣ Update Status
	_, err = tx.Exec(ctx,
		`UPDATE complaints
		 SET status='ALLOCATED', updated_at=NOW()
		 WHERE id=$1`,
		complaintID,
	)
	if err != nil {
		return "", err
	}

	return complaintID, tx.Commit(ctx)
}
func (r *Repository) GetComplaintsByCitizen(ctx context.Context, citizenID string) ([]Complaint, error) {

	rows, err := r.DB.Query(ctx,
		`SELECT id, category, severity,
		        COALESCE(latitude, 0),
		        COALESCE(longitude, 0),
		        COALESCE(street, ''),
		        COALESCE(area, ''),
		        COALESCE(ward, 0),
		        COALESCE(city, ''),
		        status,
		        created_at,
		        COALESCE(image_url, ''),
		        COALESCE(completion_photo_url, ''),
		        COALESCE(location_json, '{}'::jsonb),
		        COALESCE(rating, 0),
		        COALESCE(feedback_text, '')
		 FROM complaints
		 WHERE citizen_id=$1
		 ORDER BY created_at DESC`,
		citizenID)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var complaints []Complaint
	for rows.Next() {
		var c Complaint
		var locationJSON []byte

		err := rows.Scan(
			&c.ID,
			&c.Category,
			&c.Severity,
			&c.Latitude,
			&c.Longitude,
			&c.Street,
			&c.Area,
			&c.Ward,
			&c.City,
			&c.Status,
			&c.CreatedAt,
			&c.ImageURL,
			&c.CompletionImageURL,
			&locationJSON,
			&c.Rating,
			&c.FeedbackText,
		)
		if err != nil {
			return nil, err
		}

		_ = json.Unmarshal(locationJSON, &c.Location)
		complaints = append(complaints, c)
	}

	return complaints, nil
}

func (r *Repository) UpdateFeedback(
	ctx context.Context,
	citizenID,
	complaintID string,
	rating int,
	feedback string,
) error {

	_, err := r.DB.Exec(ctx,
		`UPDATE complaints
		 SET rating = $1,
		     feedback_text = $2
		 WHERE id = $3
		   AND citizen_id = $4
		   AND status = 'COMPLETED'`,
		rating,
		feedback,
		complaintID,
		citizenID,
	)

	return err
}
