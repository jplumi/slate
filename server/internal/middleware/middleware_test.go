package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestAuth(t *testing.T) {
	tests := []struct {
		name       string
		apiKey     string
		authHeader string
		wantStatus int
		wantCalled bool
	}{
		{
			name:       "valid bearer token",
			apiKey:     "secret",
			authHeader: "Bearer secret",
			wantStatus: http.StatusOK,
			wantCalled: true,
		},
		{
			name:       "missing header",
			apiKey:     "secret",
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "empty bearer token",
			apiKey:     "secret",
			authHeader: "Bearer ",
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "wrong token",
			apiKey:     "secret",
			authHeader: "Bearer wrong",
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "raw token without bearer prefix",
			apiKey:     "secret",
			authHeader: "secret",
			wantStatus: http.StatusOK,
			wantCalled: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("SLATE_API_KEY", tt.apiKey)

			called := false
			next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				called = true
				w.WriteHeader(http.StatusOK)
			})

			req := httptest.NewRequest(http.MethodGet, "/tasks", nil)
			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}
			rec := httptest.NewRecorder()

			Auth(next).ServeHTTP(rec, req)

			if rec.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d", rec.Code, tt.wantStatus)
			}
			if called != tt.wantCalled {
				t.Errorf("handler called = %v, want %v", called, tt.wantCalled)
			}
		})
	}
}
