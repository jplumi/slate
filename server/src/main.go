package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"

	"jplumi.com.br/slate_service/src/database"
	"jplumi.com.br/slate_service/src/middleware"
)

var db *sql.DB

type Task struct {
	ID          string `json:"id"`
	Date        string `json:"date"`
	Title       string `json:"title"`
	IsCompleted bool   `json:"isCompleted"`
	Position    int    `json:"sortOrder"`
	UpdatedAt   int64  `json:"updatedAt"`
	IsDeleted   bool   `json:"isDeleted"`
}

func getTasks(w http.ResponseWriter, r *http.Request) {
	includeDeleted := r.URL.Query().Get("deleted")

	tasks, err := GetTasks(includeDeleted == "true")
	if err != nil {
		apiError(w, err)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func saveTask(w http.ResponseWriter, r *http.Request) {
	task := Task{}
	err := json.NewDecoder(r.Body).Decode(&task)
	defer r.Body.Close()
	if err != nil {
		apiError(w, err)
		return
	}

	err = SaveTask(task)
	if err != nil {
		apiError(w, err)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func deleteTask(w http.ResponseWriter, r *http.Request) {
	task := Task{}
	err := json.NewDecoder(r.Body).Decode(&task)
	defer r.Body.Close()
	if err != nil {
		apiError(w, err)
		return
	}

	err = DeleteTask(task)
	if err != nil {
		apiError(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func getChangesSince(w http.ResponseWriter, r *http.Request) {
	sinceParam := r.URL.Query().Get("since")
	if sinceParam == "" {
		apiError(w, &ApiError{"Received empty 'since' param", http.StatusBadRequest})
		return
	}

	since, err := strconv.ParseInt(sinceParam, 10, 64)
	if err != nil {
		apiError(w, err)
		return
	}

	tasks, err := GetChangesSince(since)
	if err != nil {
		apiError(w, err)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func apiError(w http.ResponseWriter, err error) {
	var apiErr *ApiError

	if errors.As(err, &apiErr) {
		msg := fmt.Sprintf("Error %v: %v\n", apiErr.Status, apiErr.Msg)
		log.Print(msg)
		http.Error(w, msg, apiErr.Status)
		return
	}

	log.Printf("Error %v: %v\n", http.StatusInternalServerError, err.Error())
	http.Error(w, err.Error(), http.StatusInternalServerError)
}

func main() {
	// Log file
	var err error
	file, err := os.OpenFile("data/app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("Failed to open log file: %v", err)
	}
	defer file.Close()
	file.Write([]byte("\n\n"))
	log.SetOutput(io.MultiWriter(os.Stdout, file))

	// Database
	db, err = database.InitDB()
	if err != nil {
		log.Fatalf("Failed to init database: %v", err)
	}
	defer db.Close()

	// Handlers
	mux := http.NewServeMux()

	mux.HandleFunc("GET /tasks", getTasks)
	mux.HandleFunc("PUT /tasks", saveTask)
	mux.HandleFunc("DELETE /tasks", deleteTask)
	mux.HandleFunc("GET /tasks/changes", getChangesSince)

	var handler http.Handler = mux
	handler = middleware.Auth(handler)
	handler = middleware.Logger(handler)

	log.Println("Server started.")
	log.Fatal(http.ListenAndServe(":8081", handler))
}

