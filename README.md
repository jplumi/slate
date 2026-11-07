# Slate

Personal daily task scheduler: a Flutter app with offline-first local storage that syncs to a small Go backend.

| Directory  | What it is                                             |
|------------|--------------------------------------------------------|
| `app/`     | Flutter client — see `app/README.md` and `app/AGENTS.md` |
| `server/`  | Go sync backend — see `server/AGENTS.md`                 |

## Quick start

Server:

```bash
cd server
./run.sh   # starts on :8081 with a dev API key
```

App:

```bash
cd app
flutter pub get
flutter run --dart-define=SYNC_API_URL=http://localhost:8081 --dart-define=SYNC_API_KEY=rosquinha
```

The app works fully offline when the sync variables are omitted.
