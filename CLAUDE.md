# Blinking App — Claude Context

Personal memory/habit-tracking Flutter app (记忆闪烁). Path: `/Users/justinzero/ClaudeDev/blink/blinking_app`

## Quick Reference

- **Flutter SDK:** `^3.11.0` (currently 3.41.9 stable, Apr 29 2026)
- **macOS:** 26.2 (Tahoe beta) — Xcode 26.4.1 GM for production builds
- **Current version:** `1.2.0-dev` (v1.1.0+40 live on both stores; v1.2.0+41 target)
- **iOS App Store:** ✅ Live — [Blinking Notes](https://apps.apple.com/app/id6765900648) (Apple ID: 6765900648)
- **Google Play:** ✅ Live (1.1.0+40)
- **Android:** compileSdk 36 / targetSdk 36 (via Flutter SDK)
- **DB version:** 15 (`kSchemaVersion = 15` in `DatabaseService`)
- **Lint:** `flutter analyze --no-pub` (target: 0 errors)
- **Tests:** `flutter test` (558 tests, 556 passing, 2 pre-existing flaky)
- **Server config:** `https://blinkingchorus.com/api/config` — AI keys + model selection, updatable without app deploy
- **AI Model:** DeepSeek `deepseek-chat-v3-0324` primary, Gemini `gemini-2.0-flash-001` failover (both trial + pro, configurable via KV secrets at `/api/config`)
- **IAP Price:** $19.99 (non-consumable `blinking_pro`, entitlement `pro_access`)
- **Personas:** Kael (📝 Factual, default), Elara (🌿 Warm), Rush (⚡ Unfiltered), Marcus (⚔️ Stoic)
- **AI Keys:** Server-configurable via OpenRouter. Streaming enabled for perceived speed (0.6s first token)
- **Feedback email:** `blinkingfeedback@gmail.com`
- **Debug toggle:** Settings → About → tap version 5x to cycle preview/restricted

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
| `EntitlementService` | `ChangeNotifier` | State machine — preview/restricted/paid; 21d local preview, quota |
| `PurchasesService` | `ChangeNotifier` | RevenueCat IAP — init in main.dart, purchase/restore flow |
| `AiPersonaProvider` | `ChangeNotifier` | AI avatar, name, personality |
| `LlmConfigNotifier` | `ChangeNotifier` | Signals when LLM provider/api key changes |

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
- **SharedPreferences** for: theme, locale, LLM provider config (`llm_providers`, `llm_selected_index`), AI persona (`ai_assistant_name`, `ai_assistant_personality`, `ai_avatar_path`), entitlement (`entitlement_jwt`, `entitlement_state`, `entitlement_quota`, `entitlement_quota_date`, `entitlement_preview_started`, `entitlement_was_preview`), onboarding (`onboarding_completed`, `onboarding_done`), transition screen (`transition_screen_shown`)
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
| `lib/core/services/trial_service.dart` | 7-day trial token lifecycle (start, status, expiry) — **deprecated, superseded by EntitlementService** |
| `lib/core/services/entitlement_service.dart` | State machine — preview/restricted/paid; local offline preview fallback (21d, 3 AI/day); quota tracking |
| `lib/core/services/soft_prompt_service.dart` | Soft purchase prompts (days 18-20) + re-engagement triggers (1-per-7d guard) |
| `lib/core/services/purchases_service.dart` | RevenueCat IAP wrapper — purchase, restore, server validation |
| `lib/core/services/device_service.dart` | Anonymous device UUID for trial/entitlement identification |
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
| `lib/screens/settings/settings_screen.dart` | LLM config, tags, language, export, AI 个性化, Send Feedback. Contains debug toggle: 5-tap version text to cycle preview/restricted for IAP testing. |
| `lib/screens/onboarding/onboarding_screen.dart` | 3-screen first-launch flow — philosophy, features, the deal; language toggle on screen 1 |
| `lib/screens/onboarding/transition_screen.dart` | Day 21 transition — "Your 21 days are complete" |
| `lib/screens/purchase/paywall_screen.dart` | Pro purchase — $19.99 one-time, feature checklist |
| `lib/screens/settings/byok_setup_screen.dart` | 6-provider BYOK setup with ping validation |
| `lib/widgets/emoji_jar.dart` | `EmojiJarWidget` CustomPainter + AI bottom sheet |
| `lib/widgets/card_renderer.dart` | **Deleted** — replaced by `CardRenderService` |
| `lib/core/services/card_render_service.dart` | Off-screen PNG renderer with 4 layouts (hero_image/centered/left_aligned/two_column), 8 templates, 6 decorative motifs, auto-font sizing (96→9px binary search), overlay elements, re-render-on-restore |
| `lib/models/card_enums.dart` | `CardLayout`, `CardCornerStyle` enums with value/fromString extensions |
| `lib/widgets/card_template_picker.dart` | Horizontal scroll of 8 template thumbnails with locale-aware names (ZH/EN) and selection highlight |
| `lib/widgets/card_builder_sheet.dart` | `DraggableScrollableSheet` — template picker, content editor, AI Rewrite, toggle overlays, Save Keepsake flow. Injectable `renderFn` for testing. |
| `lib/screens/moment/card_preview_screen.dart` | Full-screen PNG preview with pinch-to-zoom, share, edit, re-render placeholder |
| `lib/widgets/floating_robot.dart` | Bobbing + pulse + wave-on-tap robot overlay (3 AnimationControllers); avatar = 🤖 emoji |
| `lib/widgets/floating_robot.dart` | Bobbing + pulse + wave-on-tap robot overlay (3 AnimationControllers); avatar = 🤖 emoji |
| `lib/widgets/entry_card.dart` | Entry display card with share button |

---

## IAP / RevenueCat Testing

### Debug Toggle
- Settings → About → tap version text **5x quickly** to cycle between `preview` and `restricted` modes
- Restricted mode + tap robot → paywall appears

### RevenueCat Test Store
- Key configured in `lib/main.dart` via `_rcTestApiKey` (default: `test_` key from Project Settings → API Keys)
- Test Store requires `purchases_flutter ≥ 9.8.0` (currently 9.16.1)
- Purchases show in RevenueCat → Customers → **Sandbox** tab
- Do NOT ship with Test Store key — use `--dart-define=RC_API_KEY=appl_/goog_` for production builds
- Full setup doc: `docs/plans/revenuecat-setup-actual.md`

### Entitlement Flow
- Fresh install → 21-day PREVIEW (3 AI/day, free)
- After preview or debug toggle → RESTRICTED → tap robot shows paywall
- Purchase `blinking_pro` → PAID → 1,200 AI/year
- `_applyLocalPreview()` respects pre-existing restricted/paid state (early return guard)

---

## Important Conventions

### Database Migrations
Always use sequential `if (oldVersion < N)` blocks in `DatabaseService.onUpgrade`. Never nest or use `else if`. `_onCreate` always creates the full v11 schema. `kSchemaVersion` at top of class defines the current target.

### Version Sync
When bumping `pubspec.yaml` version, also update `lib/core/config/constants.dart` `AppConstants.appVersion` (semver only, no build number) and the version subtitle in `settings_screen.dart`. A `test/core/version_test.dart` enforces this.

### Platform Version String Pattern
Android and iOS use different version strings due to Apple's restriction that `CFBundleShortVersionString` can only contain 3 integers (major.minor.patch):

| Platform | Source | Example | Notes |
|----------|--------|---------|-------|
| **Android** `versionName` | `pubspec.yaml` version name | `1.1.0-beta.7` | Full semver, hyphens allowed |
| **Android** `versionCode` | `pubspec.yaml` build number | `22` | Integer |
| **iOS** `CFBundleShortVersionString` | Manual in `ios/Runner/Info.plist` | `1.1.0` | Must be 3 integers only; Flutter's automatic conversion (`1.1.0.7`) is rejected |
| **iOS** `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` | `22` | Auto-injected from pubspec build number |

When bumping the pubspec version name (e.g. `1.1.0-beta.7` → `1.1.0-beta.8`), the iOS `CFBundleShortVersionString` only needs updating if the major.minor.patch portion changes. The build number (`CFBundleVersion`) ties both platform builds together.

### LLM Provider Config
Stored as JSON list in SharedPreferences key `llm_providers`. Use **merge-on-load** strategy in Settings: start from saved list (preserving API keys), then append any defaults not already present by name. Never discard saved providers on load.

### AI Persona Config
Stored in SharedPreferences: `ai_assistant_name` (default `'AI 助手'`) and `ai_assistant_personality` (default `''`). `AssistantScreen` reads these in `initState` and builds a dynamic `_systemPrompt` getter. Settings screen writes them on save.

### Stable IDs
`tag_synthesis` is hardcoded in `AssistantScreen._saveReflection()`. Do not rename or delete this tag ID.

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
`NoteCard` has four text fields in precedence order:
1. `cardContent: String?` — final text displayed on card (post-edit, v1.2.0)
2. `richContent: String?` — Quill Delta JSON (legacy, deprecated)
3. `aiSummary: String?` — plain text; AI-generated
4. First entry's `content` — fallback when neither field is set

### Card Templates (v1.2.0)
Eight built-in templates with Chinese aesthetic design (宁静 · 淡雅 · 含蓄): 墨韵 (Ink Rhythm), 素笺 (Plain Paper), 竹影 (Bamboo Shadow), 月色 (Moonlight), 青花 (Blue Porcelain), 茶语 (Tea Whisper), 朱砂 (Cinnabar Seal), 山水 (Landscape). All seeded via `StorageService._getDefaultTemplates()`. Template display names use `CardTemplate.displayNameFor(bool isZh)` with `nameEn` field — do not use `.name` directly in UI.

### Card Renderer (v1.2.0)
`CardRenderService` — static service for off-screen rendering. `buildPreviewWidget()` returns widget tree for preview. `renderToFile()` renders to 1080×1440 PNG via `RenderRepaintBoundary` + `PipelineOwner`. `captureFromKey()` captures from preview screen boundary. Auto-font sizing 96px→9px via binary search `TextPainter`. Photo integration: full-bleed (hero), hero header (two_column), inline thumbnail (left_aligned).

### Card Builder (v1.2.0)
`CardBuilderSheet` — open via `CardBuilderSheet.show(context, initialContent: ...)`. Accepts optional `renderFn` parameter for testing. On save: renders PNG → persists `NoteCard` via `CardProvider.addCard()`. Entry points: `EntryDetailScreen` (🖼️ icon in AppBar), `ReflectionSessionScreen` (post-save button), `AssistantScreen` (post-save icon in AppBar).

### Keepsake Badge (v1.2.0)
`_KeepsakeBadge` widget on `EntryDetailScreen` — watches `CardProvider` for card linked to current entry via `getCardByEntryId()`. Shows chip with template name. Tap → `CardPreviewScreen`. Hides when no card exists.

### Card Share (v1.2.0)
Always call `SharePlus.instance.share(ShareParams(files: [XFile(path)], sharePositionOrigin: ...))`. Rendered PNG at 1080×1440. The image contains all content.

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
| AI surfaces — Single-turn lens-based reflections (Surface B) | ✅ Done |
| AI surfaces — Mood Moment postures (Surface A) | ✅ Done |
| Lens system — Built-in 4 sets + custom, Settings UI | ✅ Done |
| No numeric quota language — All AI copy cleaned | ✅ Done |
| BYOK hidden — Config screens + menu removed | ✅ Done |
| Server-configurable AI keys — Cloudflare Worker endpoint | ✅ Done |
| Multi-key failover — Automatic rotation on rate-limit/auth failure | ✅ Done |
| Settings tab reorganization — AI/Tags/General tabs | ✅ Done |
| Insights AI branding removed — "💡 Insights · Based on your data" | ✅ Done |
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
| Insights tab Phase 1 — hero cards, heatmap, mood donut, visual polish | ✅ Done |
| Insights tab Phase 2 — CT1/CT2/CT3 | ✅ Done |
| CT4: AI-Generated Insights (LLM + rule-based fallback) | ✅ Done |
| EntitlementService (server-authoritative state machine, quotas) | ✅ Done |
| Floating robot entitlement-aware rewrite | ✅ Done |
| BYOK setup screen (6 providers, dropdown, ping validation) | ✅ Done (hidden) |
| Settings → AI entitlement banner (PREVIEW/RESTRICTED/BYOK states) | ✅ Done |
| Paywall screen ($19.99 Pro, feature checklist, in-app legal docs) | ✅ Done |
| Day 21 Transition screen | ✅ Done |
| M3 Onboarding — 3-screen first-launch flow | ✅ Done |
| Routine redesign — Build/Do/Reflect tabs | ✅ Done |
| RevenueCat Test Store verified | ✅ Done |
| iOS App Store Sandbox purchase verified | ✅ Done |
| iOS App Store production release (v1.1.0+36) | ✅ Done |
| Google Play purchase verified (refund + re-purchase tested) | ✅ Done |
| Google Play production release (v1.1.0+40) | ✅ Done |
| ALL previous features | ✅ Done |
| **Keepsake cards — Phase 3** (8 templates, single-page, photo+text, entry badge, re-render-on-restore, CardRenderService with 4 layouts + 6 decorative motifs, CardBuilderSheet, CardPreviewScreen, 3 entry points) | ✅ Done (May 23, 2026) |
| Restore streaming refactor — OOM on large backups | ✅ Done |
| `addCustomerInfoUpdateListener` in RevenueCat | ✅ Done |
| Platform version audit (Flutter 3.41.9, Xcode 26.4.1, SDK 36) | ✅ Done |
| Voice notification for routines (flutter_tts, global + per-routine toggle, DB v14) | ✅ Done |
| DEF-K-001: Content TextField accessibility identifier | ✅ Done |
| DEF-K-002: Save button Semantics blocking tap | ✅ Done |
| DEF-K-003: Edit button invalid context after Navigator.pop | ✅ Done |
| DEF-V-001: Voice toggle accessibility + persistence (7 iterations) | ✅ Done (v7 — `Semantics(onTap:)`) |
| Multi-photo crash: _MediaGridState stale _pathFutures | ✅ Done |
| AI Rewrite button: wired LlmService.complete() | ✅ Done |
| Double-nested MergeSemantics removed from all SwitchListTile wrappers | ✅ Done |
| Playbook: 7-phase Feature Development Playbook (50+ lessons, 30 pitfalls) | ✅ Done |

### Pending
| Priority | Item | Effort | Status |
|----------|------|--------|--------|
| P1 | Ship Keepsake cards in next release (v1.2.0+41) | ~1h | Code complete, needs build + UAT |
| P1 | Write 10 Maestro UAT flows for Keepsake | ~2-3h | Not started |
| P1 | Manual visual QA on real devices (8 cases) | ~1h | Not started |
| P2 | Personas web page at blinkingchorus.com/personas | ~2h | Not started |
| P2 | Habit template browse/import UI (separate from full backup) | ~2h | Not started |
| P2 | Marketing plan (launch strategy, ASO) | TBD | Not started |
| P3 | Firebase / Cloud Sync | Large | All deps commented out |
| P3 | Card History screen (grid) | ~3h | Deferred to v1.2.1 |
| P3 | XHS Export mode (multi-page, ratio toggle, page breaks) | ~1 week | Deferred to v1.3.0 |
| P3 | Custom template saving | ~2 days | Deferred to v1.3.0 |
| — | Voice notification — background TTS | ~4h | Deferred to v1.3.0 |

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
| v1.1.0-beta.7+22 | 2026-05-04 | Insights Phase 2: CT1 Writing Stats + CT3 Tag-Mood + CT2 Checklist + CT4 AI Insights. M1 Foundation: EntitlementService + floating robot rewrite + Settings AI banner + BYOK (6 providers). M2 Purchase: Paywall + Day 21 Transition screen. Server: entitlement endpoints (init/status/chat) + receipt validation (purchase/restore) + JWT + D1 tables. IAP: RevenueCat SDK + PurchasesService. ~20 i18n keys. 96/96 client tests, 352/352 server tests. Full session summary at `docs/session-summary-2026-05-04.md` |
| v1.1.0-beta.7+22 | 2026-05-05 | Image compression (pick/save/export, 1920px q85). Media-exclude toggle (text-only ~200 KB). Persona backup/restore fix (reload before pop + error handling). Offline local preview (21d, 3 AI/day). M3 Onboarding: 3-screen first-launch flow + soft prompts + re-engagement. Routine redesign: Build/Do/Reflect tabs (P0–P3), streak grace period, habit summary cards, periodic summary. Settings AI cleanup. System locale detection. Seed data (entries + routines with streaks). 106/106 tests. Session summary at `docs/session-summary-2026-05-05.md` |
| v1.1.0+29 | 2026-05-09 | iOS TestFlight push build 29. 147/147 tests. Updated App Store Connect API key (4UK6U499RC). |
| v1.1.0+30 | 2026-05-09 | iOS TestFlight push build 30. 147/147 tests. New App Store Connect API key (4UK6U499RC) replacing expired 6S889FNN6R. Session summary at `docs/session-summary-2026-05-09.md`. |
| v1.1.0+35 | 2026-05-13 | iOS App Store submission (production). 440/440 tests. Persona defaults refined, locale fixes. |
| v1.1.0+36 | e5fb97f | Production: persona defaults (Kael), 31 seed routines, 9 category PNG icons, tags refresh, notifications, locale fixes, IAP audit, device identity. |
| v1.1.0+38 | f48a2a3 | Multi-custom persona, private AI filter (5 surfaces), locale fixes, notifications working, 440 tests. |
| v1.1.0+39 | 6f459e3 | Persona-specific lens mapping, stale defaults sync, iPad backup doc, 454 tests. |
| v1.1.0+40 | 6fbe6ea | iPad share sheet + backup black screen fix. Production release on both stores. 454 tests. |
| v1.2.0-dev | f5ad852 | Phase 3 Day 9-10: DB migration v15, NoteCard/CardTemplate model updates, 8 seed templates (墨韵–山水), CardLayout enums, CardProvider registered in app.dart. |
| v1.2.0-dev | 2ad6915 | Phase 3 Day 9-10 tests: card_migration (7 tests), card_provider (11 tests), UAT automation catalog. |
| v1.2.0-dev | ef3ac92 | Phase 3 Day 11-12: CardRenderService — 4 layouts, 8 templates, 6 decorative motifs, auto-font sizing, photo integration, re-render-on-restore. |
| v1.2.0-dev | 97fd8c7 | Phase 3 Day 13-14: CardTemplatePicker, CardBuilderSheet UI — template picker, content editor, AI Rewrite, toggle overlays, Save Keepsake. |
| v1.2.0-dev | 8d38cc2 | Phase 3 Day 13-14 tests: CardBuilderSheet widget tests (8 cases — open, edit, save flow, locales, toggles). |
| v1.2.0-dev | c09c08c | Phase 3 Day 15-16: CardPreviewScreen (pinch-zoom, share, edit, re-render placeholder), keepsake badge on EntryDetailScreen, 3 entry points (EntryDetail, ReflectionSession, Assistant). |
| v1.2.0-dev | 7030132 | Phase 3 integration tests: full-flow keepsake lifecycle (9 cases — create, edit, re-render, multi-card, delete, template lookup, provider reload). |
| v1.2.0-dev | 487a6db | Phase 3 UAT master document: 30 test cases (22 Maestro-automatable, 8 manual). |
| v1.2.0-dev | 5cb8d7b | Session summary + lessons learned (10 topics) + CLAUDE.md update (version 1.2.0-dev, DB v15, 556→558 tests). |
| v1.2.0-dev | 4275bf2 | Feature Development Playbook — 5 phases, quick-reference pitfalls. |
| v1.2.0-dev | 52b8c2e | Playbook expanded: 7 phases, 50+ lessons from all sessions, 30 pitfalls, 3 categories. |
| v1.2.0-dev | da93875 | Playbook Phase 0.1: Requirement Analysis & Competitive Research. |
| v1.2.0-dev | 88843ca | DEF: Save button accessibility + gesture arena — moved outside DraggableScrollableSheet. |
| v1.2.0-dev | bcb5dc9 | DEF: Save crash — lifecycle assertion in _renderOffscreen (OverlayEntry approach). |
| v1.2.0-dev | 746ea91 | DEF-K-001/002/003 + DEF-V-001 v1 — content TF identifier, save button tap, voice state. |
| v1.2.0-dev | 97ba984 | DEF-K-003: Edit button uses invalid context after Navigator.pop (result-driven fix). |
| v1.2.0-dev | 4b4d1e5 | DEF: Multi-photo crash (_MediaGridState stale _pathFutures), AI Rewrite wired (LlmService). |
| v1.2.0-dev | 494e140 | DEF-V-001 v2: voice toggle reads cached SharedPreferences on every build. |
| v1.2.0-dev | 7675ef7 | DEF-V-001 v3: restore Semantics identifier + _voiceLoaded guard. |
| v1.2.0-dev | 506c33d | DEF-V-001 v4: ValueNotifier as single source of truth for voice toggle. |
| v1.2.0-dev | d71e889 | DEF-V-001 v5: remove double-nested MergeSemantics blocking toggle tap. |
| v1.2.0-dev | d86f70c | DEF-V-001 v6: SwitchListTile → ListTile+Switch with identifier on Switch. |
| v1.2.0-dev | 9b871ef | DEF-V-001 v7: add onTap to Semantics wrapper on Switch (fixes XCUITest accessibility). |
| v1.2.0-dev | 29d60ad | Semantics regression guard test — onTap required on Switch identifier wrapper. |
