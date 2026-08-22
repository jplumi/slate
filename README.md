![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Built with Claude](https://img.shields.io/badge/Built%20with-Claude-orange?logo=anthropic)

# Slate — Flutter App

A clean, minimal daily task scheduler. Tasks are organized by day, with swipe navigation between dates and a calendar for quick jumps.

> Personal project — built for my own daily use, not intended as a general-purpose app.

## Features

- Day view with swipe navigation between dates
- Calendar view
- Offline-first local storage (SQLite), with sync to a personal backend ([slate-server](https://github.com/jplumi/slate-server))

## Setup & Run

```bash
cd slate
flutter pub get
flutter run --dart-define=SYNC_API_URL=https://sync-service.example.com --dart-define=SYNC_API_KEY=api-key
flutter build apk --release --dart-define=SYNC_API_URL=https://sync-service.example.com --dart-define=SYNC_API_KEY=api-key
```

Works fully offline without the sync env vars set.

## Sync

`SyncService` pushes local changes and pulls remote ones whenever connectivity returns, the app resumes/pauses, or shortly after an edit. Conflicts resolve by last-write-wins (`updatedAt`). Sync status shows in the header; failures surface as a snackbar.
