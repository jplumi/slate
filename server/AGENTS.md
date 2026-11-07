# Slate Server (Go)

Go sync backend for Slate. Go 1.25, module `jplumi.com.br/slate_service`.

## Run / build

```bash
./run.sh                                  # SLATE_API_KEY=rosquinha go run cmd/slate/main.go
SLATE_API_KEY=<key> go run ./cmd/slate    # custom key
./build-image.sh                          # build the Docker image
docker compose up                         # or use docker-compose.yml
```

Listens on `:8081`.

## Layout

- `cmd/slate/main.go` — entrypoint: opens the DB, starts the HTTP server
- `internal/api/api.go` — routes
- `internal/task/` — handler, model, and store (SQLite access)
- `internal/database/database.go` — schema/migrations
- `internal/middleware/` — auth (Bearer API key) and request logging

## Endpoints

| Method | Path                        | Purpose                          |
|--------|-----------------------------|----------------------------------|
| GET    | /tasks                      | list (optional `?deleted=true`)  |
| PUT    | /tasks                      | upsert task                      |
| DELETE | /tasks                      | soft-delete (task JSON body)     |
| GET    | /tasks/changes?since=<ms>   | tasks changed since epoch ms     |

## Storage

SQLite via `modernc.org/sqlite` (pure Go, no CGO). `data/` holds `data.db` and `app.log`; it is gitignored — never commit it.

## Contract

The `Task` JSON shape must match `app/lib/models/task.dart` (see root `AGENTS.md`). Update `app/lib/services/api_client.dart` and `sync_service.dart` whenever you change these routes or fields.
