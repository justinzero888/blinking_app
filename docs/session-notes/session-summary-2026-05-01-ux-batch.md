# Blinking App — Development Session Summary
**Date:** 2026-05-01
**Session Type:** UX Issue Resolution (Full Batch)
**Status:** COMPLETE — 9 of 14 bug-reports resolved, launch readiness plan documented
**Time:** ~11h total across all implementations

---

## Session Overview

Resolved all P1 and P2 UX issues in a single extended session. The app's 5-tab navigation was streamlined (Keepsakes → Insights), the calendar became collapsible with landscape safety, the FAB became context-aware per tab, the home tab was rebranded ("My Day"), AI Secrets entries gained visible lock indicators, and an entry detail overflow bug was fixed. Created a comprehensive launch readiness plan for the remaining pre-launch actions and post-launch polish items.

---

## Issues Resolved (in implementation order)

### Issue #1 — Calendar Future Date Lock (~2h)
- Future dates greyed out at 35% opacity, non-tappable
- Today cell gets teal outline for orientation
- Month navigation limited to today + 2 months (right chevron disabled at boundary)
- Server-side guards: `_onDateSelected` rejects future, `_getDayHabitStatus` skips future queries
- **Files:** `calendar_widget.dart`, `home_screen.dart`
- **UAT:** 10/10 passed

### Issue #5 — Keepsakes → Insights Restructure (PROP-8) (~3.5h)
- Removed: shelf tab, year jar drill-down, cards tab, card editor, card builder, card preview, card renderer, "Make card" button from Moments
- Created: single-scroll Insights screen with emoji jar carousel (yearly jars via `JarProvider`) + 4 summary charts (inlined from `summary_tab.dart`)
- Card models and DB tables preserved inert (no migration, no data loss)
- Floating robot now visible on Insights tab (changed `>= 3` → `>= 4`)
- Main FAB hidden on Insights and Settings tabs
- `CardProvider` unregistered from provider tree, `flutter_quill` removed from `pubspec.yaml` (22 transitive deps cleaned)
- **Files deleted:** 8 (shelf, year_jar_detail, cards_tab, card_builder_dialog, card_editor_screen, card_preview_screen, card_renderer, summary_tab)
- **Files modified:** `app.dart`, `cherished_memory_screen.dart` (rewritten), `moment_screen.dart`, `floating_robot.dart`, `models.dart`, ARB files, `pubspec.yaml`
- **UAT:** 15/15 passed

### Issue #14 — HomeScreen Title "Calendar" → "My Day" (~15min)
- AppBar title: "My Day" / "我的一天" for today; "My Day - Apr 15" / "我的一天 - 4月15日" for past dates
- Bottom nav tab label synced: "Calendar" → "My Day"
- ARB key `myDay` added to EN/ZH files
- Null-safe fallback for test compatibility
- **Files:** `home_screen.dart`, `app_en.arb`, `app_zh.arb`

### Issue #4 — AI Secrets Lock Icon (PROP-7) (~1h)
- Grey `Icons.lock_outline` (14px) on entry cards (`_buildHeader`, `_buildListHeader`) and EntryDetailScreen AppBar title
- Positioned between emotion emoji and share icon
- Fire-n-forget: informational only, not tappable
- **Bug found & fixed:** EntryDetailScreen title Row overflowed by 4px with lock icon + date + 3 action buttons. Fixed with `Flexible` wrapper + `TextOverflow.ellipsis`
- **Files:** `entry_card.dart`, `entry_detail_screen.dart`

### Issue #7 — Contextual FAB on Routine Tab (~1.5h)
- Made `RoutineScreenState` public, exposed `showAddRoutineDialog()` via GlobalKey
- FAB now context-aware: My Day/Moments = "+" → Add Entry; Routine = `Icons.playlist_add` → Add Routine dialog
- Hidden on Insights and Settings
- Removed redundant AppBar `+` button from RoutineScreen
- Separate `heroTag` per FAB context
- **Files:** `app.dart`, `routine_screen.dart`
- **UAT:** TC-7 through TC-12 passed

### Issue #13 — Collapsible Calendar (Landscape-Safe) (~3h)
- **Collapsed (default):** Compact week strip (~65px) — 7 days with day numbers, emotion emojis, habit progress mini-bars. Tap to select. Week strip centers on `selectedDate`.
- **Expanded:** Full month grid as before. Chevron button (`expand_more`/`expand_less`) toggles.
- **Landscape:** Auto-collapses via `MediaQuery.orientation`. Chevron hidden (no expand option). Eliminates "BOTTOM OVERFLOWED BY 691 PIXELS".
- **State persisted:** `SharedPreferences` key `calendar_expanded`, defaults to `false` (content-first).
- **Week strip:** Static (no swiping). Single gesture vocabulary: tap day = select, chevron = expand/collapse.
- `_goToToday()` collapses calendar; `_onDateSelected()` syncs `focusedMonth`.
- **Files:** `calendar_widget.dart` (full rewrite), `home_screen.dart`
- **UAT:** All scenarios passed

### Issue #3 — FAB Overlap (~0h auto-resolved)
- Card system removal (PROP-8) eliminated the second FAB. No overlap possible.

### Issue #6 — List/Notes Section Headers (~0h noted)
- Headers already existed from PROP-9: 📋 Lists, ✅ Habit Check-in, 📝 Notes

---

## Files Summary

| Action | Count | Details |
|--------|:-----:|---------|
| **Deleted** | 11 | 7 cherished screen files + card_renderer.dart + summary_tab.dart + 3 test files |
| **Modified** | 14 | app.dart, home_screen.dart, calendar_widget.dart, cherished_memory_screen.dart, moment_screen.dart, routine_screen.dart, entry_detail_screen.dart, entry_card.dart, floating_robot.dart, models.dart, app_en.arb, app_zh.arb, pubspec.yaml, pubspec.lock |
| **Created** | 6 | 4 UAT docs + session summary + launch readiness plan + fab-ux-research.md |
| **Net lines** | -2,421 | 1,106 added, 3,527 removed |

---

## Test Results

| Suite | Tests | Status |
|-------|:-----:|--------|
| Flutter unit + widget + integration | 96 | All passing |
| Flutter analyze | 52 issues | 0 errors (all pre-existing warnings/infos) |
| Version sync test | 4/4 | All passing |
| Release APK | 65.0MB | Built |
| Release AAB | 52.3MB | Built |
| UAT — Calendar future date | 10/10 | ✅ |
| UAT — Insights restructure | 15/15 | ✅ |
| UAT — Issues #4, #7, #14 | 12/12 | ✅ |
| UAT — Collapsible calendar | All scenarios | ✅ |

---

## Bug Fixes Discovered During Implementation

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| EntryDetailScreen title "OVERFLOWED BY 4 PIXELS" | Lock icon + date `Row` in AppBar title competed with 3 action buttons for space | Wrapped date `Text` in `Flexible` with `TextOverflow.ellipsis` |
| HomeScreen tests failed after title change | `AppLocalizations.of(context)!` returned null in test harness (no Localizations widget) | Made `_buildTitle()` null-safe: `l?.myDay ?? fallback` |

---

## Version Bump & Release

| Item | Value |
|------|-------|
| **Previous** | `1.1.0-beta.5+20` |
| **New** | `1.1.0-beta.6+21` |
| **Files updated** | `pubspec.yaml`, `constants.dart`, `settings_screen.dart` (×2), `CLAUDE.md`, `PROJECT_PLAN.md` |
| **Version test** | 4/4 passed |
| **Release APK** | `build/app/outputs/flutter-apk/app-release.apk` — **65.0MB** (↓5.5MB from beta.5) |
| **Release AAB** | `build/app/outputs/bundle/release/app-release.aab` — **52.3MB** (↓2.4MB from beta.5) |
| **Size reduction** | flutter_quill removal (22 transitive deps cleaned) |
| **Commit** | `e7aaf50` — 50 files, +3,135 / −3,551 lines |
| **Push** | `master` → `origin/master` (GitHub) |

---

## Bug Reports Status

| Status | Count | Items |
|--------|:-----:|-------|
| ✅ Resolved | 9 | #1, #2, #3, #4, #5, #6, #7, #13, #14 |
| ⬜ Deferred (post-launch) | 6 | #7 (badge), #8 (robot), #9 (transition), #10 (banner), #11 (checkbox), #12 (trial) |

---

## What Remains

### Pre-Launch (~1h)
| ID | Item | Effort |
|----|------|:------:|
| LR-1 | PROP-3 — Promote to Google Play Production | ~15min |
| LR-2 | Carry-forward manual UAT (date manipulation) | ~15min |
| LR-3 | Pre-launch smoke tests | ~30min |

### Post-Launch (~4.5h, 6 items)
All are existing-feature polish — none blocking for launch. Detailed in `docs/plans/launch_readiness_2026-05-01.md`.

---

## Documents Created / Updated

| Document | Status |
|----------|--------|
| `docs/uxbugs/bug-reports.md` | Updated — 9 resolved, summary table, prioritization |
| `CLAUDE.md` | Updated — feature status, pending, launch roadmap |
| `PROJECT_PLAN.md` | Updated — completed features, known issues, next steps, active plans |
| `docs/plans/launch_readiness_2026-05-01.md` | **NEW** — pre-launch + post-launch plan |
| `docs/plans/2026-05-01-calendar-future-date-uat.md` | NEW |
| `docs/plans/2026-05-01-insights-restructure-uat.md` | NEW |
| `docs/plans/2026-05-01-issues-4-7-14-uat.md` | NEW |
| `docs/session-notes/session-summary-2026-05-01-ux-batch.md` | This file |

---

## Key Architectural Decisions

1. **Calendar collapse state:** Defaults to collapsed (content-first). Week strip is static (no swiping). Single gesture vocabulary.
2. **FAB context:** Per-tab icon + action, separate heroTags. Routine uses GlobalKey to access state.
3. **Card data preservation:** DB tables and models kept. CardProvider file kept but unregistered. No migration — data is inert but recoverable.
4. **flutter_quill removal:** 22 transitive deps cleaned. Can be re-added if card feature is ever restored.
5. **Insights tab:** Emoji jar carousel uses `JarProvider.getYearEmotions()` + `EmojiJarWidget` with `showAskAi: false`. Charts inlined from `summary_tab.dart`.
