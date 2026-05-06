# Blinking (记忆闪烁)

A bilingual (English/Chinese) personal memory journal and habit-tracking mobile app built with Flutter, featuring an AI assistant that reads your journal entries and holds multi-turn reflective conversations about your life.

**Current version:** `1.1.0-beta.8+23` | **106 tests passing** | **0 lint errors**

## Key Features

- **Journal entries** — text and images with emotion tracking (10 moods) and tag categorization
- **Daily checklists** — ad-hoc to-do lists with one-per-day constraint and user-prompted carry-forward
- **Habit tracking** — Build/Do/Reflect tabs, streak tracking with grace period, per-habit analytics
- **AI assistant** — multi-turn LLM chat, AI-generated insights, save reflections as journal entries
- **BYOK** — bring your own keys for 6 LLM providers (OpenAI, Anthropic, Google, DeepSeek, Groq, OpenRouter)
- **Insights dashboard** — writing stats, mood trends, heatmap, tag-mood correlation, checklist analytics
- **Offline preview** — 21-day local AI preview (3 queries/day), no server required
- **Bilingual UI** — English and Chinese with system locale detection
- **Local-first** — all data stored in SQLite, no account required
- **Backup/restore** — ZIP export with media compression (1920px, 85% quality) or text-only mode
- **Monetization** — one-time $9.99 Pro purchase via RevenueCat

## Tech Stack

- **Framework:** Flutter (SDK ^3.11.0)
- **State Management:** Provider
- **Database:** SQLite via sqflite
- **Platforms:** Android, iOS (also Linux, macOS, Windows stubs)
- **Languages:** Dart (app), TypeScript (Cloudflare Worker server)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Lint check
flutter analyze --no-pub

# Build Android
flutter build appbundle --release

# Build iOS (see docs/ios-testflight-build-push-guide.md)
```

## Project Structure

```
lib/
├── app.dart                    # Provider tree + MainScreen + navigation
├── main.dart                   # Entry point
├── core/
│   ├── config/                 # Constants, theme, emotions
│   ├── services/               # Storage, LLM, export, file, entitlement, purchases, etc.
│   └── utils/                  # CSV utilities
├── l10n/                       # Localization ARB files + generated Dart
├── models/                     # Entry, Routine, Tag, Card, etc.
├── providers/                  # State management (12 providers)
├── repositories/               # Data access layer
├── screens/                    # All app screens organized by feature
└── widgets/                    # Reusable widgets (calendar, emoji jar, floating robot, etc.)
```

## Navigation

5-tab bottom navigation: My Day | Moments | Routine | Insights | Settings

## Links

- [PROJECT_PLAN.md](PROJECT_PLAN.md) — full project plan and feature status
- [CLAUDE.md](CLAUDE.md) — developer context and conventions
- [docs/plans/](docs/plans/) — design plans and UAT documents
- [docs/release-notes/](docs/release-notes/) — per-version release notes
- [docs/plans/blinking-launch-plan-2026-05-02.md](docs/plans/blinking-launch-plan-2026-05-02.md) — launch plan

## Feedback

Email: `blinkingfeedback@gmail.com`
