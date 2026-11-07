package task

import (
	"database/sql"
	"errors"
	"log"
	"time"
)

type Store struct {
	db *sql.DB
}

func NewStore(db *sql.DB) *Store {
	return &Store{db}
}

var ErrTaskNotFound = errors.New("task not found")

func (s *Store) GetTasks(includeDeleted bool) ([]Task, error) {
	query := `SELECT id, date, title, is_completed, position, updated_at, deleted FROM tasks`
	if !includeDeleted {
		query += " WHERE deleted = 0"
	}

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}

	tasks := []Task{}
	for rows.Next() {
		task := Task{}
		err := rows.Scan(
			&task.ID,
			&task.Date,
			&task.Title,
			&task.IsCompleted,
			&task.Position,
			&task.UpdatedAt,
			&task.IsDeleted,
		)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

func (s *Store) SaveTask(task Task) error {
	// Get task last update
	var updatedAt int64
	s.db.QueryRow("SELECT updated_at FROM tasks WHERE ID = ?", task.ID).Scan(&updatedAt)

	if updatedAt != 0 {
		syncedUpdatedAt := time.UnixMilli(updatedAt)
		incomingUpdatedAt := time.UnixMilli(task.UpdatedAt)

		if syncedUpdatedAt.Equal(incomingUpdatedAt) || syncedUpdatedAt.After(incomingUpdatedAt) {
			log.Printf("CONFLICT: Tried to sync with older update - id: %v, synced: %v, older: %v", task.ID, syncedUpdatedAt, incomingUpdatedAt)
			return nil
		}
	}

	_, err := s.db.Exec(`
		INSERT INTO tasks (ID, date, title, is_completed, position, updated_at)
		VALUES (?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE 
		SET date=EXCLUDED.date,
			title=EXCLUDED.title,
			is_completed=EXCLUDED.is_completed,
			position=EXCLUDED.position,
			updated_at=EXCLUDED.updated_at
		`,
		task.ID,
		task.Date,
		task.Title,
		task.IsCompleted,
		task.Position,
		task.UpdatedAt,
	)

	return err
}

func (s *Store) DeleteTask(task Task) error {
	result, err := s.db.Exec("UPDATE tasks SET deleted=1, updated_at=? WHERE id = ?", task.UpdatedAt, task.ID)
	if err != nil {
		return err
	}

	if rows, _ := result.RowsAffected(); rows < 1 {
		return ErrTaskNotFound
	}

	return nil
}

func (s *Store) GetChangesSince(since int64) ([]Task, error) {
	query := `SELECT id, date, title, is_completed, position, updated_at, deleted
		FROM tasks
		WHERE updated_at >= ?`

	rows, err := s.db.Query(query, since)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	tasks := []Task{}
	for rows.Next() {
		task := Task{}
		err := rows.Scan(
			&task.ID,
			&task.Date,
			&task.Title,
			&task.IsCompleted,
			&task.Position,
			&task.UpdatedAt,
			&task.IsDeleted,
		)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}
