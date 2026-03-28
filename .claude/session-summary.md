# Session Summary — 2026-03-28

## Completed Tasks

### Phase 1 — Habit system overhaul (v1.0.4 · 78d2c7b) ✅ TESTED
- Extended `RoutineFrequency`: `daily | weekly | scheduled | adhoc`
- Added `scheduledDaysOfWeek: List<int>?` and `scheduledDate: DateTime?` to `Routine` model
- DB v4→v5: routine scheduling columns
- `getRoutinesForDate(DateTime)` replaces `getActiveRoutinesForToday()`
- `isMissedOn(Routine, DateTime)` pure derivation (no DB column)
- `RoutineScreen` rewrite: 3-tab (全部 / 今日 / 记录), new add/edit dialog
- `CalendarWidget.dayHabitStatus` — mini `LinearProgressIndicator` per cell
- `HomeScreen`: completed habits → single green ✓ icon row; past pending → single red ✗ icon row

### Phase 2–4 — Card enhancements, sharing, AI personalization (v1.0.5 · 7bb251c) ✅ TESTED
- `CardTemplate.customImagePath` — user-uploaded background
- `NoteCard.aiSummary` — AI-generated display text (originals preserved)
- DB v5→v6: `custom_image_path` on templates, `ai_summary` on note_cards
- `CardBuilderDialog`: edit mode, AI merge toggle, `_TemplateEditorSheet`
- `CardProvider.updateCard()`, `copyBuiltInTemplate()`
- `CardsTab`: long-press → Edit/Share/Delete menu
- `EntryCard` share button; card share PNG via `share_plus`
- Settings "AI 个性化": name + personality → SharedPreferences
- `AssistantScreen` dynamic system prompt; AppBar shows custom name
- `FloatingRobotWidget`: pulse idle + wave-on-tap (3 `AnimationController`s)

### Bug fixes (deaaa89) ✅
- **DB migration bug**: `ai_summary`/`custom_image_path` were missing for users upgrading from v5. Fixed by bumping to v6 with correct `< 6` block
- **Card tap**: Added `onTap` → `_viewCard()` dialog with `_CardFullView`
- **Image upload hang**: Added `READ_MEDIA_IMAGES` + `READ_EXTERNAL_STORAGE` to `AndroidManifest.xml`

### Rich card editor (v1.0.6 · ddf89d5 + 85f8dbf) ✅ TESTED
- `NoteCard.richContent: String?` — Quill Delta JSON; DB v6→v7
- `CardEditorScreen`: full-screen flutter_quill editor; word counter (X/100); image insert
- `CardRenderer._extractPlainText()`: `richContent > aiSummary > entry.content`
- `FlutterQuillLocalizations.delegate` added to `app.dart`

### v1.1.0 Beta features (beta-2026-03-21 branch → merged to master) ✅
- Removed video/audio entry attachments
- Legal docs: Privacy Policy + Terms of Service (bilingual)
- Full bilingual UI (English/Chinese) across all screens
- Emoji jar fixes + AI bottom sheet
- Habit import/export (JSON)
- `CardPreviewScreen`: PNG preview with Share + Save
- UX polish phases 1–3: missed habit icon (grey circle), micro-polish M1–M7
- AI persona included in ZIP backup/restore

### v1.1.0-beta.2 — Current release ✅ SHIPPED (build +11)
- **Android adaptive app icon**: fills full circle like system icons; foreground PNG + `#0D3B34` background
- **Card template names**: locale-aware via `CardTemplate.displayNameFor(bool isZh)`
- **Card custom image**: `renderToImage()` now draws custom background image with rounded clip + 25% overlay
- **Font auto-size**: `_autoFontSize()` helper (96px→9px); text area = height×0.8 / width×0.88; shared between widget and PNG
- **Share card**: image-only (removed `text:` param from all `Share.shareXFiles()` calls)
- **Send Feedback button**: Settings → About section; `mailto:blinkingfeedback@gmail.com`; pre-filled subject/body; bilingual; try/catch `launchUrl` pattern
- **FAB hero tag conflict** fixed: unique `heroTag` on main FAB and cards tab FAB
- **iOS Podfile**: post_install hook removes all `DK*` pod xcassets (fixes `AssetCatalogSimulatorAgent` for DK pods)
- **iOS legacy icons**: removed pre-iOS 7 sizes (57x57, 50x50, 72x72) from `Contents.json`
- **iOS Debug.xcconfig**: `ENABLE_ONLY_ACTIVE_RESOURCES = NO` + `ASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT = YES`
- **AppConstants.appVersion** synced to `1.1.0-beta.2`
- **44/44 tests passing**
- Merged beta branch → master; pushed to GitHub (`22776c8`)
- Built and uploaded AAB (build +11) to Google Play Internal Testing

---

## Pending Items

| Priority | Item | Notes |
|----------|------|-------|
| P2 | Dedicated entry detail / read-only view | `AddEntryScreen` reused for editing via onTap |
| P3 | Firebase / Cloud Sync | Deps commented out in pubspec |
| P3 | Card generation AI multi-design suggestions | Deferred from v1.1.0 beta |
| P3 | Custom emoji images E-1/E-2 | Deferred from v1.1.0 beta |
| BLOCKED | iOS Simulator | macOS 26 Tahoe beta + Xcode 16.2 incompatibility — `AssetCatalogSimulatorAgent` spawn fails at OS level; fix requires Xcode update or real device testing |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `AppProvider` deleted | Dead code; caused data inconsistency risk |
| DB sequential `if (oldVersion < N)` blocks | Handles all upgrade paths without branching |
| LLM config: merge-on-load | Preserves user API keys across app updates |
| `tag_reflection` id is stable | Hardcoded in `AssistantScreen._saveReflection()` |
| `richContent` + `aiSummary` both saved | `richContent` = canonical Delta JSON; `aiSummary` = plain-text mirror for thumbnails and backwards compat |
| Built-in template → copy-on-write | `copyBuiltInTemplate()` creates `isBuiltIn: false` copy |
| `note_card_entries` immutable | Original diary entries never altered by card operations |
| `FlutterQuillLocalizations.delegate` in `app.dart` | Must be in `MaterialApp.localizationsDelegates`; spread pattern preserves existing delegates |
| Word count = CJK chars + English tokens | Mixed-language fairness |
| Floating robot reverted to 🤖 emoji | Custom AI avatar image inconsistent; emoji is universal |
| Card share: image-only | Sending text + image was redundant; image contains all content |
| Feedback: mailto: in Settings | No backend needed; testers know email; zero new dependencies |
| `launchUrl` try/catch over `canLaunchUrl` | `canLaunchUrl` unreliable for `mailto:` on iOS 14+; try/catch is idiomatic |
| `clearCustomImage: bool` param on `copyWith()` | Dart `??` operator prevents nulling nullable fields without explicit flag |

---

## DB Version History

| Version | Block | Changes |
|---------|-------|---------|
| 1 | initial | entries, routines, tags, completions |
| 2 | `< 2` | entries.metadata_json, routines.description |
| 3 | `< 3` | entries.emotion, routines.category |
| 4 | `< 4` | card_folders, templates, note_cards, note_card_entries tables |
| 5 | `< 5` | routines.scheduled_days_of_week, routines.scheduled_date |
| 6 | `< 6` | templates.custom_image_path, note_cards.ai_summary |
| 7 | `< 7` | note_cards.rich_content |
| 8 | `< 8` | routines.icon_image_path |

---

## Build Artifacts

| Version | Commit | What |
|---------|--------|------|
| v1.0.4 | 78d2c7b | Phase 1 habit overhaul |
| v1.0.5 | 7bb251c | Phases 2–4 card/share/AI persona |
| v1.0.6 | ddf89d5 | Rich card editor + bug fixes |
| v1.1.0-beta.1+9 | fb79935 | Public beta — bilingual, legal, habits, card preview |
| v1.1.0-beta.2+11 | 22776c8 | Adaptive icon, card fixes, font fill, feedback button |

---

## Feedback Email
`blinkingfeedback@gmail.com` — created 2026-03-27 for tester feedback collection
