# Slate App (Flutter)

Flutter/Dart client for Slate. SDK `>=3.0.0 <4.0.0`, package name `slate`.

## Run / build

```bash
flutter pub get
flutter run --dart-define=SYNC_API_URL=http://localhost:8081 --dart-define=SYNC_API_KEY=rosquinha
flutter build apk --release --dart-define=SYNC_API_URL=... --dart-define=SYNC_API_KEY=...
```

Convenience scripts: `./run-mac.sh`, `./build-mac.sh`, `./run-android.sh`, `./build-android.sh`.

Runs fully offline without the `--dart-define` flags.

## Layout

- `lib/models/` — `Task` model and its JSON/DB serialization
- `lib/screens/` — day, calendar, home, and sync-error screens
- `lib/services/` — `api_client.dart` (HTTP), `sync_service.dart` (push/pull), `database_helper.dart` and `task_storage.dart` (local SQLite)
- `lib/widgets/` — shared UI pieces

## Behavior notes

- Offline-first: local SQLite (sqflite) is the source of truth; sync is best-effort.
- `SyncService` syncs on connectivity change, app resume/pause, and shortly after edits.
- Conflicts resolve last-write-wins on `updatedAt`.
- Sync failures surface in the header and via snackbar (`sync_error_screen.dart`).

## Contract

`api_client.dart` mirrors the routes in `server/`. See the root `AGENTS.md` for the shared `Task` JSON shape and endpoints; keep `api_client.dart` and `sync_service.dart` in step with any server change.
