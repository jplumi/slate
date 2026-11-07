# Slate — Monorepo

Personal daily task scheduler. Two components:

- `app/` — Flutter client. Offline-first: SQLite local storage, syncs to the backend when online.
- `server/` — Go sync backend. HTTP API over SQLite.

Component-specific instructions live in `app/AGENTS.md` and `server/AGENTS.md`.

## Cross-cutting rules

**Keep the sync contract in sync.** The app and server exchange `Task` JSON. If you change an endpoint, field, or sync behavior on one side, update the other:

- Server routes: `server/internal/api/api.go`
- App HTTP client: `app/lib/services/api_client.dart`
- App sync logic: `app/lib/services/sync_service.dart`
- Shared shape: `server/internal/task/model.go` ↔ `app/lib/models/task.dart`

### Task JSON

| field       | type   | notes                                    |
|-------------|--------|------------------------------------------|
| id          | string | UUID                                     |
| title       | string |                                          |
| date        | string | ISO 8601                                 |
| isCompleted | bool   |                                          |
| sortOrder   | int    |                                          |
| updatedAt   | int    | epoch milliseconds (API); `DateTime` in app |
| isDeleted   | bool   | soft delete                              |
| isDirty     | bool   | app-only, ignored by server              |

### Endpoints

| Method | Path                        | Purpose                              |
|--------|-----------------------------|--------------------------------------|
| GET    | /tasks                      | list (optional `?deleted=true`)      |
| PUT    | /tasks                      | upsert task                          |
| DELETE | /tasks                      | soft-delete (task JSON body)         |
| GET    | /tasks/changes?since=<ms>   | tasks changed since epoch ms         |

Auth: `Authorization: Bearer <SYNC_API_KEY>`.

## Conventions

- The app must keep working offline with no `SYNC_API_URL`/`SYNC_API_KEY` set.
- Never commit generated/stateful files (already gitignored): `app/build/`, `app/.dart_tool/`, `server/data/`, `server/run.sh`.
