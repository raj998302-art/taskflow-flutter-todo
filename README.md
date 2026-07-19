# Taskflow — Premium Flutter Todo App with Voice Reminders

A premium, production-quality **Todo List** application built with Flutter,
Material 3, and a clean feature-based architecture. It features a beautiful
glassmorphism UI, smooth animations, a statistics dashboard, dark & light
mode, and a fully offline local database — no backend required.

**New: Voice Reminders & Alarms** — set reminders that fire at an exact date
& time with spoken voice alerts. Example: *"Boss, apko sabji lena hai"* at
8:05 PM on the 19th. The app speaks the reminder aloud using text-to-speech
when the alarm fires, even if the app is closed.

---

## ✨ Features

### Tasks
- **Complete CRUD** — create, read, update, delete tasks with optimistic UI.
- **Task categories** — Personal, Work, Shopping, Health, Other (color-coded).
- **Priority levels** — Low / Medium / High with colored accents.
- **Due dates** — date picker with "Today", "Tomorrow", "Overdue" labels.
- **Search** — instant full-text search across title & description.
- **Filters** — All / Active / Done / Overdue / Today.
- **Sorting** — by newest, due date, priority, or A–Z.
- **Statistics dashboard** — completion ring, key metrics, weekly activity
  bar chart, and breakdowns by category & priority (powered by `fl_chart`).
- **Swipe actions** — swipe a task to complete or delete (`flutter_slidable`).

### Reminders & Voice Alarms
- **Set reminders** with exact date & time (e.g. "8:05 PM on July 19th").
- **Voice reminders** — the app speaks the reminder aloud using TTS:
  *"Boss, apko sabji lena hai"* when the alarm fires.
- **Custom voice prefix** — choose what to call yourself: "Boss", "Sir",
  "Hey", or anything you like.
- **Live voice preview** — tap "Preview voice" to hear how it sounds before
  saving.
- **Repeat options** — once, daily, weekdays, weekly, monthly.
- **Alarm survives reboot** — reminders are re-armed after device restart.
- **Full-screen alarm** — notifications appear as heads-up alarms with sound
  & vibration, even when the phone is locked.
- **Toggle on/off** — arm or disarm any reminder without deleting it.
- **Swipe to test/delete** — swipe a reminder card to test the voice or
  delete it.

### General
- **Dark & Light mode** — system-aware, persisted, instant toggle.
- **Glassmorphism UI** — frosted-glass surfaces, gradients, soft shadows.
- **Beautiful animations** — staggered list entrances, pulses, transitions.
- **Empty / loading / error states** — polished handling for every state.
- **Responsive** — adaptive layouts for phones & tablets.
- **Fully offline** — all data stored locally with Hive.

---

## 🧱 Tech Stack

| Concern              | Choice                          |
|----------------------|---------------------------------|
| Framework            | Flutter (Material 3)            |
| Language             | Dart                            |
| State management     | Riverpod (`flutter_riverpod`)   |
| Local database       | Hive (`hive` + `hive_flutter`)  |
| Routing              | go_router                       |
| Charts               | fl_chart                        |
| Animations           | flutter_animate                 |
| Swipe actions        | flutter_slidable                |
| **Notifications**    | **flutter_local_notifications** |
| **Text-to-speech**   | **flutter_tts**                 |
| **Timezone**         | **timezone**                    |
| Fonts                | google_fonts (Inter)            |
| Dates                | intl                            |

No code generation is required for the data layer — Hive serialization is
manual (Map-based), so there is no `build_runner` step needed to run the app.

---

## 🚀 Getting Started

### Prerequisites

- **Flutter >= 3.27.0** (stable channel)
- **Dart >= 3.6.0**
- A connected device, emulator, or simulator (or use the desktop/web target)

Install Flutter from the official site if you don't have it:
<https://docs.flutter.dev/get-started/install>

Verify your setup:

```bash
flutter --version
flutter doctor
```

### Install & Run

From the `flutter_todo_app/` directory:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run the app
flutter run
```

That's it — no codegen step, no backend, no API keys.

### Other Commands

```bash
# Static analysis (lint)
flutter analyze

# Build a release APK (Android)
flutter build apk --release

# Build for iOS (requires macOS + Xcode)
flutter build ios --release

# Build for the web
flutter build web --release
```

---

## 📁 Project Structure

The project follows a **clean, feature-based architecture** with three layers:
`domain`, `data`, and `presentation`, glued together with Riverpod providers.

```
flutter_todo_app/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart                  # Entry point — inits Hive, runs app
│   ├── app.dart                   # MaterialApp.router root widget
│   │
│   ├── core/                      # App-wide shared utilities
│   │   ├── constants/
│   │   │   ├── app_constants.dart # Box names, durations, defaults
│   │   │   └── app_colors.dart    # Brand, priority & category palette
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Material 3 light & dark themes
│   │   ├── utils/
│   │   │   ├── date_utils.dart    # Relative date formatting helpers
│   │   │   └── extensions.dart    # BuildContext, DateTime, Color exts
│   │   └── widgets/               # Reusable UI primitives
│   │       ├── glass_container.dart   # Frosted-glass surface
│   │       ├── empty_state.dart       # Empty-state placeholder
│   │       ├── loading_animation.dart # Pulsing-dots loader
│   │       ├── error_widget.dart      # AppErrorWidget + retry
│   │       └── stat_card.dart         # Dashboard metric card
│   │
│   ├── domain/                    # Pure business logic (no Flutter/IO)
│   │   ├── entities/
│   │   │   ├── task.dart          # Task entity + copyWith
│   │   │   └── task_enums.dart    # Priority & TaskCategory enums
│   │   ├── repositories/
│   │   │   └── task_repository.dart   # Abstract repository contract
│   │   └── usecases/              # Thin use-case wrappers
│   │       ├── add_task.dart
│   │       ├── update_task.dart
│   │       ├── delete_task.dart
│   │       ├── get_tasks.dart
│   │       └── toggle_task.dart
│   │
│   ├── data/                      # Persistence implementation
│   │   ├── models/
│   │   │   └── task_model.dart    # Hive Map ↔ Task serialization
│   │   ├── datasources/
│   │   │   └── local/
│   │   │       └── task_local_datasource.dart  # Hive box CRUD
│   │   └── repositories/
│   │       └── task_repository_impl.dart       # Implements domain contract
│   │
│   ├── presentation/              # UI layer
│   │   ├── providers/             # Riverpod state
│   │   │   ├── task_providers.dart    # taskListProvider + notifier
│   │   │   ├── filter_providers.dart  # filterProvider (search/sort/filter)
│   │   │   ├── stats_provider.dart    # statsProvider + filteredTasksProvider
│   │   │   └── theme_provider.dart    # themeModeProvider (persisted)
│   │   ├── pages/
│   │   │   ├── home_page.dart         # Main screen + FAB
│   │   │   ├── statistics_page.dart   # Dashboard with charts
│   │   │   └── task_detail_page.dart  # Single task view/edit/delete
│   │   └── widgets/               # Feature-specific widgets
│   │       ├── task_card.dart         # Slidable glassmorphic card
│   │       ├── task_list.dart         # Animated list + empty state
│   │       ├── add_task_sheet.dart    # Create/edit bottom sheet
│   │       ├── filter_bar.dart        # Filter chips + sort menu
│   │       ├── search_bar_widget.dart # Search field
│   │       └── category_chip.dart     # Selectable category pill
│   │
│   └── router/
│       └── app_router.dart        # go_router configuration
└── test/
```

---

## 🏛 Architecture

### Layered design

- **`domain/`** — entities, repository contracts, and use cases. Has **zero**
  dependencies on Flutter or Hive. This is the heart of the business logic.
- **`data/`** — implements the domain contracts. `TaskLocalDataSource` talks
  to Hive; `TaskRepositoryImpl` adapts it to the `TaskRepository` interface.
  `TaskModel` handles serialization (manual Maps — no codegen).
- **`presentation/`** — widgets, pages, and Riverpod providers. Depends on the
  domain layer (via the abstract repository), never on Hive directly.

Dependency direction: `presentation → domain ← data`. The data layer depends
on the domain (implements its interfaces), keeping persistence swappable.

### State management (Riverpod)

- `taskRepositoryProvider` — a single `TaskRepository` (Hive-backed).
- `taskListProvider` — a `StateNotifier<TaskListNotifier, AsyncValue<List<Task>>>`
  holding the source-of-truth list and exposing all CRUD methods. UI reads via
  `ref.watch`, mutates via `ref.read(...notifier)`. Updates are **optimistic**
  with rollback on failure.
- `filterProvider` — search query, filter, category, priority, and sort.
- `filteredTasksProvider` — derived list (filters + sorting applied).
- `statsProvider` — derived `TaskStats` aggregate for the dashboard.
- `themeModeProvider` — persisted `ThemeMode` (light/dark/system).

### Persistence (Hive)

Two boxes are opened eagerly in `main.dart`:

- `tasks_box` — stores every task as a JSON-like `Map<String, dynamic>`.
- `settings_box` — stores the theme mode and other preferences.

`TaskModel.toMap` / `TaskModel.fromMap` convert between the domain `Task`
entity and the stored Map, so the domain layer stays persistence-agnostic.

---

## 🎨 Design system

- **Primary color** — deep violet (`#7C5CFC`) with cyan & pink accents.
- **Surfaces** — adaptive light/dark backgrounds with frosted-glass overlays.
- **Priority colors** — red (high), amber (medium), green (low).
- **Category colors** — consistent hues per category across chips & charts.
- **Typography** — Inter (via `google_fonts`), applied globally.
- **Motion** — subtle, staggered entrances; pulses; smooth transitions.

---

## 🧪 Running Tests

```bash
flutter test
```

The project is structured to make widget and provider tests straightforward
— the repository is behind an interface, so unit tests can inject an in-memory
fake `TaskRepository` without touching Hive.

---

## 📦 Build for Release

```bash
# Android
flutter build apk --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release

# macOS / Windows / Linux desktop
flutter build macos --release
```

---

## 📝 Notes

- All data is stored **locally on-device** — uninstalling the app clears it.
- No analytics, telemetry, or network calls are made.
- The app targets Material 3 and adapts to system theme by default; the user
  can override to light or dark from the home header toggle.
