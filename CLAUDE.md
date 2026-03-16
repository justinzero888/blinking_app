# Blinking App — Claude Context

Personal memory/habit-tracking Flutter app (记忆闪烁). Path: `/home/justin/.nanobot/workspace/blinking_app`

## Quick Reference

- **Flutter SDK:** `^3.11.0`
- **Current version:** `1.0.6+7` (pubspec.yaml)
- **DB version:** 7 (sequential migrations in `DatabaseService.onUpgrade`)
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
- `FloatingRobotWidget` overlay (bobbing + pulsing 🤖, wave-on-tap) → `AssistantScreen` modal
- `FloatingActionButton` → `AddEntryScreen`

### Storage Layers
- **SQLite** via `DatabaseService` singleton (accessed through `StorageService`)
  - DB version 7; migration blocks: `< 2` (entries/routines), `< 3` (emotion/category), `< 4` (card tables), `< 5` (routine scheduling), `< 6` (template image + card AI summary), `< 7` (card rich content)
  - Tables: `entries`, `routines`, `tags`, `templates`, `card_folders`, `note_cards`, `note_card_entries`
- **SharedPreferences** for: theme, locale, LLM provider config (`llm_providers`, `llm_selected_index`), AI persona (`ai_assistant_name`, `ai_assistant_personality`)
- **File system** via `FileService` for media attachments, rendered card PNGs, custom template images, and card inline images (`card_images/`)

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/app.dart` | Provider tree + `MainScreen` (nav + `FloatingRobotWidget`); registers `FlutterQuillLocalizations.delegate` |
| `lib/main.dart` | App entry point, `StorageService` init |
| `lib/core/services/storage_service.dart` | All CRUD; seeds default tags, routines, templates, folders |
| `lib/core/services/database_service.dart` | SQLite schema v7 + migrations |
| `lib/core/services/llm_service.dart` | OpenAI-compatible chat/complete; reads provider config from SharedPreferences |
| `lib/core/services/file_service.dart` | Media copy to app documents directory |
| `lib/core/config/emotions.dart` | `kDefaultEmotions` — 10 emoji strings |
| `lib/providers/entry_provider.dart` | `addEntry`, `getDayEmotion`, `setSearchQuery`, `setFilterTag` |
| `lib/providers/routine_provider.dart` | `getRoutinesForDate`, `isMissedOn`, `toggleComplete` |
| `lib/providers/jar_provider.dart` | `getDayEmotions`, `getMonthEmotionMap`, `getYearEmotions`, `getYearEntryCount` |
| `lib/providers/card_provider.dart` | Folders + templates + note cards CRUD; `updateCard()`, `copyBuiltInTemplate()` |
| `lib/providers/summary_provider.dart` | `noteCounts`, `routineCompletionRates`, `emotionTrend`, `topTags` |
| `lib/screens/add_entry_screen.dart` | Add/edit entry (emotion picker, tag picker, image/audio) |
| `lib/screens/assistant/assistant_screen.dart` | Multi-turn LLM chat; dynamic system prompt from AI persona; Save Reflection |
| `lib/screens/moment/moment_screen.dart` | Entry list with live search + tag/date filter |
| `lib/screens/routine/routine_screen.dart` | 3-tab: 全部 / 今日 / 记录; add/edit dialog with frequency/day/date pickers |
| `lib/screens/cherished/cherished_memory_screen.dart` | 3-tab shell: 书架 / 卡片 / 总结 |
| `lib/screens/cherished/shelf_tab.dart` | Yearly jar cards → `YearJarDetailScreen` |
| `lib/screens/cherished/cards_tab.dart` | Card grid + folder filter; tap → `CardEditorScreen`; long-press → Edit/Share/Delete |
| `lib/screens/cherished/card_builder_dialog.dart` | Create card; AI merge (≤100 words); template editor sheet |
| `lib/screens/cherished/card_editor_screen.dart` | flutter_quill rich text editor; word counter (X/100); image insert |
| `lib/screens/cherished/summary_tab.dart` | fl_chart visualizations (scope: 日/周/月) |
| `lib/screens/settings/settings_screen.dart` | LLM config, tags, language, export, AI 个性化 |
| `lib/widgets/emoji_jar.dart` | `EmojiJarWidget` CustomPainter + AI bottom sheet |
| `lib/widgets/card_renderer.dart` | Off-screen PNG render; `_extractPlainText()` handles `richContent > aiSummary > entry` |
| `lib/widgets/floating_robot.dart` | Bobbing + pulse + wave-on-tap robot overlay (3 AnimationControllers) |
| `lib/widgets/entry_card.dart` | Entry display card with share button |

---

## Important Conventions

### Database Migrations
Always use sequential `if (oldVersion < N)` blocks in `DatabaseService.onUpgrade`. Never nest or use `else if`. `_onCreate` always creates the full v7 schema.

### LLM Provider Config
Stored as JSON list in SharedPreferences key `llm_providers`. Use **merge-on-load** strategy in Settings: start from saved list (preserving API keys), then append any defaults not already present by name. Never discard saved providers on load.

### AI Persona Config
Stored in SharedPreferences: `ai_assistant_name` (default `'AI 助手'`) and `ai_assistant_personality` (default `''`). `AssistantScreen` reads these in `initState` and builds a dynamic `_systemPrompt` getter. Settings screen writes them on save.

### Stable IDs
`tag_reflection` is hardcoded in `AssistantScreen._saveReflection()`. Do not rename or delete this tag ID.

### Emotion Encoding
For `SummaryProvider` emotion trend chart: 😊=5, 😌=4, 😐=3, 😢=2, 😡=1. Missing emotion defaults to 3 (neutral baseline).

### Provider Hierarchy
`AppProvider` was deleted. Do not recreate it. Settings screen uses `TagProvider` directly.

### Routine Scheduling
`RoutineFrequency` has four values: `daily | weekly | scheduled | adhoc`.
- `weekly`: uses `scheduledDaysOfWeek: List<int>` (1=Mon…7=Sun ISO 8601)
- `scheduled`: uses `scheduledDate: DateTime` (one-time)
- `adhoc`: never auto-appears; user adds manually via "手动加入"
- `isMissedOn(Routine, DateTime)` is a pure derivation — no extra DB column

### Card Content Priority
`NoteCard` has three text fields in precedence order:
1. `richContent: String?` — Quill Delta JSON (set by `CardEditorScreen`); source of truth when present
2. `aiSummary: String?` — plain text; written by AI merge in `CardBuilderDialog` and kept in sync as plain-text mirror of `richContent` on every save
3. First entry's `content` — fallback when neither field is set

`_extractPlainText()` in `CardRenderer` implements this priority. `note_card_entries` links to original entries and must never be modified by card operations.

### Card Templates
Built-in templates must never be mutated. Use `CardProvider.copyBuiltInTemplate()` to create an `isBuiltIn: false` copy before editing.

### flutter_quill Integration
`FlutterQuillLocalizations.delegate` **must** be present in `MaterialApp.localizationsDelegates` (registered in `app.dart`). Without it, `QuillEditor` throws `UnimplementedError` at runtime. The delegate is appended via spread: `[...AppLocalizations.localizationsDelegates, FlutterQuillLocalizations.delegate]`.

Word counting for the 100-word limit uses mixed CJK+English logic: each CJK character (U+4E00–U+9FFF, U+3400–U+4DBF) = 1 word; English words counted by whitespace tokens.

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
| v1.0.1 | bc3d826 | Emotion picker, routine categories, calendar emoji |
| v1.0.2 | 1ea1f96 | Floating robot, LlmService, AssistantScreen real LLM |
| v1.0.3 | a99adc6 | Jar, cards, summary + LLM merge fix |
| v1.0.4 | 78d2c7b | Phase 1: habit system overhaul (RoutineFrequency, 3-tab screen, calendar badges) |
| v1.0.5 | 7bb251c | Phases 2–4: card edit/AI merge/template image, social sharing, AI personalization |
| v1.0.6 | ddf89d5 | Rich card editor (flutter_quill), 100-word limit, card tap → edit, 3 bug fixes |
