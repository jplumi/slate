package middleware

import (
	"log"
	"net/http"
	"os"
	"strings"
)

func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[%v] %v", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
	})
}

func Auth(next http.Handler) http.Handler {
	apiKey := os.Getenv("SLATE_API_KEY")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization")
		token = strings.Replace(token, "Bearer ", "", 1)
		if token == "" {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			log.Print("Unauthorized: token empty")
			return
		}

		if apiKey != token {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			log.Print("Unauthorized: invalid token")
			return
		}

		next.ServeHTTP(w, r)
	})
}
