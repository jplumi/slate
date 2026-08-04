package database

import (
	"database/sql"

	_ "modernc.org/sqlite"
)

func InitDB() (*sql.DB, error) {
	db, err := sql.Open("sqlite", "data/data.db")
	if err != nil {
		return nil, err
	}

	schema := `
		CREATE TABLE IF NOT EXISTS tasks (
			id           TEXT PRIMARY KEY,
			date         TEXT NOT NULL,
			title        TEXT NOT NULL,
			is_completed BOOLEAN NOT NULL DEFAULT 0,
			position     INTEGER NOT NULL,
			updated_at   INTEGER NOT NULL,
			deleted   	 INTEGER NOT NULL DEFAULT 0
		);
		CREATE INDEX IF NOT EXISTS idx_tasks_date ON tasks(date);`
	if _, err := db.Exec(schema); err != nil {
		return nil, err
	}

	return db, nil
}
