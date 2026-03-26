package commissioner

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) GetProfile(ctx context.Context, userID string) (*CommissionerProfile, error) {
	var p CommissionerProfile
	var wardFrom, wardTo *int

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

	return &p, err
}

func (r *Repository) GetDashboardStats(ctx context.Context) (*CommissionerDashboardStats, error) {
	var s CommissionerDashboardStats

	err := r.DB.QueryRow(ctx, `
		SELECT
		  (SELECT COUNT(*) FROM work_order_budget
		   WHERE status='PENDING_APPROVAL'
		     AND approval_role='COMMISSIONER'),
		  (SELECT COUNT(*) FROM escalation_history
		   WHERE to_role='COMMISSIONER'),
		  (SELECT COUNT(*) FROM complaints WHERE status='COMPLETED')
	`).Scan(&s.PendingBudgets, &s.Escalations, &s.Completed)

	return &s, err
}

func (r *Repository) GetPendingBudgets(ctx context.Context) ([]BudgetApprovalItem, error) {
	rows, err := r.DB.Query(ctx, `
		SELECT complaint_id, estimated_cost, status, created_at
		FROM work_order_budget
		WHERE status='PENDING_APPROVAL'
		  AND approval_role='COMMISSIONER'
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []BudgetApprovalItem
	for rows.Next() {
		var i BudgetApprovalItem
		if err := rows.Scan(&i.ComplaintID, &i.EstimatedCost, &i.Status, &i.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, i)
	}
	return list, nil
}

func (r *Repository) ApproveBudget(ctx context.Context, complaintID, userID string) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 1️⃣ Approve budget (only commissioner level)
	_, err = tx.Exec(ctx, `
		UPDATE work_order_budget
		SET status='APPROVED',
		    approved_by=$1,
		    approved_at=NOW()
		WHERE complaint_id=$2
		  AND status='PENDING_APPROVAL'
		  AND approval_role='COMMISSIONER'
	`, userID, complaintID)

	if err != nil {
		return err
	}

	// 2️⃣ Move complaint back to FIELD OFFICER
	_, err = tx.Exec(ctx, `
		UPDATE complaints
		SET status='PENDING',
		    last_modified_role='COMMISSIONER',
		    updated_at=NOW()
		WHERE id=$1
	`, complaintID)

	if err != nil {
		return err
	}

	// 3️⃣ Restart SLA for Commissioner (2 days window)
	_, err = tx.Exec(ctx, `
		UPDATE sla_tracking
		SET current_level='COMMISSIONER',
		    sla_start_time=NOW(),
		    sla_deadline=NOW() + INTERVAL '2 days',
		    is_breached=FALSE,
		    last_checked_at=NOW()
		WHERE complaint_id=$1
	`, complaintID)

	if err != nil {
		return err
	}

	// 4️⃣ Log action
	_, err = tx.Exec(ctx, `
		INSERT INTO work_order_actions
		(complaint_id, action_by, action_type, action_role)
		VALUES ($1, $2, 'BUDGET_APPROVED', 'COMMISSIONER')
	`, complaintID, userID)

	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *Repository) RejectBudget(ctx context.Context, complaintID, userID, reason string) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 1️⃣ Reject budget
	_, err = tx.Exec(ctx, `
		UPDATE work_order_budget
		SET status='REJECTED',
		    approved_by=$1,
		    approved_at=NOW()
		WHERE complaint_id=$2
		  AND status='PENDING_APPROVAL'
		  AND approval_role='COMMISSIONER'
	`, userID, complaintID)

	if err != nil {
		return err
	}

	// 2️⃣ Update complaint
	_, err = tx.Exec(ctx, `
		UPDATE complaints
		SET status='REJECTED',
		    last_modified_role='COMMISSIONER',
		    updated_at=NOW()
		WHERE id=$1
	`, complaintID)

	if err != nil {
		return err
	}

	// 3️⃣ Insert rejection reason
	_, err = tx.Exec(ctx, `
		INSERT INTO complaint_rejections
		(complaint_id, rejected_by, role, reason)
		VALUES ($1, $2, 'COMMISSIONER', $3)
	`, complaintID, userID, reason)

	if err != nil {
		return err
	}

	// 4️⃣ Log action
	_, err = tx.Exec(ctx, `
		INSERT INTO work_order_actions
		(complaint_id, action_by, action_type, action_role)
		VALUES ($1, $2, 'BUDGET_REJECTED', 'COMMISSIONER')
	`, complaintID, userID)

	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *Repository) GetEscalations(ctx context.Context) ([]EscalationItem, error) {
	rows, err := r.DB.Query(ctx, `
		SELECT complaint_id, from_role, escalation_reason, escalated_at
		FROM escalation_history
		WHERE to_role='COMMISSIONER'
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []EscalationItem
	for rows.Next() {
		var e EscalationItem
		if err := rows.Scan(&e.ComplaintID, &e.FromRole, &e.Reason, &e.EscalatedAt); err != nil {
			return nil, err
		}
		list = append(list, e)
	}
	return list, nil
}
func (r *Repository) GetComplaintDetails(ctx context.Context, id string) (*ComplaintDetails, error) {
	var c ComplaintDetails
	var area sql.NullString

	err := r.DB.QueryRow(ctx, `
		SELECT 
			id,
			category,
			severity,
			image_url,
			completion_photo_url,
			area,
			status,
			created_at,
			COALESCE(rating, 0),
			COALESCE(feedback_text, '')
		FROM complaints
		WHERE id=$1
	`, id).Scan(
		&c.ID,
		&c.Category,
		&c.Severity,
		&c.ImageURL,
		&c.CompletionPhotoURL,
		&area,
		&c.Status,
		&c.CreatedAt,
		&c.Rating,
		&c.Feedback,
	)

	if area.Valid {
		c.Area = area.String
	}

	if err != nil {
		return nil, err
	}

	return &c, nil
}
func (r *Repository) GetAllComplaints(ctx context.Context, filter ComplaintFilter) ([]ComplaintDetails, error) {
	query := `
		SELECT 
			c.id,
			c.category,
			c.severity,
			c.image_url,
			c.completion_photo_url,
			c.area,
			c.status,
			c.created_at,
			COALESCE(c.rating, 0),
			COALESCE(c.feedback_text, ''),
			c.ward
		FROM complaints c
		WHERE 1=1
	`
	var args []interface{}
	argIdx := 1

	if filter.Area != "" {
		query += fmt.Sprintf(" AND c.area ILIKE $%d", argIdx)
		args = append(args, "%"+filter.Area+"%")
		argIdx++
	}
	if filter.Severity != "" {
		query += fmt.Sprintf(" AND c.severity = $%d", argIdx)
		args = append(args, filter.Severity)
		argIdx++
	}
	if filter.Category != "" {
		query += fmt.Sprintf(" AND c.category = $%d", argIdx)
		args = append(args, filter.Category)
		argIdx++
	}
	if filter.Ward != "" {
		query += fmt.Sprintf(" AND c.ward = $%d", argIdx)
		args = append(args, filter.Ward)
		argIdx++
	}
	if filter.StartDate != "" {
		query += fmt.Sprintf(" AND c.created_at >= $%d", argIdx)
		args = append(args, filter.StartDate)
		argIdx++
	}
	if filter.EndDate != "" {
		query += fmt.Sprintf(" AND c.created_at < ($%d::date + INTERVAL '1 day')", argIdx)
		args = append(args, filter.EndDate)
		argIdx++
	}

	query += ` ORDER BY c.created_at DESC`

	rows, err := r.DB.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []ComplaintDetails

	for rows.Next() {
		var c ComplaintDetails
		var ward sql.NullString
		var area sql.NullString

		if err := rows.Scan(
			&c.ID,
			&c.Category,
			&c.Severity,
			&c.ImageURL,
			&c.CompletionPhotoURL,
			&area,
			&c.Status,
			&c.CreatedAt,
			&c.Rating,
			&c.Feedback,
			&ward,
		); err != nil {
			return nil, err
		}

		if area.Valid {
			c.Area = area.String
		}

		if ward.Valid {
			c.Ward = ward.String
		}

		list = append(list, c)
	}
	return list, nil
}
