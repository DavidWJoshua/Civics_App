package citizen

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) GetOrCreateCitizen(ctx context.Context, phone string) (string, error) {
	var id string
	err := r.DB.QueryRow(ctx,
		`INSERT INTO users (phone_number, role)
		 VALUES ($1,'CITIZEN')
		 ON CONFLICT (phone_number, role)
		 DO UPDATE SET phone_number=EXCLUDED.phone_number
		 RETURNING id`,
		phone,
	).Scan(&id)

	if err == nil {
		// Log the ID to help debug persistence issues
		log.Printf("DEBUG: GetOrCreateCitizen for %s returning ID: %s", phone, id)
	}

	return id, err
}

func (r *Repository) GetUserByPhoneAndRole(ctx context.Context, phone, role string) (string, error) {
	var id string
	err := r.DB.QueryRow(ctx,
		`SELECT id FROM users WHERE phone_number = $1 AND role = $2`,
		phone, role,
	).Scan(&id)

	return id, err
}
