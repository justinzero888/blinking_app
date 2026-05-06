# UAT — Routine Redesign + Insights + Streak Grace
**Version:** v1.1.0-beta.7+22 (clean build)  
**Date:** 2026-05-05  
**Scope:** Routine Build/Do/Reflect tabs, streak grace period, habit summary cards, heatmap fix

---

## Pre-Test Setup

1. Fresh install (app was uninstalled before deploy — clean state)
2. Create 3+ habits (e.g., "Morning Run" daily 7am, "Meditate" daily 8am, "Journal" daily 9pm)
3. Create 5+ journal entries across different dates (Calendar → + button → write text → save)
4. Complete some habits on different days to build history

---

## Section A — Routine Tab: Do (执行)

### A-1: Do is default tab
| # | Step | Expected |
|---|------|----------|
| A-1.1 | Open app, tap Routine (✅) in bottom nav | **执行 (Do)** tab is selected, not 建造 (Build) |
| A-1.2 | Tab bar shows 3 tabs | 建造 / **执行** / 反思 |

### A-2: Each habit shows icon + name
| # | Step | Expected |
|---|------|----------|
| A-2.1 | View pending habits on Do tab | Each shows [○] [habit icon] [name]. Icon matches the habit's emoji/image |
| A-2.2 | Compare with Reflect tab | Do tab shows same icon+name layout as Reflect |

### A-3: Progress header
| # | Step | Expected |
|---|------|----------|
| A-3.1 | View Do tab with habits | Shows progress bar and "0 / 3" (or your count) |
| A-3.2 | Complete 1 habit | Bar fills, count updates to "1 / 3" |
| A-3.3 | Complete all habits | Bar full green, shows "✓" |

### A-4: Tap to complete
| # | Step | Expected |
|---|------|----------|
| A-4.1 | Tap ○ on pending habit | Brief haptic + green flash, moves to "Done today" |
| A-4.2 | Tap ✓ on completed habit | Unmarks it, moves back to "Still to do" |
| A-4.3 | Check Calendar (My Day) tab | Completed habit shows ✓ immediately |

### A-5: Streak grace reminder
| # | Step | Expected |
|---|------|----------|
| A-5.1 | Miss a daily habit yesterday, view Do tab today | Orange banner: "[habit name] — still time to keep your streak" |
| A-5.2 | Complete the habit today | Streak continues (doesn't reset after 1 missed day) |

### A-6: Visual hierarchy
| # | Step | Expected |
|---|------|----------|
| A-6.1 | Pending habits | Teal border, full opacity, ○ circle |
| A-6.2 | Completed habits | Grey background, line-through text, ✓ icon, no elevation |

---

## Section B — Routine Tab: Build (建造)

### B-1: Active/inactive toggle
| # | Step | Expected |
|---|------|----------|
| B-1.1 | View Build tab | Each card has ON/OFF switch (teal when ON) |
| B-1.2 | Toggle a habit OFF | Card fades to ~55% opacity, switch turns OFF |
| B-1.3 | Check Do tab | Paused habit disappears from Do |
| B-1.4 | Active/Paused count badges | "Active 3" (teal) / "Paused 1" (grey) |

### B-2: "Why" description
| # | Step | Expected |
|---|------|----------|
| B-2.1 | Tap ⋮ on a Build card → edit | Dialog opens with all fields |
| B-2.2 | Enter text in "Why does this matter?" (up to 120 chars) | Text accepted |
| B-2.3 | Save | Card now shows italic grey subtitle with the "why" text |

### B-3: Empty state
| # | Step | Expected |
|---|------|----------|
| B-3.1 | Delete all habits | Shows 🌱 "Start building your routine" + guidance |

---

## Section C — Routine Tab: Reflect (反思)

### C-1: Three-state encoding
| # | Step | Expected |
|---|------|----------|
| C-1.1 | Day where habit was completed | ● filled teal circle |
| C-1.2 | Day where habit was missed | ✕ in coral/orange |
| C-1.3 | Day before habit was created | No icon (blank) |

### C-2: Habit summary cards
| # | Step | Expected |
|---|------|----------|
| C-2.1 | Scroll below calendar history | Section titled "习惯总览 / Habit Overview" |
| C-2.2 | Each card shows | Icon + name, Streak / Month % / Done count badges |
| C-2.3 | Progress bar | Monthly completion rate |
| C-2.4 | Strongest/Weakest day | Day labels in teal/orange chips |

---

## Section D — Insights Tab

### D-1: Heatmap shows data
| # | Step | Expected |
|---|------|----------|
| D-1.1 | Create 5+ entries across different dates | New entries saved |
| D-1.2 | Open Insights tab | Shows "📅 Writing Activity" section with entry count (e.g. "5 entries") |
| D-1.3 | Heatmap grid visible | Colored squares for days with entries, light grey for empty days |
| D-1.4 | Future dates | Grey-out cells |

---

## Section E — Cross-Tab Sync

### E-1: Real-time propagation
| # | Step | Expected |
|---|------|----------|
| E-1.1 | Complete habit on Calendar (My Day) | Switch to Routine → Do: habit shows ✓ immediately |
| E-1.2 | Toggle habit inactive on Build | Do tab removes it instantly |

---

## Sign-off Checklist

| Section | Result | Notes |
|---------|--------|-------|
| A-1 Do default tab | ⬜ Pass / ⬜ Fail | |
| A-2 Icon + name | ⬜ Pass / ⬜ Fail | |
| A-3 Progress header | ⬜ Pass / ⬜ Fail | |
| A-4 Tap complete | ⬜ Pass / ⬜ Fail | |
| A-5 Streak grace | ⬜ Pass / ⬜ Fail | |
| A-6 Visual hierarchy | ⬜ Pass / ⬜ Fail | |
| B-1 Active/inactive | ⬜ Pass / ⬜ Fail | |
| B-2 "Why" field | ⬜ Pass / ⬜ Fail | |
| B-3 Empty state | ⬜ Pass / ⬜ Fail | |
| C-1 Three-state | ⬜ Pass / ⬜ Fail | |
| C-2 Summary cards | ⬜ Pass / ⬜ Fail | |
| D-1 Heatmap data | ⬜ Pass / ⬜ Fail | |
| E-1 Cross-tab sync | ⬜ Pass / ⬜ Fail | |
