package main

import (
	"io"
	"log"
	"os"
	_ "time/tzdata"

	"jplumi.com.br/slate_service/internal/api"
	"jplumi.com.br/slate_service/internal/database"
)

func main() {
	if os.Getenv("SLATE_API_KEY") == "" {
		log.Fatalf("SLATE_API_KEY is not set")
	}

	// Setup log file
	file, err := os.OpenFile("data/app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("Failed to open log file: %v", err)
	}
	defer file.Close()
	file.Write([]byte("\n\n"))
	log.SetOutput(io.MultiWriter(os.Stdout, file))

	// Setup databse
	db, err := database.InitDB()
	if err != nil {
		log.Fatalf("Failed to init database: %v", err)
	}
	defer db.Close()

	api.StartHttpServer(db)
}
