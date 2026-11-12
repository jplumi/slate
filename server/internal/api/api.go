package api

import (
	"database/sql"
	"log"
	"net/http"

	"jplumi.com.br/slate_service/internal/middleware"
	"jplumi.com.br/slate_service/internal/task"
)

func NewHandler(db *sql.DB) http.Handler {
	taskStore := task.NewStore(db)
	taskHandler := task.NewHandler(taskStore)

	mux := http.NewServeMux()

	mux.HandleFunc("GET /tasks", taskHandler.GetTasks)
	mux.HandleFunc("PUT /tasks", taskHandler.SaveTask)
	mux.HandleFunc("DELETE /tasks", taskHandler.DeleteTask)
	mux.HandleFunc("GET /tasks/changes", taskHandler.GetChangesSince)

	var handler http.Handler = mux
	handler = middleware.Auth(handler)
	handler = middleware.Logger(handler)

	return handler
}

func StartHttpServer(db *sql.DB) {
	handler := NewHandler(db)

	log.Println("Server started.")
	log.Fatal(http.ListenAndServe(":8081", handler))
}
