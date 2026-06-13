![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Built with Claude](https://img.shields.io/badge/Built%20with-Claude-orange?logo=anthropic)

# Slate — Flutter App

A clean, minimal daily task scheduler built for personal use. Tasks are organized by day, with swipe navigation between dates and a calendar for quick jumps.

## Features

- **Day view** — current date opens by default
- **Swipe navigation** — slide left/right to move between days  
- **Calendar view** — tap the calendar icon to jump to any date
- **Persistent storage** — all tasks saved locally via `shared_preferences`
- **Dot indicators** on calendar for days that have tasks

---

## Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0 ([install guide](https://docs.flutter.dev/get-started/install))
- An Android device or emulator (API 21+)

### Steps

```bash
# 1. Navigate to the project
cd slate

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Design Notes

- **Color palette**: Dark navy (`#1A1A2E`) + warm cream (`#F5F0E8`) + red accent (`#E84855`)
- **Navigation**: `PageController` with 20,000 pages (index 10,000 = today)
- **Storage key format**: `tasks_YYYY-MM-DD` per day
- Tasks are split into **pending** and **done** sections automatically
