# Blinking App — Claude Context

Personal memory/habit-tracking Flutter app (记忆闪烁). Path: `/home/justin/.nanobot/workspace/blinking_app`

## Quick Reference

- **Flutter SDK:** `^3.11.0`
- **Current version:** `1.0.3+4` (pubspec.yaml)
- **DB version:** 4 (sequential migrations in `DatabaseService.onUpgrade`)
- **Build:** `flutter build apk --debug`
- **Lint:** `flutter analyze --no-pub` (target: 0 errors)

---

## Architecture

### State Management
Provider tree (defined in `lib/app.dart`):

| Provider | Type | Notes |
|----------|------|-------|
| `StorageService` | `Provider` | SQLite + SharedPreferences |
| `ExportService` | `Provider` | ZIP export/import |
| `ThemeProvider` | `ChangeNotifier` | Persisted to SharedPreferences |
| `LocaleProvider` | `ChangeNotifier` | Persisted; `loadLocale()` called on creation |
| `EntryProvider` | `ChangeNotifier` | Source of truth for all entries |
| `RoutineProvider` | `ChangeNotifier` | Source of truth for all routines |
| `TagProvider` | `ChangeNotifier` | Source of truth for all tags |
| `JarProvider` | `ProxyProvider<EntryProvider>` | Emotion aggregation by year/month/day |
| `CardProvider` | `ChangeNotifier` | Folders, templates, note cards |
| `SummaryProvider` | `ProxyProvider2<EntryProvider, RoutineProvider>` | Chart metrics (daily/weekly/monthly) |

### Navigation
Bottom nav (5 tabs) in `MainScreen` (`lib/app.dart`):
```
Calendar | Moment | Routine | 珍藏 | Settings
```
- `FloatingRobotWidget` overlay (bobbing 🤖) → taps into `AssistantScreen` modal
- `FloatingActionButton` → `AddEntryScreen`

### Storage Layers
- **SQLite** via `DatabaseService` singleton (accessed through `StorageService`)
  - DB version 4; migration blocks: v1→v2 (emotion, category), v2→v3 (old — unused path now), v3→v4 (card tables)
  - Tables: `entries`, `routines`, `tags`, `templates`, `card_folders`, `note_cards`, `note_card_entries`
- **SharedPreferences** for: theme, locale, LLM provider config (`llm_providers`, `llm_selected_index`)
- **File system** via `FileService` for media attachments and rendered card PNGs

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/app.dart` | Provider tree + `MainScreen` (nav + `FloatingRobotWidget`) |
| `lib/main.dart` | App entry point, `StorageService` init |
| `lib/core/services/storage_service.dart` | All CRUD; seeds default tags, routines, templates, folders |
| `lib/core/services/database_service.dart` | SQLite schema v4 + migrations |
| `lib/core/services/llm_service.dart` | OpenAI-compatible chat/complete; reads provider config from SharedPreferences |
| `lib/core/services/file_service.dart` | Media copy to app documents directory |
| `lib/core/config/emotions.dart` | `kDefaultEmotions` — 10 emoji strings |
| `lib/providers/entry_provider.dart` | `addEntry`, `getDayEmotion`, `setSearchQuery`, `setFilterTag` |
| `lib/providers/jar_provider.dart` | `getDayEmotions`, `getMonthEmotionMap`, `getYearEmotions`, `getYearEntryCount` |
| `lib/providers/card_provider.dart` | Folders + templates + note cards CRUD; `load()` on init |
| `lib/providers/summary_provider.dart` | `noteCounts`, `routineCompletionRates`, `emotionTrend`, `topTags` |
| `lib/screens/add_entry_screen.dart` | Add/edit entry (emotion picker, tag picker, image/audio) |
| `lib/screens/assistant/assistant_screen.dart` | Multi-turn LLM chat + Save Reflection |
| `lib/screens/moment/moment_screen.dart` | Entry list with live search + tag/date filter |
| `lib/screens/cherished/cherished_memory_screen.dart` | 3-tab shell: 书架 / 卡片 / 总结 |
| `lib/screens/cherished/shelf_tab.dart` | Yearly jar cards → `YearJarDetailScreen` |
| `lib/screens/cherished/cards_tab.dart` | Card grid + folder filter → `CardBuilderDialog` |
| `lib/screens/cherished/summary_tab.dart` | fl_chart visualizations (scope: 日/周/月) |
| `lib/screens/settings/settings_screen.dart` | LLM config (persisted), tags, language, export |
| `lib/widgets/emoji_jar.dart` | `EmojiJarWidget` CustomPainter + AI bottom sheet |
| `lib/widgets/card_renderer.dart` | `RepaintBoundary` off-screen PNG render |
| `lib/widgets/floating_robot.dart` | Bobbing robot overlay widget |

---

## Important Conventions

### Database Migrations
Always use sequential `if (oldVersion < N)` blocks in `DatabaseService.onUpgrade`. Never nest or use `else if`. `_onCreate` always creates the full v4 schema.

### LLM Provider Config
Stored as JSON list in SharedPreferences key `llm_providers`. Use **merge-on-load** strategy in Settings: start from saved list (preserving API keys), then append any defaults not already present by name. Never discard saved providers on load.

### Stable IDs
`tag_reflection` is hardcoded in `AssistantScreen._saveReflection()`. Do not rename or delete this tag ID.

### Emotion Encoding
For `SummaryProvider` emotion trend chart: 😊=5, 😌=4, 😐=3, 😢=2, 😡=1. Missing emotion defaults to 3 (neutral baseline).

### Provider Hierarchy
`AppProvider` was deleted. Do not recreate it. Settings screen uses `TagProvider` directly.

---

## Pending Work

| Priority | Item |
|----------|------|
| P2 | Wire image picker → `FileService.saveFile()` → `entry.mediaUrls` → display in `EntryCard` |
| P2 | Implement audio recording with `flutter_sound` (currently a snackbar stub) |
| P2 | Dedicated entry detail / read-only view |
| P3 | Firebase / Cloud Sync (all deps commented out in pubspec) |
| P3 | Tests (currently a single placeholder) |
| P3 | CSV export UI trigger |
| P3 | Backup import UI |

---

## Commit History

| Version | Commit | What |
|---------|--------|------|
| v1.0.0 | 42b23e4 | Initial release |
| v1.0.1 | bc3d826 | Phase 1: emotion, routine categories, calendar emoji |
| v1.0.2 | 1ea1f96 | Phase 2: floating robot, LlmService, AssistantScreen real LLM |
| v1.0.3 | a99adc6 | Phase 2–5: jar, cards, summary + LLM merge fix + version bump |
| —      | a204bcd | Fix: ActionChip colors black87 in AssistantScreen |
| —      | b064e3a | Docs: phases 3–5 marked tested & passed |
