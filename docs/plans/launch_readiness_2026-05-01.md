# Launch Readiness & Post-Launch Polish
**Date:** 2026-05-01
**Version:** 1.1.0-beta.5+20
**Status:** Pre-launch — 3 items remaining before Production release

---

## Executive Summary

Of 14 UX bug-reports items, 9 are resolved. The app's feature set is stable, all P1/P2 UX issues are closed, and 96/96 tests pass with 0 analyze errors. This document tracks the 3 pre-launch actions required before Google Play Production promotion, plus 6 post-launch polish items that improve existing features but are not launch-blockers.

---

## Pre-Launch Readiness (Must Complete Before Production)

---

### LR-1: Promote Android to Production on Google Play (PROP-3)

**Status:** pending
**Priority:** P0 (blocking)
**Effort:** ~15 minutes manual (no code changes)
**Type:** Release / Operations

**Description:**
The current build (v1.1.0-beta.5+20) is in Google Play Closed Testing. Once the soak period shows no crash spikes or critical feedback, the build must be promoted to Production to make the app publicly available.

**Analysis:**
- AAB built and uploaded to Play Console (already done from prior sessions)
- Closed Testing (beta) has been active — ready for promotion after soak period
- No code changes required — purely a Play Console operation
- Recommended: start at 10–20% staged rollout to catch issues before full distribution

**Steps:**
1. Open Google Play Console → Release → Production
2. Create new release → Promote from Closed Testing (beta)
3. Set rollout percentage to 10–20%
4. Submit for review
5. Monitor crash reports and ratings for 24–48 hours
6. Increase to 100% if no issues

**Options:**

| Option | Description | Rollout Speed | Risk |
|--------|-------------|:---:|------|
| **A — Staged rollout (recommended)** | Start at 10–20%, monitor 24–48h, expand to 100% | Moderate | Low |
| **B — Full release** | Promote directly to 100% | Fast | Medium — no early-warning if crashes exist |
| **C — Internal Testing first** | Promote to Internal Testing → Closed Testing → Production | Slowest | Lowest |

**Recommendation:** Option A. Staged rollout gives a safety net for any issues that beta testers didn't catch, without unnecessarily delaying the public launch.

**Questions:**
- Is the soak period sufficient, or should we wait for more beta usage?
- Target rollout percentage: 10%, 20%, or 50% for initial wave?

---

### LR-2: Carry-Forward Manual UAT (PROP-9 TC-11)

**Status:** pending
**Priority:** P1 (launch-critical)
**Effort:** ~15 minutes (manual testing — no code)
**Type:** Verification / UAT

**Description:**
PROP-9 (Daily Checklist Entry) includes an auto-carry-forward feature: when the app opens on a new day, unchecked items from yesterday's list are automatically copied to today. This was implemented and unit-tested, but the manual UAT test case (TC-11) was deferred because it requires device date manipulation — changing the emulator clock to simulate "tomorrow."

**Analysis:**
- Carry-forward logic runs in `EntryProvider.loadEntries()` via `EntryRepository.checkAndCarryForward()`
- Uses Dart local date comparison (not SQLite UTC) — tests cover the logic paths
- The only untested scenario: opening the app on a real "next day" after creating a list today
- Risk: if carry-forward has a date boundary bug, users could lose their list items on the first real-world use

**Steps:**
1. Create a checklist entry today with 3 items, leave 2 unchecked
2. Close the app
3. Change emulator date/time to tomorrow (Settings → Date & Time → set to next day)
4. Reopen the app
5. Verify: today shows a new list entry with 2 items ("X items carried over from yesterday" banner)
6. Verify: yesterday's list still shows original items (2 unchecked, 1 checked)
7. Verify: banner auto-clears or is dismissible
8. Change emulator date back to today

**Expected result:** Unchecked items carry forward. Original list preserved. Banner visible. No duplicate carry-forward on re-open.

**Questions:**
- Ready to perform this test now, or schedule for a dedicated session?

---

### LR-3: Pre-Launch Smoke Tests & Build Verification

**Status:** pending
**Priority:** P1 (launch-critical)
**Effort:** ~30 minutes (manual testing)
**Type:** Verification

**Description:**
Before promoting to Production, a targeted smoke test across all 5 tabs and core flows ensures no regressions were introduced by the 9 UX fixes implemented in this session.

**Analysis:**
- 96 automated tests pass, 0 analyze errors — code-level verification is clean
- Manual smoke test covers what automated tests can't: visual rendering, navigation flow, real-data interaction on device
- Focus on areas touched this session: calendar collapse/expand, My Day tab, Insights tab, lock icon, contextual FAB, entry detail overflow

**Smoke Test Checklist:**

| # | Flow | Expected | Result |
|---|------|----------|:------:|
| 1 | Open app → My Day tab | AppBar "My Day", week strip visible, content below | ☐ |
| 2 | Tap chevron ▼ → expand calendar | Full month grid visible, chevron changes to ▲ | ☐ |
| 3 | Tap ▲ → collapse | Returns to week strip | ☐ |
| 4 | Rotate to landscape | Calendar auto-collapses, no overflow, content visible | ☐ |
| 5 | Tap a past date in week strip | Day view updates, title shows "My Day - {date}" | ☐ |
| 6 | Tap Today button | Returns to today, calendar collapses | ☐ |
| 7 | Navigate to Moments tab | FAB "+" visible, opens Add Entry | ☐ |
| 8 | Navigate to Routine tab | FAB shows playlist_add icon, opens Add Routine dialog | ☐ |
| 9 | Navigate to Insights tab | FAB hidden, robot visible, jar carousel + 4 charts render | ☐ |
| 10 | Navigate to Settings tab | FAB hidden, robot hidden, all settings accessible | ☐ |
| 11 | Open entry detail for Secrets-tagged entry | Lock icon in AppBar title, no overflow banner | ☐ |
| 12 | Create new entry → save → verify in Moments | Entry persists, renders correctly | ☐ |
| 13 | Toggle habit completion on Calendar | Checkbox toggles, state persists | ☐ |
| 14 | Create checklist → add items → check off | Items render with strikethrough, "X/Y done" counter | ☐ |
| 15 | Switch to Chinese (设置 → 语言 → 中文) | All labels correct: "我的一天", "洞察", lock icon remains | ☐ |

**Questions:**
- Add any additional flows from recent UAT that need re-verification?

---

## Post-Launch Polish (Not Blocking — Can Ship After Production)

These 6 items improve existing functioning features. None break the app. All can be implemented after the Production release to avoid delaying launch.

---

### P-1: Calendar List Badge Indicator (Issue #7)

**Status:** deferred
**Priority:** P3
**Effort:** ~1.5h
**Type:** Feature gap / UX enhancement

**Description:**
The calendar grid and week strip show emotion emoji badges and habit completion bars per day, but there's no indicator for days that have checklist entries. Users can't see which past days had lists without navigating into each day.

**Analysis:**
- Current calendar day cell shows: day number + emotion emoji/dot + habit progress bar
- A list badge (e.g. ☑ or small checklist icon) would add a 4th indicator in an already-dense cell
- PROP-9 design doc noted this as "nice-to-have" — implement only if it doesn't create visual clutter
- Performance: pre-compute once per build, not per-cell query

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Pre-computed map (recommended)** | Compute `Map<DateTime, bool>` once in HomeScreen, pass to CalendarWidget. Render small "☑" below habit bar. | ~1.5h |
| **B — Inline query in cell** | Query `EntryProvider.getEntriesForDate()` per cell. Simple but 28+ queries per render. | ~30min |
| **C — Replace habit bar with list badge for list-only days** | If a day has both habits and a list, show both. If only list, show list badge instead of empty habit bar. | ~1h |
| **D — No indicator** | Keep calendar clean. Users discover lists by navigating. | ~0h |

**Recommendation:** Option A if implemented. The ☑ indicator should be tiny (8–10px), secondary to the emotion emoji, and consistent between week strip and full calendar grid. Show completion state: filled ☑ for all-done, outlined ☐ for partial.

**Files:** `lib/widgets/calendar_widget.dart`, `lib/screens/home/home_screen.dart`

---

### P-2: Robot Trial/Error State Clarity (Issue #8)

**Status:** deferred
**Priority:** P2
**Effort:** ~1h
**Type:** UX polish

**Description:**
The floating robot has multiple visual states (active, no-API-key, trial-active, trial-expired). The transitions between states and the clarity of each state need review. Currently: no-API-key = 50% opacity + "!" badge; trial-expired = 50% opacity; active = full opacity + bobbing.

**Analysis:**
- Robot is visible on tabs 0 (My Day), 1 (Moments), 2 (Routine), 3 (Insights). Hidden on Settings.
- States: active (bobbing, tap → AssistantScreen), no-api-key (dimmed, "!" badge, tap → snackbar), trial-active (bobbing, tap → AssistantScreen), trial-expired (dimmed, tap → snackbar)
- Edge cases: what happens when trial expires while app is open? Is re-check triggered on app resume?
- The "!" badge may not be noticeable enough; the expired state doesn't clearly communicate next action

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Enhanced visual states + tooltip (recommended)** | Add distinct badges per state: "!" for no-key, clock for trial-active ("7d"), expired-clock for expired. Long-press tooltip on expired: "Tap Settings → AI Providers to add your own API key." Re-check on app resume. | ~1h |
| **B — Hide robot on expired** | When trial expires and no API key, hide robot entirely. Clean but reduces AI feature discoverability. | ~30min |
| **C — Tap expired robot → navigate to Settings** | Instead of snackbar, take user directly to AI Providers settings. More actionable but may feel intrusive. | ~45min |

**Recommendation:** Option A. Distinct visual states that communicate both status AND next action. The robot is a high-visibility UI element — its state should be clear enough that users never wonder "why does the robot look different today?"

**Files:** `lib/widgets/floating_robot.dart`

---

### P-3: One-List-Per-Day Transition UX (Issue #9)

**Status:** deferred
**Priority:** P3
**Effort:** ~45min
**Type:** UX polish

**Description:**
PROP-9 enforces one list per day. If the user already has a list for today and tries to create another via the Note/List toggle, the app uses `pushReplacement` to navigate to the existing list in edit mode. The screen replacement may feel jarring — the user toggled a segmented button and suddenly the screen changed.

**Analysis:**
- `AddEntryScreen._switchFormat()` checks for existing lists and calls `pushReplacement` if found
- No transition animation or contextual explanation provided
- User expectation: toggling "List" should show the list editor. Getting redirected to an existing list without explanation breaks that expectation.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Snackbar + fade transition (recommended)** | Before navigating, show snackbar: "You already have a list for today — opening it now" / "今天已有清单，正在打开". Navigate with fade transition instead of pushReplacement. | ~45min |
| **B — Disable List toggle when list exists** | Grey out "List" in SegmentedButton when today has a list. Add tooltip: "Today's list already exists — tap to edit." | ~30min |
| **C — Inline edit instead of navigate** | Instead of navigating, transform the current AddEntryScreen to list-edit mode in-place. No navigation at all. | ~1.5h |

**Recommendation:** Option A. Quick to implement, provides clear context, and the fade transition makes the replacement feel intentional.

**Files:** `lib/screens/add_entry_screen.dart`

---

### P-4: Carry-Forward Banner Timing (Issue #10)

**Status:** deferred
**Priority:** P3
**Effort:** ~30min
**Type:** UX polish

**Description:**
The carry-forward banner ("X items carried over from yesterday") appears on the carried-forward EntryCard and auto-clears via `WidgetsBinding.instance.addPostFrameCallback`. A user who opens the app and immediately scrolls or navigates away may never see the banner. Additionally, the banner only shows on the Calendar day view — Moments tab users may never encounter it.

**Analysis:**
- `EntryProvider._lastCarriedCount` set during carry-forward, read by HomeScreen
- Banner auto-clears after one frame via `postFrameCallback` → `EntryProvider.clearCarriedBanner()`
- Only HomeScreen (Calendar/My Day tab) displays the banner
- Risk: user opens app, immediately scrolls, banner clears without being seen

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Persist until user dismisses or views list (recommended)** | Keep banner until: user taps the carried-forward entry to view/edit, or dismisses with "×" button. Show in Moments tab too. | ~30min |
| **B — Extend display time** | Change to 3-second delay before auto-clear. Still risky for fast-navigating users. | ~15min |
| **C — System notification** | Fire a local notification on app open when items are carried forward. Most prominent, may feel intrusive. | ~1h |

**Recommendation:** Option A. Banner should persist until explicitly engaged with. This ensures 100% visibility regardless of user behavior.

**Files:** `lib/screens/home/home_screen.dart`, `lib/widgets/entry_card.dart`, `lib/providers/entry_provider.dart`

---

### P-5: List Checkbox UX Consistency (Issue #11)

**Status:** deferred
**Priority:** P3
**Effort:** ~1h
**Type:** UX / consistency

**Description:**
List checkboxes can be toggled in 3 places: HomeScreen EntryCard, EntryDetailScreen, and the List edit screen (AddEntryScreen list mode). All use the same checkbox+strikethrough pattern, but the edit screen also has reorderable drag handles — a different interaction model in a visually similar context.

**Analysis:**
- All three screens now use the same checkbox+strikethrough pattern (consistent visual language)
- Edit screen has additional: title field, item-entry bar (add new items), reorderable list
- Detail screen has: tappable checkboxes only (read-only otherwise)
- Card view has: tappable checkboxes only (compact)
- Users might not understand why some screens let them reorder/edit and others don't

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Differentiate screens by purpose (recommended)** | Add subtle helper text or tooltips. Edit screen: visible drag handle icon on each item. Detail view: tooltip "Tap to check." | ~1h |
| **B — Inline toggling on Calendar** | Allow checking items on the Calendar day view without opening any screen. Edit screen only for add/remove/reorder. | ~3h |
| **C — Leave as-is** | Consistency already achieved. Users will discover differences naturally. | ~0h |

**Recommendation:** Option A at minimum. The drag handle on the edit screen should be explicitly visible (not hidden behind long-press discovery). A visible `Icons.drag_handle` on each row communicates "this is reorderable" without ambiguity.

**Files:** `lib/screens/add_entry_screen.dart`

---

### P-6: Settings Trial Banner Dismiss (Issue #12)

**Status:** deferred
**Priority:** P3
**Effort:** ~45min
**Type:** UX polish

**Description:**
The Settings screen shows a trial banner ("X days remaining" or "Trial expired"). Can users dismiss it? If trial is expired and user added their own API key, does the banner still show? Does it compete visually with other Settings items?

**Analysis:**
- Introduced in PROP-6 via `TrialService`
- Banner conditionally renders based on trial state
- No dismiss mechanism — banner persists until trial naturally ends
- After trial expires AND user adds own API key: does banner still show expired trial?

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Dismissible + contextual (recommended)** | Allow dismiss with "×" button. Auto-hide when user adds own API key (they've moved on from trial). Only show when trial is active AND user hasn't configured their own key. | ~45min |
| **B — Keep current behavior** | Banner persists until trial ends. | ~0h |
| **C — Remove banner, show in robot only** | Move trial status to robot badge only. Settings stays clean. | ~1h |

**Recommendation:** Option A. The banner served its purpose once the user activates the trial. Once they add their own key, the trial banner is no longer relevant and should disappear.

**Files:** `lib/screens/settings/settings_screen.dart`

---

## Deferred (Not Tracked Here)

These items are in CLAUDE.md / PROJECT_PLAN.md but are large, blocked, or moved to separate projects:

| Item | Status |
|------|--------|
| Firebase / Cloud Sync | All deps commented out — large, no timeline |
| iOS release (Xcode 26) | Moved to `ClaudeDev/system-upgrade` |
| Custom emoji images E-1/E-2 | Deferred from v1.1.0 beta |
| Card generation AI multi-design | Removed with card system decommission |

---

## Summary Table

| ID | Item | Priority | Effort | Category |
|----|------|:--------:|:------:|----------|
| LR-1 | Promote to Google Play Production (PROP-3) | P0 | ~15min | **Pre-launch** |
| LR-2 | Carry-forward manual UAT (TC-11) | P1 | ~15min | **Pre-launch** |
| LR-3 | Pre-launch smoke tests & build verification | P1 | ~30min | **Pre-launch** |
| P-1 | Calendar list badge indicator | P3 | ~1.5h | Post-launch |
| P-2 | Robot trial/error state clarity | P2 | ~1h | Post-launch |
| P-3 | One-list-per-day transition UX | P3 | ~45min | Post-launch |
| P-4 | Carry-forward banner timing | P3 | ~30min | Post-launch |
| P-5 | List checkbox UX consistency | P3 | ~1h | Post-launch |
| P-6 | Settings trial banner dismiss | P3 | ~45min | Post-launch |
| **Total pre-launch** | | | **~1h** | |
| **Total post-launch** | | | **~4.5h** | |

---

## Launch Checklist

### Before Production
- [ ] LR-1: Promote to Google Play Production (staged rollout 10–20%)
- [ ] LR-2: Carry-forward manual UAT passed
- [ ] LR-3: Smoke tests passed across all 5 tabs
- [ ] Play Store listing reviewed: description, screenshots, feature graphic, privacy policy link
- [ ] Version bump decision: v1.1.0-beta.5 → v1.1.0 (production) or keep version?
- [ ] Release build signed with production keystore
- [ ] Crash reporting configured (Firebase Crashlytics or Play Console native)

### After Production (Week 1)
- [ ] Monitor Play Console crash reports and ANRs for 48 hours
- [ ] Monitor ratings and reviews — respond to first reviews
- [ ] If staged rollout at 20% and stable, expand to 50% → 100%

### Post-Launch Polish (Week 2+)
- [ ] P-1: Calendar list badge indicator (~1.5h)
- [ ] P-2: Robot trial states (~1h)
- [ ] P-3: One-list transition (~45min)
- [ ] P-4: Carry-forward banner (~30min)
- [ ] P-5: List checkbox consistency (~1h)
- [ ] P-6: Trial banner dismiss (~45min)

---

## Clarification Questions

1. **LR-1 (Play Store):** Target rollout percentage — 10%, 20%, or 50% for initial wave?
2. **LR-1:** Is beta soak sufficient, or wait for more Closed Testing feedback?
3. **LR-2 (UAT):** Perform carry-forward UAT now or schedule dedicated session?
4. **LR-3 (Smoke):** Any specific flows from recent UAT that need re-verification?
5. **Version:** Promote current beta version (v1.1.0-beta.5+20) as v1.1.0 production, or bump to v1.1.0+21 for the production build?
6. **Post-launch priority:** Which of P-1 through P-6 should be tackled first after launch?
