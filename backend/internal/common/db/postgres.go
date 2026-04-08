package db

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DBConfig struct {
	Host string
	Port string
	Name string
	User string
	Pass string
}

func Connect(ctx context.Context, cfg DBConfig) (*pgxpool.Pool, error) {
	sslMode := "disable"
	// If connecting to a remote host (like AWS RDS), default to sslmode=require
	if cfg.Host != "localhost" && cfg.Host != "127.0.0.1" && cfg.Host != "" {
		sslMode = "require"
	}

	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		cfg.User,
		cfg.Pass,
		cfg.Host,
		cfg.Port,
		cfg.Name,
		sslMode,
	)

	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, err
	}

	poolConfig.MaxConns = 10
	poolConfig.MinConns = 2
	poolConfig.MaxConnLifetime = time.Hour

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return pgxpool.NewWithConfig(ctx, poolConfig)
}
