# UX Issues and Defects
$ 2026-05-01: This document tracks all UX issues and bugs for the BlinkingNotes app. Each item has an assigned issue number, reported date, description, resolution, effort estimate, and closed date. The goal is to manage the lifecycle of every UX/UI issue through to resolution.

For each item, always follow following steps:
1. Research the issue and understand the root cause.
2. Propose a solution and get it approved by the user.
3. Implement the solution and test it thoroughly.
4. write UAT test cases, compile and update apk for emulator. Launch emulator for human to validate/verify. 
5. Upon approval, document the solution and close this issue. Documentation should include the root cause, the solution, and the UAT test cases. update master project plan doc and this document

---

### 13. NEW: Calendar grid too large — covers entire screen in landscape and square aspect ratios

**Status:** RESOLVED
**Priority:** P1 (high)
**Reported:** 2026-05-01
**Resolved:** 2026-05-01
**Effort:** ~3h

**Resolution — Collapsible calendar with static week strip (Option A):**

1. **Collapsed default:** Compact week strip (~65px) showing 7 days (Sun–Sat) with day numbers, emotion emojis, and habit progress mini-bars. Tap a day to select. Strip centers on `selectedDate` — not necessarily the current week (follows user navigation).
2. **Expanded state:** Full month grid as before (~350px). Toggled via chevron button (`Icons.expand_more`/`expand_less`) next to the right-arrow in the month header.
3. **Landscape auto-collapse:** When `MediaQuery.orientation == landscape`, calendar auto-collapses to week strip. Right chevron hidden (no expand option). Eliminates the "BOTTOM OVERFLOWED BY 691 PIXELS" error.
4. **State persisted:** `SharedPreferences` key `calendar_expanded` saves user preference. Defaults to `false` (content-first).
5. **Week strip is static** (no horizontal swiping). Clear gesture vocabulary: tap day = select, tap chevron = expand/collapse, swipe month = navigate months (expanded only). No gesture conflict.

**Files:** `lib/widgets/calendar_widget.dart` (rewritten), `lib/screens/home/home_screen.dart` (state management + persistence)

**Description:**
The calendar grid is rendered with `shrinkWrap: true` and `NeverScrollableScrollPhysics()`, meaning it takes its full natural height (7 columns × square cells = roughly the screen width in height). On portrait phones this leaves ~40% of the screen for the day view below. On landscape orientation or square-screen devices (tablets, foldables), the calendar can consume 60–80% of the vertical space or even the entire screen, leaving practically no room for today's entries, habit check-in, and emoji jar. The calendar itself is not scrollable — it's a fixed block. This makes the Home tab feel broken on non-portrait devices.

**Research:**
- `HomeScreen.build()` places `CalendarWidget` (unconstrained height) + `Divider` + `Expanded(_buildTodayOverview)` in a `Column`. The calendar takes whatever height it wants; only the day view gets flex.
- `CalendarWidget` uses `GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` — the grid computes its full natural height and renders as a fixed block.
- `childAspectRatio: 1` means each cell is square. On a 800px-wide tablet in landscape (400px height), the grid alone is ~400px, leaving nothing for content.
- Industry standard: journaling/habit apps universally make the calendar collapsible or adaptive to screen orientation.

**Industry research — what apps in this category do:**

| App | Calendar behavior |
|-----|------------------|
| **Daylio** | Calendar at top, **collapsible** — default shows compact week strip. Swipe/chevron to expand full month. Gold standard for journaling apps. |
| **Streaks** | Calendar at top with **chevron toggle**. Default compact (current week showing). Tap to expand full month. |
| **HabitNow** | Full month always visible but on landscape switches to side-by-side layout (calendar left, day detail right). |
| **TickTick** | Calendar tab with **toggle** between month view and list view. Month view scrolls vertically within its area. |
| **Google Calendar** | Month view **scrolls vertically** in landscape; calendar IS the primary view (different category — planning app). |
| **Loop Habit Tracker** | Full month always visible but **compact cells** (no emotion badges, just dots). Grid is ~30% of screen height. |

**Best practice for a recording/journaling app (Blinking's category):**
The most common and effective pattern is a **collapsible calendar** with a compact "week strip" as the default state. Users primarily want to see today's content — the calendar is a navigation tool, not the destination. Key rationale:
- On first open, the user sees today's entries immediately (no scrolling past a giant calendar)
- The week strip provides enough context (this week's emotion dots, habit indicators)
- Expanding the full month is an intentional action, not the default view
- Works identically on portrait, landscape, and square screens

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Collapsible calendar (recommended)** | Default state: compact week-strip showing current week with emotion dots and habit bars. Chevron/tap to expand full month. Uses `AnimatedCrossFade` or `AnimatedContainer` for smooth transition. Persist collapse state to SharedPreferences so user preference survives restarts. | ~3h |
| **B — Landscape side-by-side layout** | Detect orientation via `MediaQuery`. In landscape (width > height), use `Row` with calendar on left (40%) and day view on right (60%). In portrait, keep current stack layout. Simpler but doesn't solve the square-screen problem and doubles the layout paths. | ~2h |
| **C — Make calendar scrollable** | Remove `NeverScrollableScrollPhysics()`, allow the calendar grid to scroll within a constrained height (e.g. `SizedBox(height: 250)`). The calendar scrolls vertically to reveal more weeks. Loses the "see full month at a glance" benefit. | ~1.5h |
| **D — Compact calendar mode** | Keep full month always visible but reduce cell sizes, font sizes, and remove emotion badges in landscape/square mode. Use `LayoutBuilder` to detect constrained height and switch to compact rendering. Still shows full month but cells are much smaller. | ~1.5h |

**Recommendation:** Option A — collapsible calendar. This is the industry standard for journaling apps. Implementation approach:
- Default collapsed state: show current week row (7 days) with emotion dots and habit progress bars. This takes ~60px instead of ~350px.
- Expanded state: show full month grid as today (current behavior).
- Chevron button in the month header row toggles state.
- Animated transition between states.
- Persist collapsed/expanded preference.
- On first launch, default to collapsed to maximize day content visibility.

**Files:** `lib/widgets/calendar_widget.dart`, `lib/screens/home/home_screen.dart`

**Questions:**
- Should the calendar default to collapsed or expanded on first launch? (Recommendation: collapsed — show today's content by default, calendar is a navigation tool)
- Should the week strip show only the current week, or allow swiping to past/future weeks within the strip?
- Should the "Today" button in the AppBar also collapse the calendar (if expanded) or only reset the date/month?

---

### 14. NEW: HomeScreen AppBar title "Calendar" is misleading

**Status:** RESOLVED
**Priority:** P2 (medium)
**Reported:** 2026-05-01
**Resolved:** 2026-05-01
**Effort:** ~15min

**Resolution:**

1. **AppBar title** changes to date-contextual format: "My Day" (EN) / "我的一天" (ZH) for today; "My Day - Apr 15" / "我的一天 - 4月15日" for past dates.
2. **Bottom nav tab label** synced from "Calendar"/"日历" → "My Day"/"我的一天" via ARB key `myDay`.
3. Null-safe fallback in `_buildTitle()` for test compatibility.

**Files:** `lib/screens/home/home_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`

**Description:**
The Home tab's AppBar title reads "Calendar" (EN) / "日历" (ZH). However, this screen contains much more than a calendar:
- A calendar grid (month navigation tool)
- Today's checklists (pinned above habits)
- Habit check-in section
- Today's notes/entries
- Emoji jar visualization

Framing the entire screen as "Calendar" misleads the user about its purpose. It's actually a **daily dashboard** — your day at a glance. The calendar is a navigation widget within it, not the primary content. New users who see "Calendar" may not realize this is where they review their day's content, habits, and mood.

**Research:**
- Title is hardcoded at `home_screen.dart:58`: `Text(isZh ? '日历' : 'Calendar')`
- The bottom nav label is already "Calendar" (ARB key) — keeping the tab label as "Calendar" is fine for navigation (it tells users which tab is the calendar picker), but the screen title should reflect the content.
- Industry practice: journaling apps typically name this screen after the primary content, not the navigation widget. Daylio calls it "Today", Day One calls it the entry date, Streaks calls it "Today".

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — "My Day" / "我的今天" (recommended)** | Reflects that this is today's personal dashboard. "My Day" implies ownership and daily focus. Distinct from the "Today" button in the AppBar. | ~15min |
| **B — "Today" / "今天"** | Simple and direct. But redundant with the "Today" button already in the AppBar (same word appears twice on screen). When viewing a past date, "Today" becomes inaccurate. | ~15min |
| **C — Keep "Calendar" / "日历"** | No change. The title reflects the primary navigation widget. Users learn the screen content through usage. | ~0h |

**Recommendation:** Option A. "My Day" works for both today and when viewing past dates (it's still "your day" — just a past one). It avoids the redundancy of "Today" and clearly communicates that this is a personal daily dashboard, not a calendar app. Implementation is a single text change in `home_screen.dart`.

**Files:** `lib/screens/home/home_screen.dart:58`

**Questions:**
- If viewing a past date (e.g. April 15), should the title change to reflect that (e.g. "My Day — Apr 15") or always stay "My Day"?
- Should the bottom nav tab label also change from "Calendar" to "My Day", or keep "Calendar" as the navigation hint?
---

### 1. BUG: Calendar allows clicking future dates and crossing habit items

**Status:** RESOLVED
**Priority:** P1 (high)
**Reported:** 2026-04-30
**Resolved:** 2026-05-01
**Effort:** ~2h

**Description:**
Users can select any date on the calendar, including future dates beyond today. They can also toggle habit completions on those future dates. This is confusing — a user can "complete" tomorrow's habits today, which breaks the habit tracking model. The calendar should visually restrict future dates and prevent interaction with them.

**Resolution — Hybrid approach (Option A + navigation limit):**

1. **Future day cells greyed out & non-interactive** (`calendar_widget.dart`):
   - Future dates render at `Opacity(0.35)`, matching the industry standard for retrospective/recording calendars (Daylio, Streaks, Day One)
   - `GestureDetector` removed for future cells — tap is a no-op
   - Today cell gets a teal border outline (`Color(0xFF2A9D8F)`) for clear orientation anchor

2. **Month navigation limited to today+2 months** (`calendar_widget.dart`):
   - `_maxNavigableMonth()` computes boundary at `today + 2 months`
   - Right chevron disabled (`IconButton.onPressed = null`) when at max month
   - Left chevron unbounded — users can navigate to any past month
   - Users can see next month's layout for mental planning but can't interact with those cells

3. **Server-side guard** (`home_screen.dart`):
   - `_onDateSelected()` rejects future dates as belt-and-suspenders safety net
   - `_getDayHabitStatus()` breaks loop early when `day.isAfter(today)`, avoiding unnecessary DB queries for future dates

**Files changed:** `lib/widgets/calendar_widget.dart`, `lib/screens/home/home_screen.dart`

---

### 2. FAB "+" icon shows on Routine tab — conflicts with routine edit flow

**Status:** RESOLVED
**Priority:** P2 (medium)
**Reported:** 2026-04-30
**Resolved:** 2026-05-01
**Effort:** ~1.5h

**Resolution — Contextual FAB (Pattern B):**

FAB now changes icon and action contextually per tab:
- **My Day & Moments** (tabs 0, 1): `+` icon → opens Add Entry screen
- **Routine** (tab 2): `Icons.playlist_add` icon → opens Add Routine dialog via `GlobalKey<RoutineScreenState>`
- **Insights & Settings** (tabs 3, 4): FAB hidden
- Redundant AppBar add button removed from RoutineScreen
- Separate `heroTag` per FAB context to prevent animation conflicts

**Research basis:** Industry standard (TickTick, HabitNow use contextual FABs). Material Design spec: FAB must represent the primary action of the current screen.

**Files:** `lib/app.dart`, `lib/screens/routine/routine_screen.dart`

---

### 3. Create card screen: "+ New Card" button overlaps "+" New Entry button

**Status:** RESOLVED (2026-05-01 — card system removed in PROP-8, no FAB overlap possible)
**Priority:** P1 (high)
**Reported:** 2026-04-30
**Resolved:** 2026-05-01
**Effort:** ~0h (resolved by PROP-8 card removal)

**Resolution:** The entire card system (Cards tab, card builder, card editor, card preview) was removed as part of PROP-8 Insights restructure. The main FAB is hidden on the Insights tab. No overlapping FABs remain.

---

### 4. PROP-7: AI Secrets lock icon on entries — UX polish

**Status:** RESOLVED
**Priority:** P3 (low)
**Reported:** 2026-04-29
**Resolved:** 2026-05-01
**Effort:** ~1h

**Resolution — Option A: Lock icon on entry card and detail screen:**

Small grey `Icons.lock_outline` (14px, `Colors.grey`) appears on entry cards (`_buildHeader` and `_buildListHeader`) and the EntryDetailScreen AppBar title area when an entry has the `tag_secrets` tag. Positioned between emotion emoji and share icon on cards. Subtle and informational — not tappable.

Also fixed an overflow bug: EntryDetailScreen title `Row` caused 4px overflow with lock icon + date string when 3 action buttons were visible. Fixed by wrapping date `Text` in `Flexible` with `TextOverflow.ellipsis`.

**Files:** `lib/widgets/entry_card.dart`, `lib/screens/moment/entry_detail_screen.dart`

**Description:**
The "Secrets" (私密) system tag allows users to mark entries as private. Entries tagged with Secrets are excluded from AI assistant context. However, there is no visual indicator on entries in the Moments list, Calendar day view, or Entry Detail screen to show which entries are private. A user cannot tell at a glance which of their entries the AI can or cannot access.

**Research:**
- `Entry` model has `tagIds: List<String>`. The Secrets tag ID is `tag_secrets` (stable ID per CLAUDE.md).
- `EntryCard` widget renders in HomeScreen, MomentScreen, and EntryDetailScreen.
- The AI exclusion happens in `AssistantScreen._filterEntriesInRange()` — works correctly.
- The lock icon would show on `EntryCard` and `EntryDetailScreen`.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Lock icon on entry card (recommended)** | Add a small `Icons.lock` (🔒) icon to the trailing edge or top-right of `EntryCard` when the entry has the `tag_secrets` tag. Grey/subdued color to be subtle. Same icon on `EntryDetailScreen` AppBar. | ~1h |
| **B — Tag chip with lock** | Render the "Secrets" tag as a visible chip/badge on the entry card with a lock icon prefix. More prominent, occupies more space. | ~1.5h |
| **C — Visual treatment (background tint)** | Apply a subtle background tint or left border accent to private entries instead of an icon. Less conventional, harder to interpret at a glance. | ~1.5h |

**Recommendation:** Option A. A small `Icons.lock_outline` in the top-right or trailing edge of the entry card. Subtle, universally understood, and consistent with the entry detail screen (icon in AppBar or near the Secrets tag). Use `Colors.grey` or theme's `hintColor` so it doesn't compete with the emotion emoji or content.

**Files:** `lib/widgets/entry_card.dart`, `lib/screens/moment/entry_detail_screen.dart`

**Questions:**
- Should the lock icon be tappable (to remove the Secrets tag) or purely informational?
- Where exactly on the card: top-right corner, next to the emotion emoji, or inline with the tag chips?

---

### 5. PROP-8: Keepsakes tab restructure → Insights

**Status:** RESOLVED
**Priority:** P3 (low)
**Reported:** 2026-04-29
**Resolved:** 2026-05-01
**Effort:** ~3.5h (expanded scope)

**Resolution — Full restructure (Option C):**

The Keepsakes tab (珍藏) was replaced with a focused Insights tab (洞察). Scope expanded beyond a simple rename:

1. **Removed:** Emotion jar shelf browsing, yearly/monthly jar drill-down, card creation and editing, formatted keepsake card grid, "Make card" button from Moments screen, `flutter_quill` dependency
2. **Kept:** Summary charts (4 chart types), yearly emoji jar carousel on Insights screen, HomeScreen emoji jar widget (with `JarProvider`)
3. **New:** Single-scroll Insights screen with horizontal jar carousel at top + scope-picked charts below. Floating AI robot now appears on Insights tab. Main "+" FAB hidden on Insights and Settings tabs.
4. **Preserved behind-the-scenes:** `CardProvider`, card models, and DB tables keep existing data intact — no migration, no data loss. Files kept but provider unregistered.

**Files changed:** `app.dart`, `cherished_memory_screen.dart` (rewritten), `moment_screen.dart`, `floating_robot.dart`, `models.dart`, ARB files, `pubspec.yaml`. 8 files deleted, 22 transitive deps cleaned up. 96/96 tests pass.

---

### 6. NEW: HomeScreen list/notes visual separation after PROP-9

**Status:** NOTED — section headers already exist
**Priority:** P2 (medium)
**Reported:** 2026-05-01
**Effort:** ~0h

**Resolution:** Section headers were already in place from PROP-9 implementation: "📋 Lists" / "📋 今日清单", "✅ Habit Check-in" / "✅ 习惯打卡", "📝 Notes" / "📝 笔记". No further action needed.

**Description:**
PROP-9 introduced daily checklist entries that are pinned above habits in the Calendar day view. The HomeScreen now shows sections for Lists and Notes, with lists appearing above habits. However, the visual separation between these sections may not be clear enough — users may not immediately understand why some entries are at the top (lists) and others are below (notes). Additionally, list entries use a different card layout (checkboxes, "X/Y done" counter) that may not be visually distinct enough from regular note cards.

**Research:**
- `HomeScreen._buildDaySection()` splits entries into lists and notes. Lists are rendered first, then habits, then notes.
- List entries use `EntryCard` with checkbox rendering, strikethrough on done items, and "X/Y done" counter.
- Note entries use `EntryCard` with content preview.
- No section header distinguishes "Today's List" from "Today's Notes."

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Add section headers (recommended)** | Add subtle section headers: "✓ Today's List" above list entries, "📝 Notes" above note entries on the HomeScreen day view. Headers only appear when there are entries in both sections. Bilingual via ARB. | ~1.5h |
| **B — Visual card styling difference** | Give list entries a distinct background color (e.g. subtle teal tint) or left border accent to visually separate them from notes. No text headers. | ~1h |
| **C — No change, trust the layout** | The pinning (lists above habits) is sufficient. Users will learn the pattern over time. | ~0h |

**Recommendation:** Option A. Section headers provide clear information architecture with minimal visual weight. They only appear when needed (both sections have content). This follows the same pattern as the HomeScreen's existing Layout structure.

**Files:** `lib/screens/home/home_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`

**Questions:**
- Should the "Today's List" header be collapsible (tap to hide/show list items)?
- Should we show a subtle "No list for today — tap + to create one" prompt when there's no list entry?

---

### 7. NEW: Calendar list badge indicator (days with checklist)

**Status:** REJECTED
**Priority:** P3 (low)
**Reported:** 2026-05-01
**Resolved:** 2026-05-03
**Effort:** ~0h

**Resolution:** Feature rejected. Adding a checklist icon/indicator to calendar day cells would make the calendar view too crowded (it already shows emotion emojis and habit dots). The Moment timeline provides a complete list/notes view with type-differentiated icons.

**Description:**
The calendar grid currently shows emotion emoji badges and habit completion dots on each day cell. However, there is no indicator for days that have checklist entries. The PROP-9 design document noted this as a "nice-to-have": "A subtle ☑ indicator on calendar days that have a list entry." Without this, users can't see which past days had lists without navigating into each day.

**Research:**
- `CalendarWidget` in `lib/widgets/calendar_widget.dart` renders day cells with emotion badges and habit status dots.
- `HomeScreen._getDayEmotions()` and `_getDayHabitStatus()` provide data to the calendar. There is no equivalent for list entries.
- `EntryProvider.getEntriesForDate(date)` can be used to check for list entries on each day, but calling it for every day in the month grid (28-31 calls) could be expensive.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Pre-compute list days map** | In `HomeScreen`, compute a `Map<DateTime, bool>` once per build that indicates which days have list entries. Pass to `CalendarWidget` to render a small "☑" below the emotion emoji. | ~1.5h |
| **B — Query on-demand in calendar cell** | In each day cell, query `EntryProvider.getEntriesForDate(date)` and check for lists. Simple but potentially slow (28+ queries per month grid render). | ~30min |
| **C — Defer to v1.2** | Keep the calendar clean. Users can discover lists by navigating into each day. The emotion emoji + habit dots already provide meaningful per-day information. | ~0h |

**Recommendation:** Option A. Pre-compute once and pass down. The performance impact is negligible (one query filtered by date range + format check). The ☑ indicator should be very small (font-size 8-10px) and positioned below the emotion emoji. Use `check_box_outline_blank` icon or the ☑ character.

**Files:** `lib/widgets/calendar_widget.dart`, `lib/screens/home/home_screen.dart`

**Questions:**
- Should the ☑ indicator change appearance (e.g. fill color) based on whether the list was completed (all items done) vs. partially completed?
- Should we use the ☑ unicode character or an `Icons` widget to ensure consistent rendering across platforms?

---

### 8. NEW: Floating robot trial/error states UX clarity

**Status:** MOVED — see `docs/plans/2026-05-03-trial-purchase-flow-design.md`
**Priority:** P2 (medium)
**Reported:** 2026-05-01
**Effort:** ~1h

**Resolution:** Deferred to a comprehensive App Trial and Purchase Flow Design covering both the floating robot (Issue #8) and Settings trial banner (Issue #12). These two touchpoints will be designed together for a coherent trial→purchase flow.

**Description:**
The floating robot has multiple visual states based on trial/API key status:
- **Active:** Full opacity, bobbing animation, tap opens AssistantScreen.
- **No API key:** 50% opacity, no animation, "!" badge, tap shows snackbar.
- **Trial active:** Full opacity, tap opens AssistantScreen.
- **Trial expired:** 50% opacity with expired badge, tap shows snackbar.

The current implementation may have edge cases: what does the robot show during the transition between states (e.g., right after trial expires while app is open)? Is the "!" badge visible enough? Does the expired state clearly communicate that the user needs to add their own key?

**Research:**
- `FloatingRobotWidget` in `lib/widgets/floating_robot.dart` watches `LlmConfigNotifier` to re-check API key status.
- Trial state is checked via `TrialService.getTrialStatus()`.
- The expired badge/behavior was added in PROP-6.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Add transition states + tooltip (recommended)** | Ensure robot shows a clear "expired" badge (small clock icon with "EXPIRED" text). Add a long-press tooltip explaining what to do ("Tap Settings → AI Providers to add your own API key"). Ensure re-check happens on app resume (not just tab switch). | ~1h |
| **B — Hide robot entirely when trial expired** | When trial is expired and no API key, hide the robot completely. Clean but reduces discoverability of the AI feature for users who might want to add their own key. | ~30min |
| **C — Leave as-is** | The current implementation covers the main states. Edge cases around transition timing are minor. | ~0h |

**Recommendation:** Option A. Add polish to the expired state — a small badge, a tooltip with actionable text, and ensure state re-checks on app lifecycle events (resume). This ensures users understand why the robot changed and what to do about it.

**Files:** `lib/widgets/floating_robot.dart`

**Questions:**
- Should the robot in "expired" state also have a different animation (e.g. slow/sad bounce vs. no animation)?
- Should tapping the expired/sad robot take the user directly to Settings → AI Providers instead of showing a snackbar?

---

### 9. NEW: One-list-per-day UX — transition feels jarring

**Status:** RESOLVED
**Priority:** P3 (low)
**Reported:** 2026-05-01
**Resolved:** 2026-05-03
**Effort:** ~45min

**Resolution:** When toggling Note→List and a list already exists for today, a snackbar ("Today's list already exists — opening it") appears before a smooth 300ms fade transition to the existing list. Snackbar auto-dismisses after 800ms. New i18n key `listAlreadyExistsHint`.

**Description:**
PROP-9 enforces one list per day. If the user already has a list for today and tries to create another via the Note/List toggle in `AddEntryScreen`, the app uses `pushReplacement` to navigate to the existing list in edit mode. This is functionally correct, but the screen transition (pushReplacement without a hero animation) may feel jarring or confusing — the user toggled a segmented button and suddenly the entire screen replaced itself with a different view.

**Research:**
- `AddEntryScreen._switchFormat()` in `lib/screens/add_entry_screen.dart` checks for existing lists and calls `pushReplacement`.
- The replacement navigates to the same `AddEntryScreen` but with the existing entry loaded for editing.
- No transition animation or explanation is provided to the user about why the screen changed.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Show a brief dialog or snackbar (recommended)** | Before navigating, show a brief snackbar: "You already have a list for today — opening it now" / "今天已有清单，正在打开". Then navigate with a smooth fade or slide transition. | ~45min |
| **B — Fade transition instead of pushReplacement** | Use a custom `PageRouteBuilder` with a crossfade or slide animation to make the transition feel intentional rather than abrupt. | ~1h |
| **C — Disable the List toggle when a list exists** | Grey out or disable the "List" option in the SegmentedButton when today already has a list entry. Add a tooltip explaining why. | ~30min |

**Recommendation:** Option A. A snackbar provides instant context before the transition. Combine with a fade transition for smoothness. This is quick to implement and clearly communicates what happened.

**Files:** `lib/screens/add_entry_screen.dart`

**Questions:**
- Should the snackbar auto-dismiss (they do by default) or be an action snackbar with an "Open" button the user must tap?
- Should we also update the "List" segment button to show a checkmark or "Edit" label when a list already exists?

---

### 10. NEW: Carry-forward banner timing — may be missed by users

**Status:** RESOLVED
**Priority:** P3 (low)
**Reported:** 2026-05-01
**Resolved:** 2026-05-03
**Effort:** ~30min

**Resolution:** Removed the auto-clear carry-forward banner entirely. After the carry-forward redesign (explicit user dialog + "Yesterday" labels on individual items), the banner became redundant. The explicit dialog ensures the user knows items were carried. The `fromYesterdayLabel` on each item provides a persistent indicator. Cleanup: removed `_lastCarriedCount`, `clearCarriedBanner()`, `carriedOverCount` param from `EntryCard`, `_buildListEntryCards()` method, and `_buildCarriedOverBanner()` widget.

**Description:**
The carry-forward banner ("X items carried over from yesterday") appears on the carried-forward EntryCard and auto-clears via `WidgetsBinding.instance.addPostFrameCallback` in HomeScreen. Since it clears on the next frame after rendering, a user who opens the app and immediately scrolls or navigates away may never see the banner. Additionally, the banner is only shown on the EntryCard within the Calendar day view — users who primarily use the Moments tab may never see it.

**Research:**
- `EntryProvider._lastCarriedCount` is set during carry-forward and read by `HomeScreen`.
- Banner auto-clears via `postFrameCallback` → `EntryProvider.clearCarriedBanner()`.
- Only the HomeScreen (Calendar tab) displays the banner.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Persist banner until user dismisses or views the list (recommended)** | Instead of auto-clearing on next frame, keep the banner visible until: (a) user taps the carried-forward entry to view/edit it, or (b) user explicitly dismisses with an "×" button. Show the banner in Moments tab too. | ~30min |
| **B — Extend banner display time** | Keep the postFrameCallback approach but add a longer delay (e.g. 3 seconds) before auto-clear. Still risky for fast-navigating users. | ~15min |
| **C — Leave as-is** | The banner is a nice-to-have notification. Users can see carried items by comparing today's list with yesterday's in the Moments feed. | ~0h |

**Recommendation:** Option A. The banner should persist until the user engages with the carried-forward list. This ensures they don't miss it regardless of navigation speed. Also add the banner to the Moments tab entry card for completeness.

**Files:** `lib/screens/home/home_screen.dart`, `lib/widgets/entry_card.dart`, `lib/providers/entry_provider.dart`

**Questions:**
- Should the banner also appear as a system notification (push notification) when the app is opened after midnight?
- Should we add a "Dismiss all" option for users who don't want to see carry-forward banners?

---

### 11. NEW: List edit screen vs Calendar detail screen — duplicate checkbox UX

**Status:** RESOLVED
**Priority:** P3 (low)
**Reported:** 2026-05-01
**Resolved:** 2026-05-03
**Effort:** ~1h

**Resolution — Option A: Differentiate screens by purpose with subtle hints.**
1. **AddEntryScreen list editor:** Helper text below title ("Tap to check · Drag to reorder · × to remove") appears when items exist. Drag handle enlarged from 20px to 24px for better discoverability.
2. **EntryDetailScreen:** Added "Checklist · X/Y done" subtitle below title to distinguish list detail from note detail at a glance.
3. New i18n keys: `listEditHint`, `listDetailSubtitle`.

**Description:**
After PROP-9, there are now three places where list checkboxes can be toggled:
1. **HomeScreen EntryCard** — tappable checkboxes with strikethrough on done items.
2. **EntryDetailScreen** — read-only view with tappable checkboxes.
3. **List edit screen** (via `AddEntryScreen` with list format) — editable checkboxes with reorderable list.

The list edit screen was updated in commit `2c3fd94` to match the Calendar display pattern (checkbox + strikethrough). However, the list edit screen also has the reorderable handle, making it a different interaction model. Users might be confused about which screen to use for what: edit content vs. check items vs. reorder.

**Research:**
- `AddEntryScreen` list mode has a title field, item-entry bar, and `ReorderableListView` with checkboxes + drag handles.
- `EntryDetailScreen` list view has checkboxes but no reorder or edit capabilities.
- `EntryCard` list view is compact and has tappable checkboxes only.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Differentiate screens by purpose (recommended)** | Add short helper text or tooltips: "Tap to check" on detail/card views, "Tap to check, drag to reorder" on edit screen. Consider making the edit screen's reorder handle more prominent (e.g. `Icons.drag_handle` icon instead of relying on long-press). | ~1h |
| **B — Add a "quick check" mode to Calendar** | On the HomeScreen day view, allow checking list items inline without opening any screen. The edit screen is only for adding/removing/reordering items. | ~3h |
| **C — Leave as-is** | Users will naturally discover the differences. The visual consistency (all use same checkbox+strikethrough) is the most important thing, and it's already done. | ~0h |

**Recommendation:** Option A. Subtle contextual hints differentiate the interaction models without adding complexity. The drag handle on the edit screen should be more obvious (visible icon, not just long-press discovery).

**Files:** `lib/screens/add_entry_screen.dart`, `lib/screens/moment/entry_detail_screen.dart`

**Questions:**
- Should the Calendar day view allow inline item toggling (Option B), or is opening the detail screen sufficient?
- Is the reorder functionality on the edit screen intuitive enough, or should we add an explicit "Reorder" mode toggle?

---

### 12. NEW: Settings trial banner — location and dismissal UX

**Status:** MOVED — see `docs/plans/2026-05-03-trial-purchase-flow-design.md`
**Priority:** P3 (low)
**Reported:** 2026-05-01
**Effort:** ~45min

**Resolution:** Deferred to a comprehensive App Trial and Purchase Flow Design covering both the floating robot (Issue #8) and Settings trial banner (Issue #12). These two touchpoints will be designed together for a coherent trial→purchase flow.

**Description:**
The Settings screen has a trial banner that shows trial status ("X days remaining" or "Trial expired"). The banner's placement and dismissibility need review: Can users dismiss it? If the trial is expired and the user has added their own API key, does the banner still show the expired trial? Does the banner compete visually with other Settings items?

**Research:**
- Introduced in PROP-6.
- `TrialService` manages trial lifecycle.
- Settings screen renders a trial banner conditionally based on trial state.

**Options:**

| Option | Description | Effort |
|--------|-------------|:------:|
| **A — Dismissible + contextual banner (recommended)** | Allow users to dismiss the trial banner once they've seen it. If they add their own API key, hide the trial banner entirely (the user has moved on from trial). Only show the banner when trial is active and the user hasn't set up their own key yet. | ~45min |
| **B — Keep banner until trial expires** | Banner persists until the 7-day trial ends, then converts to "Trial expired" state. User cannot dismiss it. Simple but potentially annoying for users who have already set up their own key. | ~0h (current behavior) |
| **C — Remove banner entirely, show in robot instead** | Move all trial status information to the floating robot (badge, tooltip). Settings stays clean. Trial status is only visible where the AI feature is accessed. | ~1h |

**Recommendation:** Option A. Once a user adds their own API key, the trial banner should be dismissible or auto-hide. The banner serves its purpose (encourage trial activation) and should not become a permanent UI element.

**Files:** `lib/screens/settings/settings_screen.dart`

**Questions:**
- Should the trial banner show a "Don't show again" option, or auto-hide once dismissed?
- Should there be a way to re-activate the trial banner view (e.g. for users who want to switch back to trial)?

---

## Summary Table

| # | Issue | Priority | Effort | Status |
|---|-------|:--------:|:------:|--------|
| 1 | Calendar future date interaction | P1 | ~2h | ✅ RESOLVED |
| 2 | FAB on Routine tab — now contextual | P2 | ~1.5h | ✅ RESOLVED |
| 3 | "+ New Card" vs "+ New Entry" FAB overlap | P1 | ~0h | ✅ RESOLVED (cards removed) |
| 4 | AI Secrets lock icon (PROP-7) | P3 | ~1h | ✅ RESOLVED |
| 5 | Keepsakes tab restructure → Insights (PROP-8) | P3 | ~3.5h | ✅ RESOLVED |
| 6 | HomeScreen list/notes section headers | P2 | ~0h | ✅ NOTED (already exist) |
| 7 | Calendar list badge indicator | P3 | ~0h | ❌ REJECTED (too crowded) |
| 8 | Robot trial/error state clarity | P2 | ~1h | 📋 MOVED to trial/purchase design |
| 9 | One-list-per-day transition UX | P3 | ~45min | ✅ RESOLVED |
| 10 | Carry-forward banner timing | P3 | ~30min | ✅ RESOLVED (removed) |
| 11 | List checkbox UX consistency | P3 | ~1h | ✅ RESOLVED |
| 12 | Settings trial banner dismiss | P3 | ~45min | 📋 MOVED to trial/purchase design |
| 13 | Calendar grid too large in landscape/square | P1 | ~3h | ✅ RESOLVED |
| 14 | HomeScreen title "Calendar" → "My Day" | P2 | ~15min | ✅ RESOLVED |
| **Total resolved** | | | | **10 of 14** |
| **Rejected** | | | | **1 (Issue #7)** |
| **Moved to new plan** | | | | **2 (Issues #8, #12)** |

---

## What Remains (from original 14)

| # | Issue | Priority | Status |
|---|-------|:--------:|--------|
| 8 | Robot trial/error state clarity | P2 | 📋 Moved to `docs/plans/2026-05-03-trial-purchase-flow-design.md` |
| 12 | Settings trial banner dismiss | P3 | 📋 Moved to `docs/plans/2026-05-03-trial-purchase-flow-design.md` |

All P1/P2/P3 UX issues from the original 14 are now either resolved, rejected, or moved to a dedicated design plan. No blocking items remain.

---

## New Items (Post-Launch Polish Complete)

### 15. NEW: Enhance UI for Insight tab

**Status:** PENDING (design doc created)
**Priority:** P2 (medium)
**Reported:** 2026-05-03
**Effort:** ~6.5h (cosmetic ~2.5h, content ~4h)

**Description:**
The Insights tab (洞察) currently shows a yearly mood jar carousel + 4 charts behind a Day/Week/Month scope picker. While functional, it lacks visual hierarchy (hero stats, calendar heatmap), engagement hooks (streaks, correlations), and the competitive polish seen in Daylio/Reflectly/Streaks. The tab should be the app's **value proposition showcase**, not just raw charts.

**Resolution Plan:**
See `docs/plans/2026-05-03-insights-tab-enhancement.md` for full competitive benchmark and detailed design covering:

**Phase 1 — Cosmetic (~2.5h):**
- C1: Hero stats cards (total entries, streak, habit rate, today's mood)
- C2: Calendar heatmap (GitHub-style contribution grid)
- C3: Mood distribution donut chart
- C4: Visual hierarchy & polish (section cards, spacing, scope picker redesign)

**Phase 2 — Content (~4h):**
- CT1: Writing streak & stats (avg words, longest streak, most active day)
- CT2: Checklist analytics (completion rate, top items)
- CT3: Mood-tag correlation (which tags correlate with better moods — Daylio's killer feature)
- CT4: AI-generated personalized insights (LLM-powered text takeaways)

**No DB changes required** — all new data dimensions computed from existing tables.
**Files:** `cherished_memory_screen.dart` (major rewrite), `summary_provider.dart` (8 new getters), ARB files (~15 new i18n keys)

**Industry benchmark included:** Daylio, Reflectly, Streaks, Day One, HabitNow.

---

## Updated Summary Table

| # | Issue | Priority | Effort | Status |
|---|-------|:--------:|:------:|--------|
| 1 | Calendar future date interaction | P1 | ~2h | ✅ RESOLVED |
| 2 | FAB on Routine tab — now contextual | P2 | ~1.5h | ✅ RESOLVED |
| 3 | "+ New Card" vs "+ New Entry" FAB overlap | P1 | ~0h | ✅ RESOLVED (cards removed) |
| 4 | AI Secrets lock icon (PROP-7) | P3 | ~1h | ✅ RESOLVED |
| 5 | Keepsakes tab restructure → Insights (PROP-8) | P3 | ~3.5h | ✅ RESOLVED |
| 6 | HomeScreen list/notes section headers | P2 | ~0h | ✅ NOTED (already exist) |
| 7 | Calendar list badge indicator | P3 | ~0h | ❌ REJECTED (too crowded) |
| 8 | Robot trial/error state clarity | P2 | ~1h | 📋 MOVED to trial/purchase design |
| 9 | One-list-per-day transition UX | P3 | ~45min | ✅ RESOLVED |
| 10 | Carry-forward banner timing | P3 | ~30min | ✅ RESOLVED (removed) |
| 11 | List checkbox UX consistency | P3 | ~1h | ✅ RESOLVED |
| 12 | Settings trial banner dismiss | P3 | ~45min | 📋 MOVED to trial/purchase design |
| 13 | Calendar grid too large in landscape/square | P1 | ~3h | ✅ RESOLVED |
| 14 | HomeScreen title "Calendar" → "My Day" | P2 | ~15min | ✅ RESOLVED |
| **15** | **Enhance UI for Insight tab** | **P2** | **~6.5h** | **🆕 Phase 1 done, Phase 2 designed** |
| **Total resolved** | | | | **10 of 14** |
| **Rejected** | | | | **1 (Issue #7)** |
| **Moved to new plan** | | | | **2 (Issues #8, #12)** |
| **New — Phase 1 done** | | | | **1 (Issue #15)** |

---

## Launch-Ready Status

All original UX issues resolved (10/14), rejected (1), or moved to dedicated design (2). No blocking items.
The app is ready for:
1. **PROP-3:** Promote Android to Production on Google Play (~15min manual)
2. **Post-launch:** Monitor crash reports, reviews, trial usage
3. **Post-launch v1.1.1:** Enhance Insights tab UI (Issue #15, designed, ~6.5h)

---

## Current Clarification Questions (2026-05-03)

1. **Issue #15 (Insights tab):** Proceed with Phase 1 (cosmetic ~2.5h) before launch or defer to v1.1.1?
2. **Issue #15 hero cards:** Which 4 stats to show? (entries, streak, habit rate, mood — or different set?)
3. **Issue #15 calendar heatmap:** All-time with horizontal scroll or last 6 months constrained?
4. **Issue #15 AI insights:** Generate on-demand (Refresh button) or auto? Auto risks API cost for BYOK users.
5. **PROP-3:** Promote Android to Production now or address insight tab first?
