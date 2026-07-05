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
	CreatedAt   string `json:"createdAt"`
}

func getTasks(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT * FROM tasks")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	tasks := []Task{}
	for rows.Next() {
		task := Task{}
		err := rows.Scan(&task.ID, &task.Date, &task.Title, &task.IsCompleted, &task.Position, &task.CreatedAt)
		if err != nil {
			log.Printf("Error occurred: %v\n", err)
			w.WriteHeader(http.StatusInternalServerError)
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
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	_, err = db.Exec(`INSERT INTO tasks (ID, date, title, is_completed, position, created_at)
		VALUES (?,?,?,?,?,?)`,
		newTask.ID,
		newTask.Date,
		newTask.Title,
		newTask.IsCompleted,
		newTask.Position,
		newTask.CreatedAt,
	)
	if err != nil {
		log.Printf("Failed to execute insert: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
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

	log.Println("Server started.")
	log.Fatal(http.ListenAndServe(":8081", nil))
}
