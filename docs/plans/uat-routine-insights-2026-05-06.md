# Blinking — Routine & Insights UAT

**Date:** 2026-05-06 | **Version:** 1.1.0-beta.8+23 (fixes applied)  
**Test Data:** `blinking_backup_1778100016832.zip` (327 entries, 15 routines, 327 completions)

---

## Test Environment

| Platform | Device | Status |
|----------|--------|--------|
| iOS | iPhone 17 Pro Sim (iOS 26.5) | ✅ Running |
| Android | Medium Phone API 36.1 Emu | ✅ Running |
| Database | SQLite v12 with backup data injected | ✅ Loaded |

---

## UAT-1: Routine Tab — Do View

| # | Test Case | Expected | iOS | Android |
|---|-----------|----------|-----|---------|
| 1.1 | Open Routine tab | "Build / Do / Reflect" tabs visible | | |
| 1.2 | Switch to Do tab | Today's scheduled routines listed | | |
| 1.3 | Habit completion counter | Shows done/total (e.g., 2/6) with progress bar | | |
| 1.4 | Done count ≤ total | Never shows 8/6 or 7/6 | | |
| 1.5 | Tap uncompleted routine | Marks as done, counter updates | | |
| 1.6 | Tap completed routine | Unmarks, counter decreases | | |
| 1.7 | Adhoc "手动加入" button | Adds adhoc routine to today's list | | |

## UAT-2: Routine Tab — Reflect View

| # | Test Case | Expected | iOS | Android |
|---|-----------|----------|-----|---------|
| 2.1 | Switch to Reflect tab | Stats summary at top | | |
| 2.2 | Per-habit summary cards | Vitamin card shows streak, monthly rate, day-of-week | | |
| 2.3 | Monthly rate ≤ 100% | Never exceeds 100% (was 120% bug) | | |
| 2.4 | Streak > 0 for active habit | Vitamin (74 completions) shows streak ≥ 1 | | |
| 2.5 | Streak calculation | Consecutive days counted correctly with grace period | | |
| 2.6 | Habit detail on tap | Shows completion history and insights | | |

## UAT-3: Insights Tab — All Charts

| # | Test Case | Expected | iOS | Android |
|---|-----------|----------|-----|---------|
| 3.1 | Open Insights tab | All 4 trend charts render | | |
| 3.2 | Note counts chart | Bar chart with y-axis labels (integers) | | |
| 3.3 | Routine completion chart | Bar chart with y-axis labels (percentages) | | |
| 3.4 | Emotion trend chart | Line chart with y-axis emoji labels (😊😌😐😢😡) | | |
| 3.5 | Top tags chart | Bar chart with y-axis labels (counts) | | |
| 3.6 | Hero stats row | 3 cards fit without overflow | | |
| 3.7 | Heatmap | Shown with teal gradient | | |
| 3.8 | Checklist insights section | Statistics visible | | |
| 3.9 | AI Insights section | Rule-based insights generated without LLM | | |

## UAT-4: Routine — Streak & Grace Period

| # | Test Case | Expected | iOS | Android |
|---|-----------|----------|-----|---------|
| 4.1 | Streak reflects completion log | Vitamin with 74 completions shows correct streak | | |
| 4.2 | 1-day grace period | Missing yesterday but day-before done → streak protected | | |
| 4.3 | Grace period display | "Grace: 1 day" shown when applicable | | |
| 4.4 | Streak resets after >1 day missed | Streak falls to 0 | | |

## UAT-5: Entry Data (327 entries loaded)

| # | Test Case | Expected | iOS | Android |
|---|-----------|----------|-----|---------|
| 5.1 | Calendar month view | Entries visible on correct dates | | |
| 5.2 | Entry detail opens | Content, emotion, tags displayed | | |
| 5.3 | Search in Moments | Finds entries by keyword | | |
| 5.4 | Tag filter works | Filters entries by tag | | |

---

## Bug Fixes Verified

| Bug ID | Description | Fix | Status |
|--------|-------------|-----|--------|
| B1 | Monthly rate >100% | Count unique days not completions | ⬜ Verify |
| B2 | Done count 8/6, 7/6 | Deduplicate allToday list | ⬜ Verify |
| B3 | Charts missing y-axis | Added labels to all 4 charts | ⬜ Verify |
| B4 | AI insights need API key | Replaced LLM with rule-based stats | ⬜ Verify |
| B5 | Streak showing 0 for active habit | Date comparison fix | ⬜ Verify |
| B6 | Post-purchase state not updating | Auto-mark paid in paywall | ⬜ Verify |
| B7 | Settings no PAID banner | Added green banner | ⬜ Verify |
| B8 | Trial AI showing network error | Falls through to BYOK check | ⬜ Verify |

---

## Known Issues

1. **IAP production keys** — Blocked on App Store Connect metadata + Google Play service credentials
2. **Onboarding** — Not tested on fresh install (simulator had previous data)
3. **Android purchase** — Not tested (no Google key connected)

---

## Verification Steps

1. **Open Routine tab** → Do view → verify done/total counter is correct
2. **Switch to Reflect tab** → verify Vitamin shows streak > 0 and rate ≤ 100%
3. **Open Insights tab** → verify all charts have y-axis labels
4. **Tap Refresh on AI Insights** → verify rule-based insights appear without API key
5. **Calendar view** → verify entries load on correct dates
6. **Settings → AI** → verify preview banner shows correct days remaining
