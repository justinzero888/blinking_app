# Blinking App — Claude Context

Personal memory/habit-tracking Flutter app (记忆闪烁). Path: `/Users/justinzero/ClaudeDev/blink/blinking_app`

## Quick Reference

- **Flutter SDK:** `^3.11.0` (currently 3.41.8 stable, Apr 24 2026)
- **macOS:** 26.2 (Tahoe beta) — requires Xcode 26, managed in `ClaudeDev/system-upgrade`
- **Current version:** `1.1.0-beta.5+20` (pubspec.yaml)
- **DB version:** 11 (`kSchemaVersion = 11` in `DatabaseService`)
- **Build AAB:** `flutter build appbundle --release`
- **Build APK:** `flutter build apk --release`
- **Lint:** `flutter analyze --no-pub` (target: 0 errors)
- **Tests:** `flutter test` (94 tests, all passing)
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
Calendar | Moment | Routine | 珍藏 | Settings
```
- `FloatingRobotWidget` overlay (bobbing + pulsing 🤖, wave-on-tap) → `AssistantScreen` modal
- `FloatingActionButton` (heroTag: `'main_add_entry_fab'`) → `AddEntryScreen`

### Storage Layers
- **SQLite** via `DatabaseService` singleton (accessed through `StorageService`)
  - DB version 11; migration blocks: `< 2` (entries/routines), `< 3` (emotion/category), `< 4` (card tables), `< 5` (routine scheduling), `< 6` (template image + card AI summary), `< 7` (card rich content), `< 8` (routine `icon_image_path`), `< 9` (template `custom_image_path`), `< 10` (template `source_template_id`), `< 11` (indexes on `entry_tags(entry_id)` + `note_card_entries(card_id)`)
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
| `lib/screens/cherished/cherished_memory_screen.dart` | 3-tab shell: 书架 / 卡片 / 总结 |
| `lib/screens/cherished/shelf_tab.dart` | Yearly jar cards → `YearJarDetailScreen` |
| `lib/screens/cherished/cards_tab.dart` | Card grid + folder filter; tap → `CardEditorScreen`; long-press → Edit/Share/Delete; FAB heroTag: `'cards_tab_new_card_fab'` |
| `lib/screens/cherished/card_builder_dialog.dart` | Create card; AI merge (≤100 words); template editor sheet |
| `lib/screens/cherished/card_editor_screen.dart` | flutter_quill rich text editor; word counter (X/100); image insert; save navigates to `CardPreviewScreen` |
| `lib/screens/cherished/card_preview_screen.dart` | PNG preview of rendered card; Share (image-only) + Save actions |
| `lib/screens/cherished/summary_tab.dart` | fl_chart visualizations (scope: 日/周/月) |
| `lib/screens/chorus/post_to_chorus_sheet.dart` | Bottom sheet for posting entries to Chorus social platform |
| `lib/screens/settings/settings_screen.dart` | LLM config, tags, language, export, AI 个性化, Send Feedback |
| `lib/widgets/emoji_jar.dart` | `EmojiJarWidget` CustomPainter + AI bottom sheet |
| `lib/widgets/card_renderer.dart` | Off-screen PNG render; `_autoFontSize()` 96px→9px; text area = height×0.8/width×0.88; custom bg image with rounded clip |
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

---

## Feature Status & Pending Work

### Completed
| Feature | Status |
|---------|--------|
| AI assistant (multi-turn LLM chat + Save Reflection) | ✅ Done |
| AI Secrets tag (exclude private notes from AI context) | ✅ Done |
| Bilingual UI (EN/ZH) | ✅ Done |
| Backup/Restore (ZIP + JSON) with progress bars | ✅ Done |
| Card share (PNG export) | ✅ Done |
| Chorus social posting (publish to blinkingchorus.com) | ✅ Done |
| Entry detail read-only view with share + Post to Chorus | ✅ Done |
| Habit import/export (JSON) | ✅ Done |
| Legal docs (Privacy Policy + ToS) | ✅ Done |
| Note cards + rich editor (flutter_quill, 100-word limit) | ✅ Done |
| Card PNG cleanup (orphan file deletion on card/folder/template delete) | ✅ Done (PROP-4) |
| DB indexes v11 (`entry_tags(entry_id)` + `note_card_entries(card_id)`) | ✅ Done (PROP-5) |
| Onboarding banner (Calendar, one-time dismissible) | ✅ Done |
| Trial API key flow (7-day free trial, app + backend) | ✅ Done (PROP-6) |
| UX polish M1–M7, P1-1–P1-10, P2 items | ✅ Done |

### Pending
| Priority | Item | Effort | Status |
|----------|------|--------|--------|
| P1 | PROP-3 — Promote Android to Production on Google Play | ~15 min manual | Ready — monitor beta soak |
| P2 | PROP-6 — Trial API key flow (7-day free trial) | ✅ Done | App + backend deployed 2026-04-30; plans in `docs/plans/2026-04-30-prop-6-trial-api-key-plan.md`
| P2 | PROP-9 — Daily Checklist Entry (ad-hoc daily lists) | ~18h | Revised design + plan in `docs/plans/2026-04-30-prop-9-daily-checklist-plan.md`; ship in v1.1.1 if v1.1.0 is tight |
| P3 | PROP-7 — AI Secrets lock icon on entries | ~1h | UX polish |
| P3 | PROP-8 — Keepsakes tab rename (deferred post-beta) | ~30 min | Wait for beta feedback |
| P3 | Firebase / Cloud Sync | Large | All deps commented out in pubspec |
| P3 | Card generation AI multi-design suggestions | Unknown | Deferred from v1.1.0 beta |
| P3 | Custom emoji images E-1/E-2 | Unknown | Deferred from v1.1.0 beta |
| P3 | iOS release (Xcode 26 upgrade, App Store submission) | Moved | Managed in separate project: `ClaudeDev/system-upgrade` |

### Launch Roadmap (Target: end of May 2026)

| Week | Window | Focus |
|------|--------|-------|
| 1–2 | May 1–14 | PROP-6 backend + app-side build, alpha test |
| 3 | May 15–21 | PROP-9 (stretch goal) + PROP-7/PROP-8 polish |
| 4 | May 22–30 | Launch readiness: Play Store listing, beta crash triage, smoke tests, version bump, release build |

**Critical path:** PROP-6 must ship with production launch (removes #1 onboarding barrier). PROP-9 is a stretch goal — ship in v1.1.1 if Week 3 runs over. Backend for PROP-6 is the only external dependency; start immediately.

**iOS release work** (Xcode 26 upgrade, toolchain migration, App Store submission) has been moved to a separate management project at `/Users/justinzero/ClaudeDev/system-upgrade`. The plan document `docs/plans/2026-04-28-infrastructure-upgrade-ios-release.md` is superseded by the new project's planning.

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
| v1.1.0-beta.5+20 | (pending) | PROP-6 trial API key (full stack): app UI + Cloudflare Worker backend; 94 tests |
| v1.1.0-beta.4+19 | (this session) | Flutter 3.41.2→3.41.8 upgrade (unblocks Xcode 26); iOS pipeline plan updated; iOS release moved to ClaudeDev/system-upgrade |
