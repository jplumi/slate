package main

import (
	"log"
	"net/http"
	"time"
)

func GetTasks(includeDeleted bool) ([]Task, error) {
	query := "SELECT * FROM tasks";
	if !includeDeleted {
		query += " WHERE deleted = 0"
	}

	rows, err := db.Query(query)
	if err != nil {
		return nil, &ApiError{"Failed to get Tasks", http.StatusInternalServerError}
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
			return nil, &ApiError{"Failed to get Tasks", http.StatusInternalServerError}
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

func SaveTask(task Task) error {
	// Get task last update
	var updatedAt int64
	db.QueryRow("SELECT updated_at FROM tasks WHERE ID = ?", task.ID).Scan(&updatedAt)

	if updatedAt != 0 {
		syncedUpdatedAt := time.UnixMilli(updatedAt)
		incomingUpdatedAt := time.UnixMilli(task.UpdatedAt)

		if syncedUpdatedAt.Equal(incomingUpdatedAt) || syncedUpdatedAt.After(incomingUpdatedAt) {
			log.Printf("Tried to sync with older update - id: %v, synced: %v, older: %v", task.ID, syncedUpdatedAt, incomingUpdatedAt)
			return nil
		}
	}

	_, err := db.Exec(`
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

func DeleteTask(task Task) error {
	log.Printf("delete task: %v", task.ID)
	result, err := db.Exec("UPDATE tasks SET deleted=1, updated_at=? WHERE id = ?", task.UpdatedAt, task.ID)
	if err != nil {
		return err
	}

	if rows, _ := result.RowsAffected(); rows < 1 {
		return &ApiError{"id not found", http.StatusNotFound}
	}

	return nil
}

func GetChangesSince(since int64) ([]Task, error) {
	rows, err := db.Query("SELECT * FROM tasks WHERE updated_at >= ?", since)
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
