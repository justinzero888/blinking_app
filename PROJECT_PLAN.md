# Blinking App (记忆闪烁) - Project Plan

## App Overview
- **Name**: Blinking (记忆闪烁)
- **Type**: Personal memory capture app
- **Framework**: Flutter
- **Platforms**: Android + iOS (both live)
- **Current Version**: 1.1.0-beta.8+23

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
| 29 | M1 Foundation — EntitlementService (server-authoritative state + quotas) | Done |
| 30 | M1 Foundation — Floating robot rewrite (entitlement-aware state matrix, long-press overlay) | Done |
| 31 | M1 Foundation — BYOK setup screen (6 providers, dropdown, ping validation) | Done |
| 32 | M1 Foundation — CT4: AI-Generated Insights (LLM + rule-based fallback, Refresh button) | Done |
| 33 | M1 Foundation — Settings → AI entitlement banner (PREVIEW/RESTRICTED/BYOK) | Done |
| 34 | M2 Purchase — Paywall screen ($9.99 Pro, feature checklist, in-app legal docs) | Done |
| 35 | M2 Purchase — Day 21 Transition screen (what stays vs pauses, one-time guard) | Done |
| 36 | Server: Receipt validation endpoints (purchase, restore) + receipts D1 table | Done |
| 37 | Server: Entitlement state machine (init, status, chat) + JWT + quota counter | Done |
| 38 | Client: IAP integration (RevenueCat + PurchasesService + paywall wiring) | Done |
| 39 | RevenueCat Test Store verified — purchase flow end-to-end on simulator | Done |

### Remaining / Blocked
| # | Item | Status |
|---|------|--------|
| 1 | **Setup IAP (human)** — RevenueCat Test Store ✅ verified. Remaining: connect App Store Connect + Play Console for production keys | ⬜ Pending — see `docs/plans/revenuecat-setup-actual.md` |
| 2 | **Set server secrets + deploy** — JWT_SECRET, ENTITLEMENT_ENABLED, D1 migrations | ~10min — deploy-ready |
| 3 | **PROP-3: Promote Android to Production on Google Play** | ~1.5h — launch-ready |
| 4 | M4 Top-ups (denial sheet, consumable IAP) | ~3h — post-launch |
| 5 | Firebase / Cloud Sync | Not started — deps commented out |

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

### v1.1.0-beta.8+23 — 2026-05-06 (RevenueCat IAP — Test Store Verified)
- **RevenueCat IAP fully verified on Test Store.** Purchase flow: paywall → Get Pro → native purchase dialog → "Welcome to Pro!" → entitlement activated.
- **purchases_flutter upgraded to 9.16.1** (from 8.11.0) for Test Store support.
- **PurchasesService** fix: `purchasePackage` API change in 9.x (returns `PurchaseResult`, not `CustomerInfo`).
- **EntitlementService** fix: `_applyLocalPreview()` early return guard for restricted/paid state.
- **Paywall** now calls `refreshCustomerInfo()` after purchase for immediate entitlement sync.
- **Debug toggle:** 5-tap version text in Settings to cycle preview/restricted for IAP testing.
- RevenueCat configuration: entitlement `pro_access` → product `blinking_pro` → offering `ofrng88832e4ac2` (set as Current).
- CocoaPods updated: PurchasesHybridCommon 14.3.0 → 17.55.1, RevenueCat 5.67.1.
- IAP setup guide updated to `docs/plans/revenuecat-setup-actual.md` with real process documented.
- **Tests:** 135/135 passing. **Lint:** 0 errors.

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

## Contact
- Developer: Justin
- Feedback: blinkingfeedback@gmail.com
