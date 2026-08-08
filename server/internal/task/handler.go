package task

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
)

type Handler struct {
	store *Store
}

func NewHandler(store *Store) *Handler {
	return &Handler{store}
}

func (h *Handler) GetTasks(w http.ResponseWriter, r *http.Request) {
	includeDeleted := r.URL.Query().Get("deleted")

	tasks, err := h.store.GetTasks(includeDeleted == "true")
	if err != nil {
		handleErr(w, err)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func (h *Handler) SaveTask(w http.ResponseWriter, r *http.Request) {
	task := Task{}
	err := json.NewDecoder(r.Body).Decode(&task)
	defer r.Body.Close()
	if err != nil {
		handleErr(w, err)
		return
	}

	err = h.store.SaveTask(task)
	if err != nil {
		handleErr(w, err)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func (h *Handler) DeleteTask(w http.ResponseWriter, r *http.Request) {
	task := Task{}
	err := json.NewDecoder(r.Body).Decode(&task)
	defer r.Body.Close()
	if err != nil {
		handleErr(w, err)
		return
	}

	err = h.store.DeleteTask(task)
	if err != nil {
		handleErr(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (h *Handler) GetChangesSince(w http.ResponseWriter, r *http.Request) {
	sinceParam := r.URL.Query().Get("since")
	if sinceParam == "" {
		http.Error(w, "Received empty 'since' param", http.StatusBadRequest)
		return
	}

	since, err := strconv.ParseInt(sinceParam, 10, 64)
	if err != nil {
		handleErr(w, err)
		return
	}

	tasks, err := h.store.GetChangesSince(since)
	if err != nil {
		handleErr(w, err)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func handleErr(w http.ResponseWriter, err error) {
	if errors.Is(err, ErrTaskNotFound) {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	http.Error(w, err.Error(), http.StatusInternalServerError)
}
