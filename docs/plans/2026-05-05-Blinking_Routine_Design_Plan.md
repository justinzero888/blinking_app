# Blinking Routine — Design Plan v1.2

**Status:** Updated — Tab Names Confirmed  
**Date:** May 2026  
**Scope:** Routine section redesign across Build, Do, and Reflect tabs  
**Changes from v1.1:** Tab names updated to **Build · Do · Reflect**

---

## Design Principles

Three foundational redefinitions of each tab's purpose:

| Tab | Redefined Role | Default? |
|-----|---------------|----------|
| **Build** | Management console — own, configure, and curate your habits | No |
| **Do** | Progress surface — see and act on today's habits | **Yes** |
| **Reflect** | Archive and reflection — what was done, with context from notes | No |

These three tabs represent a natural lifecycle: **Build → Do → Reflect.**

One overriding principle across all three tabs: **simplification.** Small, focused interactions. Complexity lives in notes, not in UI states.

---

## Tab 1 — Build (Management Console)

### Current Gaps
- No way to activate or deactivate a habit without deleting it
- No description or personal "why" for any habit
- Two competing FABs create visual confusion
- Empty state provides no guidance
- Flat list with no organisation

### Proposed Design

#### 1.1 Active / Inactive Toggle

Each habit card gains a toggle switch. Inactive habits are visually subdued (reduced opacity, no teal accent) and excluded from the Do tab. Their history is preserved, but the streak resets to zero on deactivation — resuming the habit starts a new streak from day one.

**Active card:**
```
┌──────────────────────────────────────────────┐
│  🏃  Morning Run         streak: 12 days     │
│      Daily · 7:00 AM                   [ON]  │
│      "I run to clear my head"                │
└──────────────────────────────────────────────┘
```

**Inactive card:**
```
┌──────────────────────────────────────────────┐  ← 50% opacity
│  🏃  Morning Run         paused              │
│      Daily · 7:00 AM                   [OFF] │
│      "I run to clear my head"                │
└──────────────────────────────────────────────┘
```

**Streak behaviour on pause:**  
Toggling a habit inactive resets the streak to zero immediately. When the user re-activates the habit, the streak counter starts fresh from day one. The all-time best streak is always preserved and displayed separately. This is intentionally strict — a pause is a real break, not a freeze. The grace period (see Streak Grace Period section) does not apply to inactive habits.

#### 1.2 Personal "Why" Description

An optional free-text field added to the add/edit modal: **"Why does this matter to you?"**

- Maximum 120 characters
- Displayed as a subtitle on the card in italics, secondary colour
- Placeholder: *"Add your reason — it helps you stick to it"*
- Behavioural basis: written implementation intentions measurably improve habit follow-through (Gollwitzer, 1999; Milkman et al., 2021)

#### 1.3 Edit Modal — Updated Fields

| Field | Type | Status |
|-------|------|--------|
| Habit name | Text | Existing |
| Icon | Picker | Existing |
| Frequency | Selector | Existing |
| Reminder time | Time picker | Existing |
| Personal why | Text area (120 chars) | **New** |
| Active status | Toggle | **New** |

#### 1.4 Resolve the Dual-FAB Problem
- Single **+** FAB for adding a habit
- AI / robot assistant button moves to a banner card at list top ("Explore habit suggestions →") or into the ⋮ overflow menu
- Primary action on a management screen should be unambiguous: add habit

#### 1.5 List Organisation

Two sections: **Active** (full opacity, teal accents) → **Paused** (below a divider, muted). Within each section, user-defined drag-to-reorder. A count badge on the tab or section header: *"5 active habits."*

#### 1.6 Empty State

```
┌──────────────────────────────────────────┐
│                                          │
│   🌱                                     │
│                                          │
│   Start building your routine            │
│   Small habits, done consistently,       │
│   create lasting change.                 │
│                                          │
│   [ + Add your first habit ]             │
│                                          │
└──────────────────────────────────────────┘
```

---

## Tab 2 — Do (Progress Surface)

### Current Gaps
- Not the default tab
- No completion affordance — the single most critical missing interaction
- Visual hierarchy inverted (completed cards more prominent than pending)
- No motivational signal
- "Daily" label is redundant when all visible habits are daily

### Proposed Design

#### 2.1 Make Do the Default Tab

On every app open after initial setup, land on Do. The Build tab is accessed by tapping it. This matches the primary daily use case: check progress, log completions.

| Entry point | Default tab |
|-------------|------------|
| First-ever open | Build (onboarding) |
| Every subsequent open | **Do** |
| Home widget tap | Do |
| Reminder notification tap | Do, scrolled to that habit |

#### 2.2 Completion Affordance (Critical)

Tap a pending habit card to mark it complete. This is the primary interaction — it must be obvious, not discoverable.

**States:**

```
PENDING (full colour, teal accent):
┌──────────────────────────────────────────────┐
│  ○  Morning Run                    7:00 AM   │
└──────────────────────────────────────────────┘

COMPLETED (muted, moves to Done section):
┌──────────────────────────────────────────────┐
│  ✓  Morning Run                    Done      │
└──────────────────────────────────────────────┘
```

On completion: brief card flash animation, light haptic feedback. Card moves to the "Done" section below. **Real-time sync:** this completion propagates instantly to the My Day (main) tab, the Do progress bar, and the Reflect calendar — no refresh required.

#### 2.3 Correct Visual Hierarchy
- **Pending**: full teal, normal opacity, prominent
- **Completed**: desaturated, reduced opacity, visually recessive
- This matches universal task-app convention and aligns with the user's goal: finish what's pending

#### 2.4 Section Structure

```
Do — Tuesday, 6 May

  PROGRESS:  ████████░░░░  3 of 5 done

  ─── Still to do ──────────────────────
  ○  Meditate                  8:00 AM
  ○  Evening Walk              9:00 PM

  ─── Done today ───────────────────────
  ✓  Morning Run               Done
  ✓  Vitamins                  Done
  ✓  Journal                   Done
```

#### 2.5 Progress Header

- Date line: "Tuesday, 6 May"
- Horizontal progress bar with completion count: "3 of 5 done"
- Mirrors (and links to) the My Day tab summary — the Do tab is the deeper view of that same data
- On 100% completion: "All done today ✓" replaces the bar, fades after 3 seconds

#### 2.6 Motivational Micro-copy

Single line, secondary colour, beneath the header. No emoji.

| Time of day | Copy |
|-------------|------|
| Before noon | "Good morning. Here's your day." |
| Noon–6 PM | "Afternoon check-in. Keep going." |
| After 6 PM | "Almost done for the day." |
| 100% complete | "That's everything. Well done." |

#### 2.7 Connecting Habits to Notes via Tags

After completing a habit, a small secondary action appears below the checkmark: **"Add a note →"**

Tapping opens a Moments-style note entry pre-tagged with the habit's tag. This uses the app's existing tagging structure — no new schema. The tag links the note to the habit for display in the Reflect detail view.

Example: Completing "Morning Run" opens a note pre-tagged `#morning-run`. In Reflect, all notes carrying that tag appear inline in the habit's timeline.

This is the highest-leverage feature for Blinking's identity: it turns a completion checkmark into a reflective record. It reinforces the simplification principle — one tag, everything connected.

---

## Tab 3 — Reflect (Archive & Reflection)

*Tab renamed from "History" to "Reflect."*

### Current Gaps
- Hollow circles cannot distinguish completed / missed / paused / not-yet-created / no data
- No actual analytics or context
- Wall of identical circles is visually demotivating
- No connection to notes or tags

### Proposed Design

#### 3.1 Resolve Circle Ambiguity — Three-State Encoding

The skip state is removed entirely. Users who want to explain a miss write a note — the notes system handles nuance, the UI stays simple.

| State | Symbol | Colour | Meaning |
|-------|--------|--------|---------|
| Completed | ● filled circle | Teal | Done |
| Missed | ✕ small cross | Warm coral | Existed, not done |
| Inactive that day | · small dot | Light grey | Habit was paused |
| Not yet created | (blank) | — | Habit didn't exist yet |

A collapsible legend sits at the top of the calendar on first view, then auto-hides.

#### 3.2 Per-Habit Summary Cards

Below the calendar grid, a scrollable list of per-habit summary cards:

```
┌────────────────────────────────────────────────┐
│  🏃  Morning Run                               │
│                                                │
│  Current streak    Best streak    This month   │
│      12 days          31 days       18 / 22    │
│                                                │
│  ███████████████░░░░░  82% completion          │
│                                                │
│  Strongest: Monday  ·  Weakest: Friday         │
│                                                │
│  [ View detail → ]                             │
└────────────────────────────────────────────────┘
```

#### 3.3 Single-Habit Detail View

Tapping "View detail" opens a dedicated screen:

- **Calendar heatmap** (12 months) — intensity = consistency
- **Weekly bar chart** (last 8 weeks) — trend direction visible at a glance
- **Day-of-week breakdown** — which days you succeed / miss most
- **Tagged notes** — all Moments entries carrying this habit's tag, shown chronologically, in full

The tagged notes section is the connective tissue between doing (Do) and reflecting (Reflect). No new data model needed — it is a filtered view of existing notes by tag.

#### 3.4 Period Summary at Top of Reflect

```
  May 2026

  Total completions    152
  Best streak          12 days  (Morning Run)
  Most consistent      Vitamins   96%
  Needs attention      Evening Walk   41%
```

Time period selector: Week / Month / All Time.

"Needs attention" appears only when a habit falls below 50% for the period. Neutral framing — not an alert, just a signal.

---

## Streak Grace Period — Analysis & Recommendation

*This section addresses how long a habit streak should be protected after a missed day.*

### How Leading Apps Handle It

**Duolingo — Purchasable Freeze (1 day)**  
A "Streak Freeze" consumable item protects the streak for exactly one missed day. Must be equipped before the miss — cannot be applied retroactively. Mechanical and transactional: streak protection as a reward economy. Works for Duolingo's gamified model but feels out of place in a reflective app.

**Streaks (iOS) — Flexible Frequency, No Grace Period**  
Avoids the grace period problem by letting users set habits as "X times per week" rather than "every day." Elegant but shifts complexity into setup and removes the motivational clarity of a daily streak.

**Habitica — No Grace Period, Punitive**  
Miss a daily task and your character loses HP. No forgiveness. Effective for a small audience who wants strict accountability; research shows it increases drop-off significantly for average users.

**Headspace / Calm — No Streaks as Primary Metric**  
De-emphasise streaks in favour of total sessions or "mindful days." Compassionate but reduces the motivational pull of streak mechanics.

**Loop Habit Tracker — Habit Score (Exponential Average)**  
Replaces streaks with a continuous score — an exponential moving average of completions. Behaviourally honest but emotionally flat.

**Finch & Reflectly — Compassion-First Framing**  
Show streaks but respond to breaks with encouraging copy rather than mechanical grace periods. The number resets, but the tone doesn't punish.

### Behavioural Research Perspective

- **"Never Miss Twice"** (James Clear, *Atomic Habits*): Missing once is normal and inconsequential. Missing twice starts to establish a pattern of not doing the habit. A 1-day automatic grace aligns with this.
- **"Fresh Start Effect"** (Milkman et al.): People are more motivated to restart after temporal landmarks — new week, new month.
- **Streak Anxiety**: Long streaks increase anxiety about breaking them, which can itself cause avoidance. Grace periods reduce anxiety without removing motivation.
- **Intrinsic vs. Extrinsic Motivation**: Grace periods that require user action maintain intrinsic engagement better than fully automatic systems.

### Recommendation for Blinking

A three-tier grace period that aligns streak mechanics with Blinking's journaling identity:

**Tier 1 — Automatic (1 day, no action required)**  
Miss a day and the streak does not break until the following day. The user sees a subtle indicator on the Do tab: *"Yesterday's [habit] is still open — tap to log it."*

**Tier 2 — Note-earned (up to 2 additional days)**  
Within the grace window, write a reflection note tagged to the habit. Each note extends the grace period by one day, up to 2 additional days. The note can say anything — the act of writing is the gesture.

This is uniquely Blinking: **the note is the grace period.** It reinforces the tagging system, rewards reflection, and keeps the habit alive in the user's consciousness during a difficult stretch.

**Tier 3 — Reset**  
After 3 days total (1 automatic + up to 2 note-earned), the streak resets to zero. Missed days appear as ✕ in Reflect. Best streak is always preserved.

```
DAY 0:  Habit completed — streak continues
DAY 1:  Habit missed
DAY 2:  Tier 1 grace — streak intact, gentle reminder shown
        [Optional: write a note → earns +1 day]
DAY 3:  Tier 2 grace (if note written on Day 2)
        [Optional: write another note → earns +1 more day]
DAY 4:  Grace expired — streak resets to 0
        Best streak preserved. Missed days recorded in Reflect.
```

**Why 3 days:** Generous enough for illness, travel, or a hard week; strict enough that the streak remains meaningful. The note mechanism means motivated users actively earn grace days rather than receiving them passively.

**Paused habits:** The grace period does not apply to inactive habits. Pausing is an explicit choice; restarting begins a new streak from day one.

---

## Cross-Tab Changes

### Real-Time Sync

All state changes propagate instantly across all surfaces with no manual refresh:

| Action | Surfaces updated immediately |
|--------|------------------------------|
| Mark habit complete (Do) | My Day tab, Do progress bar, Reflect calendar |
| Toggle habit inactive (Build) | Do tab (habit disappears), My Day summary count |
| Add a note tagged to habit (Moments) | Reflect detail view for that habit |
| Streak reset | Do header, Reflect per-habit card, My Day if shown |

### Tagging as Universal Connector

Tags are the connective tissue across the entire app. One tag links a habit to everything related to it — notes, history, reminders, and future analytics — with no bespoke schema changes per feature.

**Convention:**
- Habit tags are auto-generated from the habit name on creation (e.g. "Morning Run" → `#morning-run`)
- User can rename the tag in the edit modal
- Any Moments note carrying a habit's tag appears in that habit's Reflect detail view
- One note can carry multiple habit tags (e.g. a note about a run that also mentions sleep quality)

This is the simplest possible linking architecture. It uses what already exists. Adding new habit-linked features in future requires only: filter notes by tag.

### Visual Language — Colour Tokens

| Token | Colour | Meaning |
|-------|--------|---------|
| `brand-teal` | Teal | Active / pending / in progress |
| `state-done` | Green | Completed |
| `state-missed` | Warm coral | Missed / needs attention |
| `state-inactive` | Mid-grey | Paused / inactive |
| `state-empty` | Light grey | No data |

No surface should use these colours for decorative purposes — only semantic ones.

### Emotional Signal Layer

Minimal, calm, consistent with Blinking's journaling tone:

| Trigger | Signal |
|---------|--------|
| First completion of the day | Subtle card flash animation |
| 100% day complete | "All done today ✓" header line, fades in 3 seconds |
| New personal best streak | Single-line banner on Do tab, dismissible |
| Streak grace period active | Gentle reminder on Do: "Still time to log yesterday's [habit]" |

No popups. No forced celebration screens. One signal per trigger.

---

## Implementation Priority

| Priority | Item | Tab | Effort |
|----------|------|-----|--------|
| P0 | Tap-to-complete interaction | Do | M |
| P0 | Set Do as default tab | Cross-tab | XS |
| P0 | Real-time sync across all surfaces | Cross-tab | M |
| P1 | Fix visual hierarchy (pending prominent, done receded) | Do | S |
| P1 | Active/inactive toggle with streak reset on pause | Build | M |
| P1 | Three-state circle encoding + legend | Reflect | S |
| P2 | Progress summary header (count + bar) | Do | S |
| P2 | Personal "why" description field | Build | S |
| P2 | Per-habit summary cards | Reflect | L |
| P2 | Tag-based note bridge from completion | Do | M |
| P2 | Resolve dual-FAB | Build | XS |
| P2 | Streak grace period — Tier 1 (1-day auto) | Cross-tab | M |
| P3 | Grace period — Tier 2 (note-earned extension) | Cross-tab | M |
| P3 | Single-habit detail view with tagged notes | Reflect | L |
| P3 | Section grouping (pending / done) | Do | S |
| P3 | Periodic summary at top | Reflect | S |
| P3 | Emotional micro-signals | Cross-tab | S |
| P3 | Empty state on Build tab | Build | XS |

**Effort scale:** XS = hours · S = 1–2 days · M = 3–5 days · L = 1–2 weeks

---

## Resolved Design Decisions

| # | Question | Decision |
|---|----------|----------|
| 1 | Completion sync | Real-time across all surfaces — My Day, Do, Reflect update instantly on any state change |
| 2 | Skip state | Removed. No new tracking field. Users who want to explain a miss write a note. Simplicity wins. |
| 3 | Tab rename | Build · Do · Reflect confirmed as final tab names |
| 4 | Streak behaviour on pause | Streak resets to zero immediately on deactivation. Resuming starts from day one. Grace period (max 3 days: 1 auto + up to 2 note-earned) applies to missed days only, not paused habits. |
| 5 | Note–habit linking | Tag-based. Habit tag auto-generated on creation. Any note carrying the tag appears in that habit's Reflect view. No schema changes. |

---

*Blinking Routine Design Plan v1.2 — internal document*
