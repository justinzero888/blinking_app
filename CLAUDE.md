# Blinking App — Claude Context

Personal memory/habit-tracking Flutter app (记忆闪烁). Path: `/Users/justinzero/ClaudeDev/blink/blinking_app`

## Quick Reference

- **Flutter SDK:** `^3.11.0` (currently 3.41.8 stable, Apr 24 2026)
- **macOS:** 26.2 (Tahoe beta) — requires Xcode 26, managed in `ClaudeDev/system-upgrade`
- **Current version:** `1.1.0-beta.7+22` (pubspec.yaml)
- **DB version:** 12 (`kSchemaVersion = 12` in `DatabaseService`)
- **Build AAB:** `flutter build appbundle --release`
- **Build APK:** `flutter build apk --release`
- **Lint:** `flutter analyze --no-pub` (target: 0 errors)
- **Tests:** `flutter test` (96 tests, all passing)
- **Feedback email:** `blinkingfeedback@gmail.com`

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
Calendar | Moment | Routine | Insights | Settings
```
- `FloatingRobotWidget` overlay (bobbing + pulsing 🤖, wave-on-tap) → `AssistantScreen` modal
- `FloatingActionButton` (heroTag: `'main_add_entry_fab'`, contextual per tab) → `AddEntryScreen` or `AddRoutineDialog`
- FAB hidden on Insights and Settings tabs

### Storage Layers
- **SQLite** via `DatabaseService` singleton (accessed through `StorageService`)
  - DB version 12; migration blocks: `< 2` (entries/routines), `< 3` (emotion/category), `< 4` (card tables), `< 5` (routine scheduling), `< 6` (template image + card AI summary), `< 7` (card rich content), `< 8` (routine `icon_image_path`), `< 9` (template `custom_image_path`), `< 10` (template `source_template_id`), `< 11` (indexes on `entry_tags(entry_id)` + `note_card_entries(card_id)`), `< 12` (checklist: `entry_format`, `list_items`, `list_carried_forward`)
  - Tables: `entries`, `routines`, `tags`, `templates`, `card_folders`, `note_cards`, `note_card_entries`
- **SharedPreferences** for: theme, locale, LLM provider config (`llm_providers`, `llm_selected_index`), AI persona (`ai_assistant_name`, `ai_assistant_personality`)
- **File system** via `FileService` for media attachments, rendered card PNGs, custom template images, and card inline images (`card_images/`)

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/app.dart` | Provider tree + `MainScreen` (nav + `FloatingRobotWidget`); registers `FlutterQuillLocalizations.delegate` |
| `lib/main.dart` | App entry point, `StorageService` init |
| `lib/core/config/constants.dart` | `AppConstants.appVersion` — keep in sync with pubspec.yaml |
| `lib/core/services/storage_service.dart` | All CRUD; seeds default tags, routines, templates, folders |
| `lib/core/services/database_service.dart` | SQLite schema v11 + sequential migrations |
| `lib/core/services/llm_service.dart` | OpenAI-compatible chat/complete; reads provider config from SharedPreferences |
| `lib/core/services/file_service.dart` | Media copy to app documents directory |
| `lib/core/services/chorus_service.dart` | Social publishing to Chorus backend |
| `lib/core/services/trial_service.dart` | 7-day trial token lifecycle (start, status, expiry) |
| `lib/core/services/device_service.dart` | Anonymous device UUID for trial identification |
| `lib/core/config/emotions.dart` | `kDefaultEmotions` — 10 emoji strings |
| `lib/providers/entry_provider.dart` | `addEntry`, `getDayEmotion`, `setSearchQuery`, `setFilterTag` |
| `lib/providers/routine_provider.dart` | `getRoutinesForDate`, `isMissedOn`, `toggleComplete` |
| `lib/providers/jar_provider.dart` | `getDayEmotions`, `getMonthEmotionMap`, `getYearEmotions`, `getYearEntryCount` |
| `lib/providers/card_provider.dart` | Folders + templates + note cards CRUD; `updateCard()`, `copyBuiltInTemplate(isZh)` |
| `lib/providers/summary_provider.dart` | `noteCounts`, `routineCompletionRates`, `emotionTrend`, `topTags` |
| `lib/core/constants/legal_content.dart` | `kPrivacyPolicyContent` + `kTermsOfServiceContent` string constants |
| `lib/screens/legal_doc_screen.dart` | Shared scrollable legal document viewer (Privacy Policy, Terms of Service) |
| `lib/screens/add_entry_screen.dart` | Add/edit entry (emotion picker, tag picker, image — video/audio removed in v1.1.0) |
| `lib/screens/assistant/assistant_screen.dart` | Multi-turn LLM chat; dynamic system prompt from AI persona; Save Reflection |
| `lib/screens/moment/moment_screen.dart` | Entry list with live search + tag/date filter |
| `lib/screens/moment/entry_detail_screen.dart` | Read-only entry detail view with share + Post to Chorus |
| `lib/screens/routine/routine_screen.dart` | 3-tab: 全部 / 今日 / 记录; add/edit dialog with frequency/day/date pickers |
| `lib/screens/cherished/cherished_memory_screen.dart` | Insights screen: yearly emoji jar carousel + 4 summary charts (note count, habit completion, mood trend, top tags) |
| `lib/screens/cherished/shelf_tab.dart` | Yearly jar cards → `YearJarDetailScreen` (may be deprecated post-PROP-8) |
| `lib/screens/cherished/cards_tab.dart` | Card grid + folder filter (may be deprecated post-PROP-8) |
| `lib/screens/cherished/card_builder_dialog.dart` | Create card; AI merge (≤100 words); template editor sheet (deprecated) |
| `lib/screens/cherished/card_editor_screen.dart` | flutter_quill rich text editor (deprecated — flutter_quill removed) |
| `lib/screens/cherished/card_preview_screen.dart` | PNG preview of rendered card (deprecated) |
| `lib/screens/cherished/summary_tab.dart` | fl_chart visualizations — merged into `cherished_memory_screen.dart` post-PROP-8 |
| `lib/screens/chorus/post_to_chorus_sheet.dart` | Bottom sheet for posting entries to Chorus social platform |
| `lib/screens/settings/settings_screen.dart` | LLM config, tags, language, export, AI 个性化, Send Feedback |
| `lib/widgets/emoji_jar.dart` | `EmojiJarWidget` CustomPainter + AI bottom sheet |
| `lib/widgets/card_renderer.dart` | Off-screen PNG render; `_autoFontSize()` 96px→9px; text area = height×0.8/width×0.88; custom bg image with rounded clip (may be deprecated) |
| `lib/widgets/floating_robot.dart` | Bobbing + pulse + wave-on-tap robot overlay (3 AnimationControllers); avatar = 🤖 emoji |
| `lib/widgets/entry_card.dart` | Entry display card with share button |

---

## Important Conventions

### Database Migrations
Always use sequential `if (oldVersion < N)` blocks in `DatabaseService.onUpgrade`. Never nest or use `else if`. `_onCreate` always creates the full v11 schema. `kSchemaVersion` at top of class defines the current target.

### Version Sync
When bumping `pubspec.yaml` version, also update `lib/core/config/constants.dart` `AppConstants.appVersion` (semver only, no build number) and the version subtitle in `settings_screen.dart`. A `test/core/version_test.dart` enforces this.

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
Built-in templates must never be mutated. Use `CardProvider.copyBuiltInTemplate({bool isZh})` to create an `isBuiltIn: false` copy before editing. Template display names use `CardTemplate.displayNameFor(bool isZh)` — do not use `.name` directly in UI. Copies of built-in templates store `sourceTemplateId` so they can resolve English display names (e.g. "Custom — Spring Day").

### Card Renderer
`CardRenderer` uses `_autoFontSize(text, maxWidth, maxHeight)` — iterates 96px→9px via `TextPainter` to find largest font that fits. Text area = `width * 0.88` × `height * 0.8`. Both the widget `build()` and static `renderToImage()` use the same helper for consistent sizing.

### Card Share
Always call `Share.shareXFiles([XFile(path)])` without `text:` or `subject:` params. The image contains all content; sending text alongside is redundant.

### flutter_quill Integration
`FlutterQuillLocalizations.delegate` **must** be present in `MaterialApp.localizationsDelegates` (registered in `app.dart`). Without it, `QuillEditor` throws `UnimplementedError` at runtime. The delegate is appended via spread: `[...AppLocalizations.localizationsDelegates, FlutterQuillLocalizations.delegate]`.

Word counting for the 100-word limit uses mixed CJK+English logic: each CJK character (U+4E00–U+9FFF, U+3400–U+4DBF) = 1 word; English words counted by whitespace tokens.

### FAB Hero Tags
Main FAB in `app.dart`: `heroTag: 'main_add_entry_fab'`. Cards tab FAB in `cards_tab.dart`: `heroTag: 'cards_tab_new_card_fab'`. Required to prevent Hero tag conflicts during tab navigation.

### url_launcher / mailto
Use `try { await launchUrl(uri); } catch (_) { ... }` pattern. Do NOT use `canLaunchUrl` for `mailto:` — it is unreliable on iOS 14+ without `LSApplicationQueriesSchemes`.

### Daily Checklist (PROP-9)
- **One list per day:** `AddEntryScreen._switchFormat()` checks `EntryProvider.getEntriesForDate(today)` for existing `EntryFormat.list` entries. If found, shows snackbar + 300ms fade transition to edit the existing list.
- **Toggle data preservation:** Note→List extracts first 200 chars / first line break as title. List→Note concatenates items as `"- item\n"` lines into body text.
- **Carry-forward (user-prompted):** `EntryProvider.getCarryForwardPreview()` returns unchecked items from yesterday's list. `HomeScreen._scheduleCarryForwardCheck()` triggers on first load each day. Shows `AlertDialog` asking user to carry forward. Tracked per-day via `SharedPreferences` (`carry_forward_dialog_YYYY_M_D`).
- **`ListItem.fromPreviousDay`:** Flag on items carried over. Rendered as italic "Yesterday" / "昨日" label in `EntryCard`, `EntryDetailScreen`, `AddEntryScreen`.
- **Past-date entries view-only:** `EntryCard._buildListItem()` blocks toggle for past dates. `HomeScreen._onEntryTapped()` routes past entries to `EntryDetailScreen`. Edit button hidden for past entries. `AddEntryScreen` shows "View Memory" read-only mode with save guard.
- **Carry-forward banner:** Removed entirely (redundant after explicit dialog + "Yesterday" labels).
- **List edit UX:** Helper text below title ("Tap to check · Drag to reorder · × to remove"), drag handle 24px.
- **EntryFormat enum:** Coexists with `EntryType`. Values: `note`, `list`. DB column `entry_format`.

---

## Feature Status & Pending Work

### Completed
| Feature | Status |
|---------|--------|
| AI assistant (multi-turn LLM chat + Save Reflection) | ✅ Done |
| AI Secrets tag (exclude private notes from AI context) | ✅ Done |
| AI Secrets lock icon on entries (PROP-7) | ✅ Done |
| Bilingual UI (EN/ZH) | ✅ Done |
| Backup/Restore (ZIP + JSON) with progress bars | ✅ Done |
| Chorus social posting (publish to blinkingchorus.com) | ✅ Done |
| Entry detail read-only view with share + Post to Chorus | ✅ Done |
| Habit import/export (JSON) | ✅ Done |
| Legal docs (Privacy Policy + ToS) | ✅ Done |
| Card PNG cleanup (PROP-4) | ✅ Done |
| DB indexes v11 (PROP-5) | ✅ Done |
| Onboarding banner (Calendar, one-time dismissible) | ✅ Done |
| Trial API key flow (7-day free trial, app + backend) | ✅ Done (PROP-6) |
| Daily Checklist Entry (ad-hoc lists, user-prompted carry-forward, 1-per-day) | ✅ Done (PROP-9) |
| Calendar future date lock (Issue #1) | ✅ Done |
| Keepsakes → Insights restructure (PROP-8) | ✅ Done |
| Insights tab — emoji jar carousel + summary charts | ✅ Done |
| Insights tab Phase 1 — hero cards, heatmap, mood donut, visual polish (Issue #15) | ✅ Done |
| Insights tab Phase 2 — CT1: Writing Stats (avg words, active day, peak hour) | ✅ Done |
| Insights tab Phase 2 — CT3: Tag-Mood Correlation (tag → mood score, min 3 entries) | ✅ Done |
| Insights tab Phase 2 — CT2: Checklist Analytics (lists, completion, carry-forward, top item) | ✅ Done |
| Insights tab hero row overflow fix (4th card clipped on iPhone) | ✅ Done |
| HomeScreen title "Calendar" → "My Day" (Issue #14) | ✅ Done |
| Contextual FAB — per-tab icon + action (Issue #7) | ✅ Done |
| Collapsible calendar — week strip default, landscape safe (Issue #13) | ✅ Done |
| EntryDetailScreen title overflow fix | ✅ Done |
| Carry-forward redesign — user-prompted dialog + "Yesterday" flag | ✅ Done |
| Past-date entries view-only lock | ✅ Done |
| Insights tab crash fix (empty tags guard) | ✅ Done |
| Moment tab icon differentiation (note/checklist/routine) | ✅ Done |
| One-list-per-day transition UX (snackbar + fade) | ✅ Done |
| List edit screen helper text + drag handle size | ✅ Done |
| Carry-forward banner removal (dead code cleanup) | ✅ Done |
| iOS App Store submission | ✅ Done |

### Pending
| Priority | Item | Effort | Status |
|----------|------|--------|--------|
| P1 | PROP-3 — Promote Android to Production on Google Play | ~15 min manual | Ready |
| P2 | Issue #15 Phase 2 — CT4: AI-Generated Insights | ~1.5h | Not started — depends on trial flow |
| P2 | App Trial & Purchase Flow implementation | ~1.5h | Designed, not implemented |
| P3 | Restore streaming refactor — avoid loading full ZIP into memory (OOM on large backups) | ~2h | Known limitation, not blocking |
| P3 | Firebase / Cloud Sync | Large | All deps commented out in pubspec |
| P3 | Custom emoji images E-1/E-2 | N/A | Deferred |

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
| v1.1.0-beta.1+9 | fb79935 | Public beta: bilingual UI, legal docs, emoji jar fix, habit import/export, card preview |
| v1.1.0-beta.2+11 | 22776c8 | Adaptive icon, card fixes, font fill, feedback button, iOS xcassets fixes |
| v1.1.0-beta.3+18 | 7edfcef | DB v10 (source_template_id), template locale fix, EntryDetailScreen, ChorusService, 56 tests |
| v1.1.0-beta.4+19 | 4d4b51f | Calendar routine checklist simplified, restore progress dialog, 79 tests |
| v1.1.0-beta.4+19 | e1fbbd6 | PROP-4 card PNG cleanup, PROP-5 DB indexes v11, 93 tests, release notes |
| v1.1.0-beta.5+20 | d769c1b | PROP-6 trial API key (full stack): app UI + Cloudflare Worker backend; 94 tests |
| v1.1.0-beta.5+20 | 63981bb–83d8ad9 | PROP-9 daily checklist (8 commits): DB v12, list builder, carry-forward, one-per-day; 125 tests |
| v1.1.0-beta.5+20 | 2c3fd94 | List edit screen: checkbox + strikethrough consistency with Calendar |
| v1.1.0-beta.6+21 | 2026-05-01 | 9 UX issues: collapsible calendar, My Day rebrand, contextual FAB, Insights restructure (PROP-8), lock icon (PROP-7), future-date lock, landscape-safety, entry detail overflow fix |
| v1.1.0-beta.6+21 | 2026-05-03 | Carry-forward redesign (user-prompted dialog + "Yesterday" flag), past-date view-only, Insights crash fix, Moment icons, 3 post-launch polish items (#9, #10, #11) |
| v1.1.0-beta.6+21 | 2026-05-03 | iOS App Store submission complete; App Trial & Purchase Flow design doc; Insights tab Phase 1 implementation (hero stats, heatmap, mood donut, visual polish); 96/96 tests; restore streaming OOM limitation identified |
| v1.1.0-beta.6+21 | 2026-05-04 | Insights Phase 2 — CT1: Writing Stats (avg words, active day, peak hour); CT3: Tag-Mood Correlation (tag→mood score, min 3 entries); Hero card overflow fix (4th card clipped on iPhone); 5 new i18n keys; UAT 12/12 passed; 96/96 tests |
| v1.1.0-beta.7+22 | 2026-05-04 | Insights Phase 2 — CT2: Checklist Analytics (lists, completion, carry-forward, top item); Version bump; Android APK+AAB built; iOS pushed to TestFlight; UAT 8/8 passed; Git push to GitHub |
