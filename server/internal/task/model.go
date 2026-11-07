package task

type Task struct {
	ID          string `json:"id"`
	Date        string `json:"date"`
	Title       string `json:"title"`
	IsCompleted bool   `json:"isCompleted"`
	Position    int    `json:"sortOrder"`
	UpdatedAt   int64  `json:"updatedAt"`
	IsDeleted   bool   `json:"isDeleted"`
}
