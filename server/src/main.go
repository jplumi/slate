package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"

	"jplumi.com.br/slate_service/src/database"
)

var db *sql.DB

type Task struct {
	ID          string `json:"id"`
	Date        string `json:"date"`
	Title       string `json:"title"`
	IsCompleted bool   `json:"isCompleted"`
	Position    int    `json:"position"`
	UpdatedAt   string `json:"updated_at"`
}

func getTasks(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT * FROM tasks")
	if err != nil {
		apiError(w, err, "Failed to get tasks", http.StatusInternalServerError)
		return
	}

	tasks := []Task{}
	for rows.Next() {
		task := Task{}
		err := rows.Scan(&task.ID, &task.Date, &task.Title, &task.IsCompleted, &task.Position, &task.UpdatedAt)
		if err != nil {
			apiError(w, err, "Failed to get tasks", http.StatusInternalServerError)
			return
		}
		tasks = append(tasks, task)
	}

	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func saveTask(w http.ResponseWriter, r *http.Request) {
	newTask := Task{}
	err := json.NewDecoder(r.Body).Decode(&newTask)
	defer r.Body.Close()
	if err != nil {
		apiError(w, err, "Failed to save task", http.StatusInternalServerError)
		return
	}

	_, err = db.Exec(`
		INSERT INTO tasks (ID, date, title, is_completed, position, updated_at)
		VALUES (?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE 
		SET date=EXCLUDED.date,
			title=EXCLUDED.title,
			is_completed=EXCLUDED.is_completed,
			position=EXCLUDED.position,
			updated_at=EXCLUDED.updated_at
		`,
		newTask.ID,
		newTask.Date,
		newTask.Title,
		newTask.IsCompleted,
		newTask.Position,
		newTask.UpdatedAt,
	)
	if err != nil {
		apiError(w, err, "Failed to execute insert", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func deleteTask(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		http.Error(w, "Id is empy.", http.StatusBadRequest)
		return
	}

	result, err := db.Exec("DELETE FROM tasks WHERE id = ?", id)
	if err != nil {
		log.Printf("Faild to delete %v: %v\n", id, err)
		http.Error(w, "Faild to delete.", http.StatusInternalServerError)
		return
	}
	if rows, _ := result.RowsAffected(); rows < 1 {
		http.Error(w, "Id not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func getChangesSince(w http.ResponseWriter, r *http.Request) {
	since := r.URL.Query().Get("since")
	if since == "" {
		http.Error(w, "'since' parameter is empty", http.StatusBadRequest)
		return
	}

	rows, err := db.Query("SELECT * FROM tasks WHERE date > ?", since)
	if err != nil {
		apiError(w, err, "Failed to execute query", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	tasks := []Task{}
	for rows.Next() {
		task := Task{}
		err := rows.Scan(&task.ID, &task.Date, &task.Title, &task.IsCompleted, &task.Position, &task.UpdatedAt)
		if err != nil {
			apiError(w, err, "Failed to get tasks", http.StatusInternalServerError)
			return
		}
		tasks = append(tasks, task)
	}

	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func apiError(w http.ResponseWriter, err error, msg string, status int) {
	log.Printf("Error %v | %v: %v\n", status, msg, err.Error())
	http.Error(w, msg, status)
}

func main() {
	var err error
	db, err = database.InitDB()
	if err != nil {
		log.Fatalf("Failed to init database: %v", err)
	}
	defer db.Close()

	http.HandleFunc("GET /tasks", getTasks)
	http.HandleFunc("POST /tasks", saveTask)
	http.HandleFunc("DELETE /tasks/{id}", deleteTask)
	http.HandleFunc("GET /tasks/changes", getChangesSince)

	log.Println("Server started.")
	log.Fatal(http.ListenAndServe(":8081", nil))
}
