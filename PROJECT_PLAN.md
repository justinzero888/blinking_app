# Blinking App (记忆闪烁) - Project Plan

## App Overview
- **Name**: Blinking (记忆闪烁)
- **Type**: Personal memory capture app
- **Framework**: Flutter
- **Platforms**: Android + iOS (both live)
- **Current Version**: 1.1.0-beta.7+22

## Goals
- Capture memories: text, audio, video, image
- Track daily routines
- AI-powered summaries and reminders
- Local + cloud sync
- Multi-language (Chinese/English)

## Project Status

### Completed Screens
| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 1 | Home/Calendar | Monthly calendar + today's overview | Working |
| 2 | Moment/Timeline | Entries grouped by date, search + tag/date filter | Working |
| 3 | Add/Edit Entry | Create or edit memory (text/image) | Working |
| 4 | Routines | Daily habits tracking with completions | Working |
| 5 | Cherished / Cards | Note cards with templates, folders, AI merge, rich editor | Working |
| 6 | Cherished / Shelf | Yearly emotion jars | Working |
| 7 | Cherished / Summary | Chart metrics (daily/weekly/monthly) | Working |
| 8 | Settings | Tags, language, LLM config, AI persona, export/import | Working |
| 9 | AI Assistant | Multi-turn LLM chat with Save Reflection | Working |
| 10 | Entry Detail | Read-only entry view with share + Post to Chorus | Working |

### Completed Features (beyond screens)
| # | Item | Status |
|---|------|--------|
| 1 | AI assistant (multi-turn LLM chat + Save Reflection) | Done |
| 2 | AI Secrets tag (exclude private notes from AI context) | Done |
| 3 | Bilingual UI (EN/ZH) | Done |
| 4 | Backup/Restore (ZIP + JSON) with progress bars | Done |
| 5 | Chorus social posting (publish to blinkingchorus.com) | Done |
| 6 | Habit import/export (JSON) | Done |
| 7 | Legal docs (Privacy Policy + ToS) | Done |
| 8 | Card PNG cleanup (PROP-4) | Done |
| 9 | DB indexes v11 (PROP-5) | Done |
| 10 | Onboarding banner | Done |
| 11 | 7-Day Trial API key flow — full stack (PROP-6) | Done |
| 12 | Daily Checklist Entry — ad-hoc list with carry-forward (PROP-9) | Done |
| 13 | Calendar future date lock (Issue #1) | Done |
| 14 | Keepsakes → Insights restructure (PROP-8) | Done |
| 15 | AI Secrets lock icon on entries (PROP-7 / Issue #4) | Done |
| 16 | Contextual FAB — per-tab icon + action (Issue #7) | Done |
| 17 | HomeScreen "Calendar" → "My Day" (Issue #14) | Done |
 | 18 | Collapsible calendar — week strip, landscape-safe (Issue #13) | Done |
| 19 | Carry-forward redesign — user-prompted + "Yesterday" flag (TC-11) | Done |
 | 20 | Insights tab crash fix — empty tags guard | Done |
| 21 | Moment tab icon differentiation — note vs checklist vs routine | Done |
| 22 | Post-launch polish batch — Issues #9, #10, #11 | Done |
| 23 | Post-launch polish disposition — Issues #7 (rejected), #8/#12 (design doc) | Done |
| 24 | iOS App Store submission | Done |
| 25 | Insights Phase 1 — hero stats row overflow fix (4th card clipped) | Done |
| 26 | Insights Phase 2 — CT1: Writing Stats (avg words, active day, peak hour) | Done |
| 27 | Insights Phase 2 — CT3: Tag-Mood Correlation (tag → mood score, min 3 entries) | Done |
| 28 | Insights Phase 2 — CT2: Checklist Analytics (lists, completion rate, carry-forward, top item) | Done |

### Remaining / Blocked
| # | Item | Status |
|---|------|--------|
| 1 | Firebase / Cloud Sync | Not started — deps commented out |
| 2 | Custom emoji images E-1/E-2 | Deferred |
| 3 | **PROP-3: Promote Android to Production on Google Play** | ~15 min manual — launch-ready |
| 4 | App Trial & Purchase Flow — implementation (Issues #8, #12) | Designed, not implemented |
| 5 | **Issue #15: Insights Phase 2 — CT4: AI-Generated Insights** | ~1.5h remaining — depends on trial flow |

## Technical Architecture

### Folder Structure
```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration + provider tree
├── core/                  # Core modules
│   ├── config/            # Theme, constants
│   ├── services/          # Storage, export, file, LLM, Chorus
│   └── utils/             # Helpers
├── l10n/                  # Localization (zh/en .arb files)
├── models/                # Entry, Tag, Routine, CardTemplate, CardFolder, NoteCard
├── providers/             # EntryProvider, TagProvider, RoutineProvider,
│                          # LocaleProvider, ThemeProvider, CardProvider,
│                          # JarProvider, SummaryProvider, RoutineProvider
├── screens/               # UI screens
│   ├── cherished/         # Cards, shelf, summary, card editor/preview/builder
│   ├── chorus/            # PostToChorusSheet
│   ├── moment/            # Timeline, entry detail
│   ├── routine/           # Routine screen
│   ├── settings/          # Settings screen
│   └── assistant/         # AI assistant chat
└── widgets/               # EmojiJarWidget, CardRenderer, FloatingRobotWidget, etc.
```

### Database Schema (v12)
| Table | Key Fields |
|-------|-----------|
| `entries` | id, type, content, tagIds, emotion, createdAt |
| `routines` | id, name, frequency, scheduledDaysOfWeek, scheduledDate, reminderTime |
| `completions` | id, routineId, date |
| `tags` | id, name, nameEn, color |
| `templates` | id, name, icon, fontColor, bgColor, isBuiltIn, customImagePath, **source_template_id** |
| `card_folders` | id, name, isDefault |
| `note_cards` | id, folderId, templateId, content, richContent, aiSummary, renderedImagePath |
| `note_card_entries` | cardId, entryId |

## Launch Roadmap

See **[Blinking Launch Plan](docs/plans/blinking-launch-plan-2026-05-02.md)** for the full timeline including competitive analysis, pricing strategy, and marketing plan.

| Week | Window | Focus |
|------|--------|-------|
| 1–2 | May 1–14 | ✅ All P1/P2 UX issues. ✅ PROP-6. ✅ PROP-9. ✅ PROP-8. ✅ iOS App Store submission. ✅ Carry-forward redesign. ✅ Insights crash fix. |
| 3 | May 15–21 | **Android launch:** smoke tests → version bump → 1.1.0 → Play Store production (PROP-3) |
| 4 | May 22–30 | **Monitor:** crash reports, reviews, trial usage. v1.1.1: Insights tab enhancement (Issue #15), trial/purchase flow. |

## Development History

### v1.1.0-beta.6+21 — 2026-05-04 (Insights Phase 2: CT1 + CT3)

### v1.1.0-beta.7+22 — 2026-05-04 (Insights Phase 2: CT2 + Version Bump)
- **CT2 — Checklist Analytics:** New section between Trends and Tag Impact. 4 stats: total lists, avg completion rate, items carried forward, most common item. `_ChecklistInsightsSection` + `_ChecklistStatRow` + `_ChecklistInsightsEmpty` widgets. New computed props: `totalLists`, `checklistCompletionRate`, `totalCarriedForward`, `topChecklistItem`.
- **Version bump:** `1.1.0-beta.6+21` → `1.1.0-beta.7+22`. Android APK + AAB built. iOS build pushed to TestFlight.
- **5 new i18n keys** (EN/ZH): `insightsChecklistSection`, `insightsListsCreated`, `insightsAvgCompletion`, `insightsItemsCarried`, `insightsTopItem`.
- **UAT:** 8/8 test cases passed on both iOS and Android.
- **Git commit:** All changes committed and pushed to GitHub.
- **Tests:** 96/96 passing. **Lint:** 0 new errors.

### v1.1.0-beta.6+21 — 2026-05-04 (Insights Phase 2: CT1 + CT3)
- **CT1 — Writing Stats:** New section between heatmap and mood donut. 3 mini stat cards: avg words/entry (CJK+EN word counting), most active weekday, peak writing hour. `_WritingStatsSection` + `_MiniStatCard` widgets. New computed props: `averageEntryLength`, `mostActiveDayOfWeek`, `mostActiveHour`.
- **CT3 — Tag-Mood Correlation:** New section between trends and mood jars. Shows top 5 tags with highest avg mood score (min 3 entries). Colored bar + emoji + score per tag. New computed prop: `tagMoodCorrelation`. `_TagMoodSection` + `_TagMoodEmpty` widgets.
- **Bug fix:** Hero stats row overflow on iPhone — 4th card was clipped. Fixed with `Expanded` + `LayoutBuilder` responsive layout.
- **5 new i18n keys** (EN/ZH): `insightsWritingStats`, `insightsAvgWords`, `insightsMostActiveDay`, `insightsTagImpact`, `insightsTagImpactFootnote`.
- **UAT:** 12/12 test cases passed on both iOS and Android.
- **Tests:** 96/96 passing. **Lint:** 0 new errors.
- **Files:** `summary_provider.dart`, `cherished_memory_screen.dart`, `app_en.arb`, `app_zh.arb`

### v1.1.0-beta.6+21 — 2026-05-03 (Post-Launch UX Polish Batch + Insight Tab Design)
- **Issue #10 — Removed carry-forward auto-banner:** Dead code cleanup: `_lastCarriedCount`, `clearCarriedBanner()`, `carriedOverCount` param from `EntryCard`, `_buildCarriedOverBanner()` widget, `_buildListEntryCards()` method. Banner became redundant after explicit user-prompted carry-forward dialog + "Yesterday" labels.
- **Issue #9 — One-list-per-day transition UX:** When toggling Note→List and a list already exists, a snackbar ("Today's list already exists — opening it") appears before a 300ms fade transition to the existing list. New i18n key `listAlreadyExistsHint`.
- **Issue #11 — List checkbox UX consistency:** Helper text on list edit screen ("Tap to check · Drag to reorder · × to remove"), drag handle enlarged 20→24px, EntryDetailScreen subtitle "Checklist · X/Y done". New i18n keys `listEditHint`, `listDetailSubtitle`.
- **Issue #7 — Calendar list badge:** Rejected (too crowded — calendar already has emotion + habit dots).
- **Issues #8, #12 — App Trial & Purchase Flow:** Moved to new design doc `docs/plans/2026-05-03-trial-purchase-flow-design.md`.
- **Bug reports:** 10/14 resolved, 1 rejected, 2 moved to dedicated design plan. No blocking UX items remain.
- **Issue #15 — Enhance Insights tab UI:** Design doc created at `docs/plans/2026-05-03-insights-tab-enhancement.md`. Competitive benchmark (Daylio, Reflectly, Streaks, Day One, HabitNow). Proposed: hero stats cards, calendar heatmap, mood distribution donut, writing stats, checklist analytics, tag-mood correlation, AI-generated insights. ~6.5h total, no DB changes.
- **Tests:** 96/96 passing.

### v1.1.0-beta.6+21 — 2026-05-03 (Carry-Forward Redesign + Bug Fixes)
- **TC-11 carry-forward simplification:** Past-date entries now view-only
  - `EntryCard._buildListItem()` — no tap toggle for entries from previous dates
  - `HomeScreen._onEntryTapped()` — routes past entries to `EntryDetailScreen` instead of `AddEntryScreen`
  - `EntryDetailScreen` — edit button hidden for past entries, list checkboxes non-interactive
  - `AddEntryScreen` — save guard blocks editing past-date entries; past entries show "View Memory" read-only mode
- **TC-11 carry-forward redesign:** Replaced auto carry-forward with explicit user-prompted flow
  - `ListItem.fromPreviousDay` field — flags items carried over from yesterday
  - `EntryRepository` — removed `checkAndCarryForward()`; added `getYesterdayListEntry()`, `getUncheckedItems()`, `createTodayListWithItems()`, `hasTodayList()`
  - `EntryProvider` — removed auto carry-forward from `loadEntries()`; added `getCarryForwardPreview()`, `carryForwardItems()`
  - `HomeScreen` — shows `AlertDialog` on first app open each day asking user to carry forward unchecked items
  - "Yesterday" label (`fromYesterdayLabel`) shown on carried items in `EntryCard`, `EntryDetailScreen`, `AddEntryScreen`
  - 5 new i18n strings (EN/ZH): dialog title, message, Yes/No, from-yesterday label
  - Prompt tracked per-day via `SharedPreferences` (`carry_forward_dialog_YYYY_M_D`)
- **Bug fix:** `_TopTagsChart` crash when `tagProvider.tags` empty — added `|| tagProvider.tags.isEmpty` guard
- **Moment tab:** Entry icons now differentiate note (`Icons.note`) vs checklist (`Icons.checklist`) vs routine (`Icons.check_circle`)
- **iOS App Store submission complete** — both platforms now use same Flutter codebase
- **Tests:** 96/96 passing
- **Files:** 11 modified, tests updated

### v1.1.0-beta.6+21 — 2026-05-01 (UX Batch Resolution)
- **9 UX issues resolved in one session:**
  - Issue #1: Calendar future dates locked (35% opacity, non-tappable, today+2 nav limit)
  - Issue #2/#7: Contextual FAB (per-tab icon + action: My Day/Moments = "+", Routine = playlist_add)
  - Issue #3: FAB overlap auto-resolved (card system removed)
  - Issue #4: AI Secrets lock icon on entry cards + detail screen
  - Issue #5: Keepsakes → Insights restructure (removed shelf/cards, kept charts + emoji jar carousel)
  - Issue #13: Collapsible calendar with week strip default, landscape auto-collapse
  - Issue #14: HomeScreen "Calendar" → "My Day" + bottom nav label sync
  - Bug fix: EntryDetailScreen title overflow (4px)
  - Bug fix: HomeScreen test compatibility with AppLocalizations
- **Files:** 14 modified, 11 deleted, 6 created. -2,421 net lines.
- **Dependencies:** flutter_quill removed (22 transitive deps cleaned)
- **Tests:** 96/96 passing, 0 analyze errors

### v1.1.0-beta.5+20 — 2026-05-01 (PROP-9)
- **PROP-9: Daily Checklist Entry (full implementation)**
  - DB migration v12: `entry_format`, `list_items`, `list_carried_forward` columns
  - `ListItem` model with JSON serialization, `EntryFormat` enum (note/list)
  - AddEntryScreen: Note/List toggle with `SegmentedButton`, reorderable list builder
  - EntryCard: checkbox rendering, strikethrough on done, "X/Y done" counter, carried-over banner
  - EntryDetailScreen: interactive list view with tappable checkboxes
  - HomeScreen: lists pinned above habits, separate Lists/Notes sections
  - Carry-forward: unchecked items auto-carry to next day on app open
  - One list per day constraint: auto-navigates to existing list on toggle
  - List edit screen: checkboxes with strikethrough consistent with Calendar display
  - 10 new i18n strings (EN/ZH)
  - **Test results:** 125/125 passing (31 new tests)
  - **UAT:** 14/15 cases passed (carry-forward pending manual date test)

### v1.1.0-beta.5+20 — 2026-04-30
- **PROP-6: 7-Day Trial API Key Flow (full stack)**
  - App-side: `DeviceService` (anonymous install UUID), `TrialService` (trial lifecycle with demo mode), Settings trial banner + provider entry + start flow, LLM service trial error handling, floating robot trial states, assistant expiry banner, i18n (13 new EN/ZH strings)
  - Backend: Cloudflare Workers (2 endpoints: `/api/trial/start`, `/api/trial/chat`), D1/KV storage, rate limiting (20 req/day), proxy to OpenRouter `qwen/qwen3.5-flash`, kill switch via Workers secret
  - Export/import: trial data excluded from backup/restore
- **Test results:** 94/94 passing
- **Build artifacts:** APK 70.5 MB, AAB 54.7 MB
- **Backend:** Deployed at `blinkingchorus.com`

### v1.1.0-beta.4+19 — 2026-04-29
- PROP-4: Card PNG cleanup (orphan file deletion on card/folder/template delete)
- PROP-5: DB indexes v11 (`entry_tags(entry_id)` + `note_card_entries(card_id)`)
- Calendar routine checklist simplified to 2-element layout
- Restore progress dialog with percentage and time estimate
- 93 tests passing

### v1.1.0-beta.3+18 — 2026-04-28
**Bug fixes:**
- Fixed template name locale mismatch: Create Card → Select Template → Edit Template → Template Name field was always showing Chinese names even under English locale. Root cause: `_TemplateEditorSheetState.initState` was seeding `_nameController` with the raw DB `name` field (always Chinese). Fix: added `isZh` parameter to `_TemplateEditorSheet` and switched `initState` to `template.displayNameFor(isZh)`.

**Test fixes (pre-existing failures resolved):**
- `emoji_jar_overflow_test.dart`: Two tests assumed `LocaleProvider` defaults to `'zh'`; it actually defaults to `'en'` (changed in a prior commit). Fixed: seeded Chinese locale via `SharedPreferences.setMockInitialValues` + `loadLocale()` for the zh-specific test; corrected expected string to `'Ask AI'` for the visibility test.
- `version_test.dart` / `constants.dart`: `AppConstants.appVersion` was stale at `'1.1.0-beta.2'`; bumped to `'1.1.0-beta.3'` to match pubspec.
- `settings_screen.dart`: Hardcoded version strings updated to `1.1.0-beta.3` (display subtitle + feedback email subject).

**Test results:** 56/56 passing

**Build artifacts:**
| Artifact | Result | Size |
|----------|--------|------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | — |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` | 65.3 MB |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` | 49.3 MB |

### v1.1.0-beta.3+18 — prior changes in this build
- **DB schema v10**: Added `source_template_id TEXT` column to `templates` table (migration in `onUpgrade`).
- **CardTemplate**: Added `sourceTemplateId` field; `displayNameFor(isZh)` now derives English name for copies of built-ins (e.g. "Custom — Spring Day").
- **CardFolder**: Added `displayNameFor(bool isZh)` — default folder renders as "My Cards" in English.
- **CardProvider**: `copyBuiltInTemplate()` now stores `sourceTemplateId` so copies can resolve their English display name.
- **EntryDetailScreen**: Added "Post to Chorus" icon button — opens `PostToChorusSheet` and shows a snackbar on success.
- **ChorusService**: New `lib/core/services/chorus_service.dart` (social publishing).
- **Chorus screen**: `lib/screens/chorus/` added with `PostToChorusSheet`.

### v1.1.0-beta.2+11 — fb79935 → 22776c8
- Adaptive icon, card fixes, font fill, feedback button, iOS xcassets fixes.

### v1.1.0-beta.1+9 — fb79935
- Public beta: bilingual UI, legal docs, emoji jar fix, habit import/export, card preview.

### v1.0.x
| Version | What |
|---------|------|
| v1.0.6 | Rich card editor (flutter_quill), 100-word limit, card tap → edit |
| v1.0.5 | Card edit/AI merge/template image, social sharing, AI personalization |
| v1.0.4 | Habit system overhaul (RoutineFrequency, 3-tab screen, calendar badges) |
| v1.0.3 | Jar, cards, summary + LLM merge fix |
| v1.0.2 | Floating robot, LlmService, AssistantScreen real LLM |
| v1.0.1 | Emotion picker, routine categories, calendar emoji |
| v1.0.0 | Initial release |

## Build Commands
```bash
flutter test                          # 96 tests
flutter analyze --no-pub              # 0 errors
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

## Known Issues

### Open
- Firebase / Cloud Sync — all deps commented out, sync toggle is a no-op
- Issue #15 Phase 2: Insights tab content enhancements (stats, checklists, correlation, AI — ~4h)
- Issues #8, #12: Trial/purchase flow (design doc complete, ~1.5h implementation)
- Restore: `ZipDecoder().decodeStream()` loads entire archive into memory — OOM risk on large (>500MB) backups. Needs streaming refactor for v1.1.1.

### Post-Launch Polish (All Resolved)
- Issues #9, #10, #11 — resolved 2026-05-03
- Issue #7 — rejected (calendar too crowded)
- Issues #8, #12 — moved to dedicated trial/purchase design plan

### Resolved (since v1.1.0-beta.3)
- Template name field shows Chinese under English locale (fixed v1.1.0-beta.3)
- AppConstants.appVersion out of sync with pubspec (fixed v1.1.0-beta.3)
- Emoji jar test locale assumption wrong (fixed v1.1.0-beta.3)
- Add Entry screen: Provider error
- SQLite migration from SharedPreferences
- Media persistence (FileService internal copy)
- Gradle build failures (compilerOptions DSL, JavaCompile --release flag)
- LLM API keys lost on restart
- Language setting lost on restart
- Search and tag filter unwired in Moment screen
- Duplicate AppProvider (deleted)
- Card PNG orphan files on delete (PROP-4)
- DB performance on queries (PROP-5 indexes)
- 7-day trial API key flow (PROP-6 — full stack deployed)
- Flutter 3.41.2→3.41.8 upgrade (unblocks Xcode 26)
- Daily checklist entries (PROP-9 — 8 commits, 31 new tests)

## Next Steps

1. **PROP-3: Promote Android to Production on Google Play** (~15 min) — smoke tests → version bump `1.1.0` → Play Store production
2. v1.1.0: Trial & Purchase Flow implementation (~1.5h) — required for launch
3. v1.1.0: Insights Phase 2 — CT2: Checklist Analytics (~45min) + CT4: AI-Generated Insights (~1.5h)
4. Firebase / Cloud Sync (future, deps already in pubspec)

## Active Plans

| Plan | Status | Link |
|------|--------|------|
| **Blinking Launch Plan (Android + iOS)** | **Active** | [2026-05-02](docs/plans/blinking-launch-plan-2026-05-02.md) |
| **Insights Tab Enhancement (Issue #15)** | **Active — CT1+CT3 done, CT2+CT4 remaining** | [2026-05-03](docs/plans/2026-05-03-insights-tab-enhancement.md) |
| **Insights CT1+CT3 UAT** | ✅ Passed (12/12) | [2026-05-04](docs/plans/2026-05-04-insights-phase2-ct1-ct3-uat.md) |
| App Trial & Purchase Flow (Issues #8, #12) | Designed | [2026-05-03](docs/plans/2026-05-03-trial-purchase-flow-design.md) |
| 7-Day Trial API Key Flow (PROP-6) | ✅ Complete | [2026-04-30-prop-6-trial-api-key-plan.md](docs/plans/2026-04-30-prop-6-trial-api-key-plan.md) |
| Daily Checklist Entry (PROP-9) | ✅ Complete | [2026-04-30-prop-9-daily-checklist-plan.md](docs/plans/2026-04-30-prop-9-daily-checklist-plan.md) |
| UAT — PROP-9 | ✅ Passed (14/15) | [2026-05-01-prop-9-uat-test-cases.md](docs/plans/2026-05-01-prop-9-uat-test-cases.md) |
| Launch Readiness (Pre/Post) | Superseded | [2026-05-01](docs/plans/launch_readiness_2026-05-01.md) |
| iOS Release | Moved to ClaudeDev/system-upgrade | [system-upgrade/master_plan.md](../system-upgrade/master_plan.md) |

## Contact
- Developer: Justin
- Feedback: blinkingfeedback@gmail.com
