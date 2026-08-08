package middleware

import (
	"log"
	"net/http"
	"os"
	"strings"
)

type customResponseWriter struct {
	http.ResponseWriter
	status int
	body   []byte
}

func (r *customResponseWriter) WriteHeader(statusCode int) {
	r.status = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}
func (r *customResponseWriter) Write(body []byte) (int, error) {
	r.body = body
	return r.ResponseWriter.Write(body)
}

func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		response := customResponseWriter{w, 200, nil}
		next.ServeHTTP(&response, r)

		if response.status >= 400 {
			log.Printf("[%v] | %v %v - ERROR: %v", response.status, r.Method, r.URL.Path, string(response.body))
			return
		}

		// log.Printf("[%v] | %v %v", response.status, r.Method, r.URL.Path)
	})
}

func Auth(next http.Handler) http.Handler {
	apiKey := os.Getenv("SLATE_API_KEY")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization")
		token = strings.Replace(token, "Bearer ", "", 1)
		if token == "" {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		if apiKey != token {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r)
	})
}
