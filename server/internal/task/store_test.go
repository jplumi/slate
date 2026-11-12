package task

import (
	"database/sql"
	"slices"
	"testing"

	_ "modernc.org/sqlite"
)

const testSchema = `
CREATE TABLE IF NOT EXISTS tasks (
	id           TEXT PRIMARY KEY,
	date         TEXT NOT NULL,
	title        TEXT NOT NULL,
	is_completed BOOLEAN NOT NULL DEFAULT 0,
	position     INTEGER NOT NULL,
	updated_at   INTEGER NOT NULL,
	deleted   	 INTEGER NOT NULL DEFAULT 0
);`

func newTestStore(t *testing.T) (*Store, *sql.DB) {
	t.Helper()

	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	db.SetMaxOpenConns(1)
	t.Cleanup(func() { db.Close() })

	if _, err := db.Exec(testSchema); err != nil {
		t.Fatalf("create schema: %v", err)
	}

	return NewStore(db), db
}

func readTask(t *testing.T, db *sql.DB, id string) Task {
	t.Helper()

	var task Task
	err := db.QueryRow(`SELECT id, date, title, is_completed, position, updated_at, deleted FROM tasks WHERE id = ?`, id).
		Scan(&task.ID, &task.Date, &task.Title, &task.IsCompleted, &task.Position, &task.UpdatedAt, &task.IsDeleted)
	if err != nil {
		t.Fatalf("query task %q: %v", id, err)
	}
	return task
}

func TestSaveTask_Insert(t *testing.T) {
	store, db := newTestStore(t)

	want := Task{
		ID:          "1",
		Date:        "2024-01-01",
		Title:       "Buy milk",
		IsCompleted: false,
		Position:    0,
		UpdatedAt:   1000,
	}

	if err := store.SaveTask(want); err != nil {
		t.Fatalf("SaveTask() error = %v", err)
	}

	if got := readTask(t, db, want.ID); got != want {
		t.Errorf("stored task = %+v, want %+v", got, want)
	}
}

func TestSaveTask_UpdatesNewer(t *testing.T) {
	store, db := newTestStore(t)

	original := Task{ID: "1", Date: "2024-01-01", Title: "Buy milk", UpdatedAt: 1000}
	if err := store.SaveTask(original); err != nil {
		t.Fatalf("seed SaveTask() error = %v", err)
	}

	want := Task{
		ID:          "1",
		Date:        "2024-01-02",
		Title:       "Buy oat milk",
		IsCompleted: true,
		Position:    3,
		UpdatedAt:   2000,
	}
	if err := store.SaveTask(want); err != nil {
		t.Fatalf("SaveTask() error = %v", err)
	}

	if got := readTask(t, db, want.ID); got != want {
		t.Errorf("stored task = %+v, want %+v", got, want)
	}
}

func TestSaveTask_RejectsStaleUpdate(t *testing.T) {
	store, db := newTestStore(t)

	original := Task{ID: "1", Date: "2024-01-01", Title: "Buy milk", Position: 0, UpdatedAt: 1000}
	if err := store.SaveTask(original); err != nil {
		t.Fatalf("seed SaveTask() error = %v", err)
	}

	tests := []struct {
		name     string
		incoming Task
	}{
		{"equal timestamp", Task{ID: "1", Date: "2024-01-02", Title: "stale", Position: 9, UpdatedAt: 1000}},
		{"older timestamp", Task{ID: "1", Date: "2024-01-02", Title: "stale", Position: 9, UpdatedAt: 999}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := store.SaveTask(tt.incoming); err != nil {
				t.Fatalf("SaveTask() error = %v", err)
			}

			if got := readTask(t, db, "1"); got != original {
				t.Errorf("stored task = %+v, want unchanged %+v", got, original)
			}
		})
	}
}

func TestGetChangesSince(t *testing.T) {
	store, _ := newTestStore(t)

	seeded := []Task{
		{ID: "1", Date: "2024-01-01", Title: "a", UpdatedAt: 100},
		{ID: "2", Date: "2024-01-01", Title: "b", UpdatedAt: 200},
		{ID: "3", Date: "2024-01-01", Title: "c", UpdatedAt: 300},
	}
	for _, task := range seeded {
		if err := store.SaveTask(task); err != nil {
			t.Fatalf("seed SaveTask() error = %v", err)
		}
	}

	tests := []struct {
		name  string
		since int64
		want  []string
	}{
		{"includes boundary", 200, []string{"2", "3"}},
		{"only newest", 300, []string{"3"}},
		{"none", 301, nil},
		{"all", 0, []string{"1", "2", "3"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := store.GetChangesSince(tt.since)
			if err != nil {
				t.Fatalf("GetChangesSince() error = %v", err)
			}

			gotIDs := make([]string, 0, len(got))
			for _, task := range got {
				gotIDs = append(gotIDs, task.ID)
			}
			want := slices.Clone(tt.want)
			slices.Sort(gotIDs)
			slices.Sort(want)
			if !slices.Equal(gotIDs, want) {
				t.Errorf("GetChangesSince() ids = %v, want %v", gotIDs, want)
			}
		})
	}
}

func TestGetChangesSince_IncludesDeleted(t *testing.T) {
	store, _ := newTestStore(t)

	store.SaveTask(Task{ID: "1", Date: "2024-01-01", Title: "a", UpdatedAt: 100})
	store.SaveTask(Task{ID: "2", Date: "2024-01-01", Title: "b", UpdatedAt: 200})

	if err := store.DeleteTask(Task{ID: "2", UpdatedAt: 250}); err != nil {
		t.Fatalf("DeleteTask() error = %v", err)
	}

	got, err := store.GetChangesSince(200)
	if err != nil {
		t.Fatalf("GetChangesSince() error = %v", err)
	}

	if len(got) != 1 {
		t.Fatalf("GetChangesSince() returned %d tasks, want 1", len(got))
	}
	if got[0].ID != "2" || !got[0].IsDeleted {
		t.Errorf("GetChangesSince() = %+v, want deleted task 2", got[0])
	}
}
