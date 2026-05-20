# Daily Tasks — Flutter App

A clean, minimal daily task scheduler for Android built with Flutter.

## Features

- **Day view** — current date opens by default
- **Swipe navigation** — slide left/right to move between days  
- **Calendar view** — tap the calendar icon to jump to any date
- **Add tasks** — tap the **+** button, or tap anywhere on an empty screen
- **Check off tasks** — tap the checkbox; done tasks move to a "Done" section
- **Edit tasks** — double-tap any task to edit inline
- **Delete tasks** — swipe a task left to delete it
- **Persistent storage** — all tasks saved locally via `shared_preferences`
- **Dot indicators** on calendar for days that have tasks

---

## Project Structure

```
lib/
├── main.dart               # Entry point
├── app.dart                # MaterialApp + AppTheme
├── models/
│   └── task.dart           # Task data model
├── services/
│   └── task_storage.dart   # SharedPreferences persistence
├── screens/
│   ├── home_screen.dart    # PageView-based day navigator
│   ├── day_screen.dart     # Task list for a single day
│   └── calendar_screen.dart # TableCalendar day picker
└── widgets/
    ├── task_tile.dart      # Swipeable, editable task row
    └── add_task_sheet.dart # Bottom sheet for adding tasks
```

---

## Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0 ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter plugin
- An Android device or emulator (API 21+)

### Steps

```bash
# 1. Navigate to the project
cd todo_app

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | ^2.2.2 | Local task persistence |
| `table_calendar` | ^3.1.0 | Calendar view |
| `intl` | ^0.19.0 | Date formatting |
| `uuid` | ^4.3.3 | Unique task IDs |

---

## Design Notes

- **Color palette**: Dark navy (`#1A1A2E`) + warm cream (`#F5F0E8`) + red accent (`#E84855`)
- **Navigation**: `PageController` with 20,000 pages (index 10,000 = today)
- **Storage key format**: `tasks_YYYY-MM-DD` per day
- Tasks are split into **pending** and **done** sections automatically
