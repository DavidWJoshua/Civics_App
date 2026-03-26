package junior_engineer

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

// --------------------------------------------------
// 👤 PROFILE
// --------------------------------------------------

func (r *Repository) GetProfile(ctx context.Context, userID string) (*JEProfile, error) {
	var p JEProfile

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

// --------------------------------------------------
// 📊 DASHBOARD
// --------------------------------------------------

func (r *Repository) GetDashboardStats(ctx context.Context) (*JEDashboardStats, error) {
	var s JEDashboardStats

	err := r.DB.QueryRow(ctx, `
		SELECT
		  (SELECT COUNT(*) FROM work_order_budget 
		   WHERE status='PENDING_APPROVAL' 
		   AND approval_role='JUNIOR_ENGINEER'),

		  (SELECT COUNT(*) FROM escalation_history 
		   WHERE to_role='JUNIOR_ENGINEER'),

		  (SELECT COUNT(*) FROM complaints 
		   WHERE status='COMPLETED'),

		  (SELECT COUNT(*) FROM complaints 
		   WHERE status='REJECTED')
	`).Scan(
		&s.PendingBudgets,
		&s.Escalations,
		&s.Completed,
		&s.Rejected,
	)

	return &s, err
}

// --------------------------------------------------
// 💰 PENDING BUDGETS
// --------------------------------------------------

func (r *Repository) GetPendingBudgets(ctx context.Context) ([]BudgetApprovalItem, error) {
	rows, err := r.DB.Query(ctx, `
		SELECT complaint_id, estimated_cost, status, created_at
		FROM work_order_budget
		WHERE status='PENDING_APPROVAL'
		  AND approval_role='JUNIOR_ENGINEER'
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []BudgetApprovalItem

	for rows.Next() {
		var item BudgetApprovalItem
		if err := rows.Scan(
			&item.ComplaintID,
			&item.EstimatedCost,
			&item.Status,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}
		list = append(list, item)
	}

	return list, nil
}

// --------------------------------------------------
// ✅ APPROVE BUDGET
// --------------------------------------------------

func (r *Repository) ApproveBudget(ctx context.Context, complaintID, userID string) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx failed: %v", err)
	}
	defer tx.Rollback(ctx)

	// 1️⃣ Approve budget (only if pending JE approval)
	_, err = tx.Exec(ctx, `
		UPDATE work_order_budget
		SET status='APPROVED',
		    approved_by=$1,
		    approved_at=NOW()
		WHERE complaint_id=$2
		  AND status='PENDING_APPROVAL'
		  AND approval_role='JUNIOR_ENGINEER'
	`, userID, complaintID)

	if err != nil {
		return fmt.Errorf("budget approve failed: %v", err)
	}

	// 2️⃣ Move complaint back to Field Officer
	_, err = tx.Exec(ctx, `
		UPDATE complaints
		SET status='PENDING',
		    last_modified_role='JUNIOR_ENGINEER',
		    updated_at=NOW()
		WHERE id=$1
	`, complaintID)

	if err != nil {
		return fmt.Errorf("complaint update failed: %v", err)
	}

	// 3️⃣ Restart SLA for JE level (2 days window)
	_, err = tx.Exec(ctx, `
		UPDATE sla_tracking
		SET current_level='JUNIOR_ENGINEER',
		    sla_start_time=NOW(),
		    sla_deadline=NOW() + INTERVAL '2 days',
		    is_breached=FALSE,
		    last_checked_at=NOW()
		WHERE complaint_id=$1
	`, complaintID)

	if err != nil {
		return fmt.Errorf("sla update failed: %v", err)
	}

	// 4️⃣ Log action
	_, err = tx.Exec(ctx, `
		INSERT INTO work_order_actions
		(complaint_id, action_by, action_type, action_role)
		VALUES ($1, $2, 'BUDGET_APPROVED', 'JUNIOR_ENGINEER')
	`, complaintID, userID)

	if err != nil {
		return fmt.Errorf("action log failed: %v", err)
	}

	return tx.Commit(ctx)
}

// --------------------------------------------------
// ❌ REJECT BUDGET
// --------------------------------------------------

func (r *Repository) RejectBudget(ctx context.Context, complaintID, userID, reason string) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx failed: %v", err)
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
		  AND approval_role='JUNIOR_ENGINEER'
	`, userID, complaintID)

	if err != nil {
		return fmt.Errorf("budget reject failed: %v", err)
	}

	// 2️⃣ Update complaint to REJECTED
	_, err = tx.Exec(ctx, `
		UPDATE complaints
		SET status='REJECTED',
		    last_modified_role='JUNIOR_ENGINEER',
		    updated_at=NOW()
		WHERE id=$1
	`, complaintID)

	if err != nil {
		return fmt.Errorf("complaint update failed: %v", err)
	}

	// 3️⃣ Store rejection reason
	_, err = tx.Exec(ctx, `
		INSERT INTO complaint_rejections
		(complaint_id, rejected_by, role, reason)
		VALUES ($1, $2, 'JUNIOR_ENGINEER', $3)
	`, complaintID, userID, reason)

	if err != nil {
		return fmt.Errorf("rejection insert failed: %v", err)
	}

	// 4️⃣ Log action
	_, err = tx.Exec(ctx, `
		INSERT INTO work_order_actions
		(complaint_id, action_by, action_type, action_role)
		VALUES ($1, $2, 'BUDGET_REJECTED', 'JUNIOR_ENGINEER')
	`, complaintID, userID)

	if err != nil {
		return fmt.Errorf("action log failed: %v", err)
	}

	return tx.Commit(ctx)
}

// --------------------------------------------------
// ⏱ SLA ESCALATIONS
// --------------------------------------------------

func (r *Repository) GetEscalations(ctx context.Context) ([]EscalationItem, error) {
	rows, err := r.DB.Query(ctx, `
		SELECT complaint_id, from_role, escalation_reason, escalated_at
		FROM escalation_history
		WHERE to_role='JUNIOR_ENGINEER'
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []EscalationItem

	for rows.Next() {
		var item EscalationItem
		if err := rows.Scan(
			&item.ComplaintID,
			&item.FromRole,
			&item.Reason,
			&item.EscalatedAt,
		); err != nil {
			return nil, err
		}
		list = append(list, item)
	}

	return list, nil
}
func (r *Repository) GetAllComplaints(ctx context.Context, filter ComplaintFilter) ([]JEComplaint, error) {
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
			COALESCE(cr.reason, ''),
			COALESCE(c.rating, 0),
			COALESCE(c.feedback_text, ''),
			c.ward
		FROM complaints c
		LEFT JOIN complaint_rejections cr 
			ON c.id = cr.complaint_id
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
		// EndDate + 1 day to include the whole day
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

	var list []JEComplaint

	for rows.Next() {
		var item JEComplaint

		var photo sql.NullString
		var completion sql.NullString
		var area sql.NullString
		var ward sql.NullString

		if err := rows.Scan(
			&item.ID,
			&item.Category,
			&item.Severity,
			&photo,
			&completion,
			&area,
			&item.Status,
			&item.CreatedAt,
			&item.RejectionReason,
			&item.Rating,
			&item.Feedback,
			&ward,
		); err != nil {
			return nil, err
		}

		if photo.Valid {
			item.PhotoURL = &photo.String
		}
		if completion.Valid {
			item.CompletionPhoto = &completion.String
		}

		if area.Valid {
			item.Area = area.String
		}
		if ward.Valid {
			item.Ward = ward.String
		}

		list = append(list, item)
	}

	return list, nil
}

func (r *Repository) EscalateBreachedComplaints(ctx context.Context) error {

	// -------------------------------
	// 1️⃣ FIELD OFFICER → JE
	// -------------------------------
	_, err := r.DB.Exec(ctx, `
		WITH fo_breached AS (
			SELECT complaint_id
			FROM sla_tracking
			WHERE sla_deadline < NOW()
			  AND current_level = 'FIELD_OFFICER'
		)
		INSERT INTO escalation_history 
		(complaint_id, from_role, to_role, escalation_reason, escalated_at)
		SELECT complaint_id, 'FIELD_OFFICER', 'JUNIOR_ENGINEER', 'SLA Breached', NOW()
		FROM fo_breached;
	`)
	if err != nil {
		return err
	}

	_, err = r.DB.Exec(ctx, `
		UPDATE sla_tracking
		SET current_level = 'JUNIOR_ENGINEER',
		    sla_start_time = NOW(),
		    sla_deadline = NOW() + INTERVAL '2 days',
		    is_breached = FALSE
		WHERE sla_deadline < NOW()
		  AND current_level = 'FIELD_OFFICER';
	`)
	if err != nil {
		return err
	}

	// -------------------------------
	// 2️⃣ JE → COMMISSIONER
	// -------------------------------
	_, err = r.DB.Exec(ctx, `
		WITH je_breached AS (
			SELECT complaint_id
			FROM sla_tracking
			WHERE sla_deadline < NOW()
			  AND current_level = 'JUNIOR_ENGINEER'
		)
		INSERT INTO escalation_history 
		(complaint_id, from_role, to_role, escalation_reason, escalated_at)
		SELECT complaint_id, 'JUNIOR_ENGINEER', 'COMMISSIONER', 'SLA Breached', NOW()
		FROM je_breached;
	`)
	if err != nil {
		return err
	}

	_, err = r.DB.Exec(ctx, `
		UPDATE sla_tracking
		SET current_level = 'COMMISSIONER',
		    sla_start_time = NOW(),
		    sla_deadline = NOW() + INTERVAL '2 days',
		    is_breached = FALSE
		WHERE sla_deadline < NOW()
		  AND current_level = 'JUNIOR_ENGINEER';
	`)
	if err != nil {
		return err
	}

	return nil
}

// --------------------------------------------------
// 🔄 COMPLAINT REASSIGNMENT
// --------------------------------------------------

func (r *Repository) GetComplaintsForReassignment(ctx context.Context, jeUserID string) ([]JEComplaint, error) {
	// First get JE's wards
	profile, err := r.GetProfile(ctx, jeUserID)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT 
			c.id, c.category, c.severity, c.image_url, c.completion_photo_url, 
			c.area, c.status, c.created_at, c.ward
		FROM complaints c
		JOIN work_order_assignments ca ON c.id::uuid = ca.complaint_id::uuid
		JOIN leave_applications la ON ca.officer_id::text = la.officer_id::text
		WHERE c.ward::int >= $1 AND c.ward::int <= $2
		  AND c.status = 'ALLOCATED'
		  AND ca.is_active = TRUE
		  AND la.status = 'APPROVED'
		  AND CURRENT_DATE >= la.from_date 
		  AND CURRENT_DATE <= la.to_date
		ORDER BY c.created_at DESC
	`
	rows, err := r.DB.Query(ctx, query, profile.WardFrom, profile.WardTo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []JEComplaint
	for rows.Next() {
		var item JEComplaint
		var photo, completion, area, ward sql.NullString

		if err := rows.Scan(
			&item.ID, &item.Category, &item.Severity, &photo, &completion,
			&area, &item.Status, &item.CreatedAt, &ward,
		); err != nil {
			return nil, err
		}

		if photo.Valid {
			item.PhotoURL = &photo.String
		}
		if completion.Valid {
			item.CompletionPhoto = &completion.String
		}
		if area.Valid {
			item.Area = area.String
		}
		if ward.Valid {
			item.Ward = ward.String
		}

		list = append(list, item)
	}

	return list, nil
}

func (r *Repository) GetFieldOfficersStatus(ctx context.Context, jeUserID string) ([]FieldOfficerStatus, error) {

	query := `
		SELECT 
			o.user_id, o.name, o.ward_from, o.ward_to, o.is_active,
			CASE WHEN la.id IS NOT NULL THEN TRUE ELSE FALSE END AS is_on_leave
		FROM officer_profiles o
		LEFT JOIN users u ON o.phone_number = u.phone_number
		LEFT JOIN leave_applications la ON o.user_id::text = la.officer_id::text 
			AND la.status = 'APPROVED' 
			AND CURRENT_DATE >= la.from_date 
			AND CURRENT_DATE <= la.to_date
		WHERE u.role = 'FIELD_OFFICER'
	`

	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []FieldOfficerStatus
	for rows.Next() {
		var item FieldOfficerStatus
		if err := rows.Scan(
			&item.UserID, &item.Name, &item.WardFrom, &item.WardTo,
			&item.IsActive, &item.IsOnLeave,
		); err != nil {
			return nil, err
		}
		list = append(list, item)
	}

	return list, nil
}

func (r *Repository) ReassignComplaint(ctx context.Context, complaintID string, newOfficerID string, jeUserID string) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Mark previous assignments as inactive
	_, err = tx.Exec(ctx, `
		UPDATE work_order_assignments 
		SET is_active = FALSE 
		WHERE complaint_id = $1 AND is_active = TRUE
	`, complaintID)
	if err != nil {
		return err
	}

	// Insert new assignment
	_, err = tx.Exec(ctx, `
		INSERT INTO work_order_assignments (complaint_id, officer_id, assigned_role, is_active)
		VALUES ($1, $2, 'FIELD_OFFICER', TRUE)
	`, complaintID, newOfficerID)
	if err != nil {
		return err
	}

	// Create action log
	_, err = tx.Exec(ctx, `
		INSERT INTO work_order_actions (complaint_id, action_by, action_type, action_role)
		VALUES ($1, $2, 'COMPLAINT_REASSIGNED', 'JUNIOR_ENGINEER')
	`, complaintID, jeUserID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}
