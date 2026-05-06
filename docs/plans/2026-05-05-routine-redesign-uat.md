# UAT — Routine Redesign (Build · Do · Reflect)
**Version:** v1.1.0-beta.7+22  
**Date:** 2026-05-05  
**Scope:** Routine tab redesign — 3 sub-tabs with Build/Do/Reflect paradigm

---

## Section A — Tab Navigation

### A-1: Tab names and default
| # | Step | Expected |
|---|------|----------|
| A-1.1 | Tap Routine tab in bottom nav | 3 sub-tabs visible: **建造** (Build) / **执行** (Do) / **反思** (Reflect) |
| A-1.2 | Default tab on entry | **执行 (Do)** tab is selected by default, not Build |
| A-1.3 | Switch between tabs | Smooth tab transition, all 3 tabs responsive |
| A-1.4 | Switch to English locale | Tabs read: **Build** / **Do** / **Reflect** |

---

## Section B — Do Tab (执行)

### B-1: Progress header
| # | Step | Expected |
|---|------|----------|
| B-1.1 | Create 3+ daily habits for today | Do tab shows date header ("Thursday, May 5"), progress bar, and count like "0 / 3" |
| B-1.2 | Complete 1 habit | Progress bar fills proportionally, count updates to "1 / 3" |
| B-1.3 | Complete all habits | Progress bar full green, "✓" shown instead of count |

### B-2: Motivational copy
| # | Step | Expected |
|---|------|----------|
| B-2.1 | View Do tab in morning (< 12 PM) | Shows "Good morning. Here's your day." |
| B-2.2 | View Do tab in afternoon (12-6 PM) | Shows "Afternoon check-in. Keep going." (if not all done) |
| B-2.3 | View Do tab in evening (> 6 PM) | Shows "Almost done for the day." (if not all done) |
| B-2.4 | Complete all habits | Shows "All done today. Well done." in green |

### B-3: Tap to complete
| # | Step | Expected |
|---|------|----------|
| B-3.1 | Tap the ○ circle on a pending habit | Haptic buzz, brief green flash animation, habit moves to "Done today" section |
| B-3.2 | Tap ✓ on a completed habit | Habit unmarks, moves back to "Still to do" |
| B-3.3 | Check My Day (Calendar) tab after completing | Completed habit shows ✓ on Calendar tab immediately |
| B-3.4 | Switch to Reflect tab after completing | Completed habit shows ● teal circle for today |

### B-4: Visual hierarchy
| # | Step | Expected |
|---|------|----------|
| B-4.1 | View pending habits | Cards have teal-accented left border, full opacity, ○ icon with teal tint |
| B-4.2 | View completed habits | Cards have grey background, no elevation, line-through text, ✓ icon |
| B-4.3 | Pending section header | "Still to do" with teal color + count badge |
| B-4.4 | Completed section header | "Done today" in grey, no count badge |

### B-5: Empty state
| # | Step | Expected |
|---|------|----------|
| B-5.1 | No habits scheduled for today | Shows 🌿 "Nothing scheduled today" + "Add a habit in Build" hint |

### B-6: Manual add button
| # | Step | Expected |
|---|------|----------|
| B-6.1 | Have an ad-hoc routine, tap "Add" button | Picker shows ad-hoc routines, tapping adds to today's list |
| B-6.2 | Complete the manually added routine | Same completion behavior as scheduled routines |

---

## Section C — Build Tab (建造)

### C-1: Active/inactive toggle
| # | Step | Expected |
|---|------|----------|
| C-1.1 | View Build tab with active habits | Each card has an ON switch (teal), full opacity, teal icon background |
| C-1.2 | Toggle a habit OFF | Card drops to ~55% opacity, switch turns OFF, icon goes grey |
| C-1.3 | Toggle a habit ON | Card returns to full opacity, switch turns ON, icon returns to teal |
| C-1.4 | Check Do tab after toggling OFF | Paused habit disappears from today's Do list |

### C-2: Active count badge
| # | Step | Expected |
|---|------|----------|
| C-2.1 | View Build tab with 3 active habits | "Active" header shows teal badge with "3" |
| C-2.2 | View "Paused" section | Grey header with count badge, no teal accents |

### C-3: "Why" description
| # | Step | Expected |
|---|------|----------|
| C-3.1 | Edit a habit, add text in "Why does this matter?" field (e.g. "I run to clear my head") | Field accepts up to 120 characters |
| C-3.2 | Save the edit | Build card now shows italic grey subtitle with the "why" text |
| C-3.3 | Create a new habit without "why" | Card shows no italic subtitle (normal) |

### C-4: More menu (⋮)
| # | Step | Expected |
|---|------|----------|
| C-4.1 | Tap ⋮ on a Build card | Opens menu (currently direct edit trigger) |
| C-4.2 | Tap the card to edit | Opens edit dialog with all fields populated |

### C-5: Empty state
| # | Step | Expected |
|---|------|----------|
| C-5.1 | Delete all routines, view Build tab | Shows 🌱 "Start building your routine" + "Small habits, done consistently, create lasting change." |

### C-6: Add habit FAB
| # | Step | Expected |
|---|------|----------|
| C-6.1 | Tap + FAB on Routine tab | Opens Add Routine dialog |
| C-6.2 | Fill name, optional fields, tap Add | Routine appears in Build and Do tabs |

---

## Section D — Reflect Tab (反思)

### D-1: Three-state encoding
| # | Step | Expected |
|---|------|----------|
| D-1.1 | View a past day where all habits were completed | All rows show ● filled teal circle |
| D-1.2 | View a past day where a habit was missed | Missed habit shows ✕ in coral/orange |
| D-1.3 | View a day before a habit was created | Habit row is blank (no icon) for that day |
| D-1.4 | Only days with data appear | Empty days are not listed |

### D-2: Date grouping
| # | Step | Expected |
|---|------|----------|
| D-2.1 | View Reflect tab with multiple days of history | Each day is separated by a divider with date label "May 5 (Mon)" |
| D-2.2 | Most recent day is at the top | Days sorted newest first |

### D-3: Empty state
| # | Step | Expected |
|---|------|----------|
| D-3.1 | Fresh install with no history | Shows 📊 "No history yet" + "Completed habits will appear here" |

---

## Section E — Edit Dialog (New Fields)

### E-1: "Why" field
| # | Step | Expected |
|---|------|----------|
| E-1.1 | Add routine → enter text in "Why does this matter?" | Text accepted, counter shows remaining chars |
| E-1.2 | Text exceeding 120 chars | Input truncated at 120 chars |
| E-1.3 | Save with "why" text | Routine shows italic description on Build card |

### E-2: All existing fields still work
| # | Step | Expected |
|---|------|----------|
| E-2.1 | Change name, reminder, frequency, category | All save and display correctly |
| E-2.2 | Pick custom icon image | Icon saves and displays on card |
| E-2.3 | Change frequency to Weekly | Day-of-week chips appear |
| E-2.4 | Change frequency to Scheduled | Date picker appears |
| E-2.5 | Change frequency to Ad-hoc | No extra options |

---

## Section F — Cross-Tab Sync

### F-1: Real-time propagation
| # | Step | Expected |
|---|------|----------|
| F-1.1 | Complete a habit in Do tab | My Day (Calendar) tab shows ✓ immediately |
| F-1.2 | Toggle habit inactive in Build tab | Do tab immediately removes the habit |
| F-1.3 | Add new habit in Build tab | Do tab immediately includes it (if scheduled for today) |

---

## Section G — Regression

### G-1: HomeScreen routine checklist still works
| # | Step | Expected |
|---|------|----------|
| G-1.1 | Calendar tab shows today's routine checklist | Same as before — ✓ for completed, ○ for pending |
| G-1.2 | Tap to complete from Calendar tab | Works identically to Do tab |

### G-2: Floating robot not broken
| # | Step | Expected |
|---|------|----------|
| G-2.1 | Floating robot visible on Routine tab | Robot bobs and pulses as normal |
| G-2.2 | Tap robot on Routine tab | Opens AssistantScreen normally |

### G-3: Add entry FAB unchanged
| # | Step | Expected |
|---|------|----------|
| G-3.1 | Switch to Calendar/Moment tabs | FAB shows + (add entry), not add routine |
| G-3.2 | Switch to Routine tab | FAB shows + (add routine) |

---

## Sign-off Checklist

| Section | Tester | Result | Notes |
|---------|--------|--------|-------|
| A-1 Tab names + default | | ⬜ Pass / ⬜ Fail | |
| B-1 Progress header | | ⬜ Pass / ⬜ Fail | |
| B-2 Motivational copy | | ⬜ Pass / ⬜ Fail | |
| B-3 Tap to complete | | ⬜ Pass / ⬜ Fail | |
| B-4 Visual hierarchy | | ⬜ Pass / ⬜ Fail | |
| B-5 Do empty state | | ⬜ Pass / ⬜ Fail | |
| B-6 Manual add | | ⬜ Pass / ⬜ Fail | |
| C-1 Active/inactive toggle | | ⬜ Pass / ⬜ Fail | |
| C-2 Count badges | | ⬜ Pass / ⬜ Fail | |
| C-3 "Why" description | | ⬜ Pass / ⬜ Fail | |
| C-4 More menu | | ⬜ Pass / ⬜ Fail | |
| C-5 Build empty state | | ⬜ Pass / ⬜ Fail | |
| C-6 Add habit FAB | | ⬜ Pass / ⬜ Fail | |
| D-1 Three-state encoding | | ⬜ Pass / ⬜ Fail | |
| D-2 Date grouping | | ⬜ Pass / ⬜ Fail | |
| D-3 Reflect empty state | | ⬜ Pass / ⬜ Fail | |
| E-1 "Why" field | | ⬜ Pass / ⬜ Fail | |
| E-2 Existing fields | | ⬜ Pass / ⬜ Fail | |
| F-1 Real-time sync | | ⬜ Pass / ⬜ Fail | |
| G-1 HomeScreen checklist | | ⬜ Pass / ⬜ Fail | |
| G-2 Floating robot | | ⬜ Pass / ⬜ Fail | |
| G-3 FAB unchanged | | ⬜ Pass / ⬜ Fail | |
