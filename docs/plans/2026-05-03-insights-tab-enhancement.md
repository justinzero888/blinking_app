# Insights Tab Enhancement — Detail Design
**Created:** 2026-05-03
**Status:** Phase 1 (cosmetic) ✅ | CT1 (Writing Stats) ✅ | CT2 (Checklist Analytics) ✅ | CT3 (Tag-Mood Correlation) ✅ | CT4 (AI Insights) remaining
**Total effort:** ~6.5h — Phase 1: ✅ ~2.5h | CT1+CT3: ✅ ~1.75h | CT2: ✅ ~45min | CT4: ~1.5h remaining
**Files:** `lib/screens/cherished/cherished_memory_screen.dart`, `lib/providers/summary_provider.dart`

---

## Summary

The Insights tab (洞察) currently shows a yearly mood jar carousel + 4 charts (note count, habit completion, mood trend, top tags) behind a Day/Week/Month scope picker. While functional, it lacks:

1. **Visual hierarchy** — a flat scroll list of charts with no hero numbers or sections
2. **Engagement hooks** — no streaks, no correlations, no personalized takeaways
3. **Industry-competitive polish** — competitors (Daylio, Reflectly) surface insights as the **value proposition**, not just raw charts

This plan proposes a two-phase enhancement: **cosmetic** (visual refresh, stats cards, heatmap) and **content** (new data dimensions, correlations, AI insights).

---

## Industry Benchmark

### Competitor Analysis — Insights/Stats Tabs

| App | Category | Insights Features |
|-----|----------|-------------------|
| **Daylio** | Mood tracking | Mood line chart, mood distribution pie, activity↔mood correlation (e.g. "When you exercise, your mood is 25% better"), year-in-pixels grid, calendar heatmap, goal achievements, streaks |
| **Reflectly** | AI journaling | Stats dashboard with headline numbers, mood calendar, AI-generated "weekly reflection" text blurbs, streaks, entry count |
| **Streaks** | Habit tracker | Per-habit completion bars (0-100%), current/longest streak per habit, completion heat map (GitHub-style), month-over-month comparison |
| **Day One** | Journaling | Calendar heatmap, entry count, photo count, word count stats, streak counter, "On This Day" retrospective, location map |
| **HabitNow** | Habit tracker | Completion rate per habit, streak counter, weekly/monthly summary cards, "best day of week" insight |

### Common Patterns Across All Competitors

| Pattern | Adopted By | Description |
|---------|-----------|-------------|
| **Hero stats row** | Daylio, Reflectly, Streaks | 3-4 headline numbers at top: total entries, streak, mood avg, completion rate |
| **Calendar heatmap** | Daylio, Streaks, Day One | GitHub-style contribution grid — every day is a colored dot. Users love this (it's the #1 requested feature in journaling apps) |
| **Mood distribution** | Daylio (pie), Reflectly | How your mood breaks down: happy X%, neutral Y%, sad Z% |
| **Correlation insights** | Daylio | "When you do X, your mood is Y% better" — the #1 differentiator for Daylio |
| **Streaks** | All 5 apps | "You've written for X days in a row" — simple but addictive |
| **AI text insights** | Reflectly | LLM-generated personalized takeaways ("You tend to write more on weekends") |
| **Year in Review** | Daylio (year-in-pixels), Day One | Annual summary — total entries, top mood, top activities, top tags |

### What Blinking Can Uniquely Offer (Competitive Advantage)

| Differentiator | Why |
|----------------|-----|
| **Bilingual insights** | Competitors are English-only or have poor i18n. Blinking generates insights in ZH + EN |
| **Checklist analytics** | No competitor combines mood + habits + ad-hoc checklists in one insights view |
| **AI-generated personalized insights** | Blinking already has LLM infrastructure (PROP-6). Can generate text insights about user patterns |
| **Emotion jar visualization** | Already unique to Blinking — keep and enhance it |

---

## Phase 1: Cosmetic (Visual Refresh) — ~2.5h

### C1. Hero Stats Cards

Replace the standalone mood jar carousel with a richer header section:

```
┌─────────────────────────────────────────┐
│  Insights                       洞察    │  ← AppBar
├─────────────────────────────────────────┤
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │
│  │  42  │ │  7天  │ │  78% │ │  😊   │  │  ← Hero cards row
│  │ 总记录│ │ 连续  │ │ 习惯  │ │ 今日  │  │
│  └──────┘ └──────┘ └──────┘ └──────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │  🫙 情绪罐                        │  │  ← Mood jars (kept, moved below)
│  │  [2025] [2026]  →                │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Data sources (all computed from existing data, no DB changes):**

| Card | EN Label | ZH Label | Computation |
|------|----------|----------|-------------|
| Total entries | "Total Entries" | "总记录" | `_entryProvider.allEntries.length` |
| Current streak | "Day Streak" | "连续天数" | Count consecutive days backward from today with ≥1 entry |
| Habit rate | "Routine Rate" | "习惯完成率" | Avg completion % across all active routines (all time) |
| Today's mood | "Today's Mood" | "今日心情" | Dominant emotion today via `JarProvider.getDayEmotions(today)` |

**Implementation:**
- Single-row horizontal `ListView` of glossy `Card` widgets, each 80×80px
- Animated counter entrance (count up from 0 on first load)
- Tap on streak card → show longest streak tooltip
- Tap on mood card → scroll to mood trend chart

**Files:** `cherished_memory_screen.dart` — new `_HeroStatsRow` widget within `_InsightsContent`

### C2. Calendar Heatmap

GitHub-style contribution grid showing all-time daily activity:

```
┌──────────────────────────────────────────┐
│  📅 Writing Activity              写作足迹 │
│  ┌──────────────────────────────────────┐│
│  │  Mon Wed Fri                         ││
│  │  ░░▓░ ░░▓░ ░░░░ ░░░░ ░░░░ ░░░░    ││
│  │  ░░░░ ░░░░ ░░▓░ ░░░░ ░░░░ ░░░░    ││
│  │  ░░█░ ░░▓░ ░░░░ ░░░░ ░░░░ ░░░░    ││  ← 7 rows × ~20 cols
│  │  ░░░░ ░░░░ ░░░░ ░░█░ ░░░░ ░░░░    ││
│  │  ░░▓░ ░░░░ ░░░░ ░░░░ ░░░░ ░░█░    ││
│  │  ░░░░ ░░█░ ░░░░ ░░░░ ░░░░ ░░░░    ││
│  │         Jan   Feb   Mar   Apr   May  ││
│  └──────────────────────────────────────┘│
│  Less ░░ ▓░ █░ More entries             │
└──────────────────────────────────────────┘
```

**Data:** Pre-compute a `Map<DateTime, int>` of entries per day. Render 52 weeks × 7 days as colored squares.
- Color scale: 0 entries = `Colors.grey[200]`, 1 = teal-100, 2+ = teal-300, 5+ = teal-500, 10+ = teal-700
- Horizontal scroll if > 52 weeks
- Tap a day → show tooltip with date + entry count

**Implementation:**
- Custom `_CalendarHeatmap` widget — `GridView` (7 rows) inside horizontal `ListView` (weeks)
- ~150 lines of new widget code
- Performance: pre-compute `Map<String, int>` on provider change, O(n) over entries

**Files:** `cherished_memory_screen.dart` — new `_CalendarHeatmap` widget within `_InsightsContent`

### C3. Mood Distribution Donut

```
┌──────────────────────────────────────────┐
│  🎭 Mood Distribution             情绪分布 │
│  ┌──────────────────────────────────────┐│
│  │       ╭─────────╮                    ││
│  │      ╱   😊 40%  ╲                   ││
│  │     │   😌 25%    │   ← Donut chart  ││
│  │     │   😐 20%   │                   ││
│  │      ╲  😢 10%  ╱                    ││
│  │       ╰─────────╯                    ││
│  │  😊 Happy · 42   😌 Good · 26        ││  ← Legend below
│  │  😐 Neutral · 21  😢 Sad · 11        ││
│  └──────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

**Data:** Aggregate all non-null emotions across entries, compute percentage per emotion.

**Implementation:**
- `fl_chart` `PieChart` with `PieChartSectionData` per emotion
- Center hole (donut style) with total entry count
- Legend below: emoji + label + count + percentage
- Colors: use emotion-appropriate colors (green for happy, yellow for neutral, blue/grey for sad)

**Files:** `cherished_memory_screen.dart` — new `_MoodDistributionChart` widget

### C4. Visual Hierarchy & Polish

1. **Section cards** — wrap each chart in a `Card` with subtle elevation + rounded corners
2. **Alternating backgrounds** — light grey tint on odd/even sections for visual grouping
3. **Consistent section headers** — each section gets an emoji-prefixed title + description subtitle
4. **Scope picker redesign** — move from standalone `ChoiceChip` row to a segmented control inside a card header
5. **Smooth scroll animations** — `ScrollController` + `animateTo` on section header tap
6. **Spacing** — increase `SizedBox(height: 32)` between sections (currently 24)

**Effort:** ~30min, mostly CSS-like tweaks to existing widgets.

---

## Phase 2: Content (New Data Dimensions) — ~4h

### CT1. Writing Streak & Stats Section — ~45min

New section below hero cards, above heatmap:

```
┌──────────────────────────────────────────┐
│  🔥 Writing Stats                 写作统计 │
│  ┌──────────┬──────────┬──────────────┐  │
│  │  📝 42   │  📊 156  │  🏆 12 days  │  │
│  │  entries │  avg words│  longest     │  │
│  │          │  per entry│  streak      │  │
│  ├──────────┼──────────┼──────────────┤  │
│  │  最活跃   │  平均字数  │  最长连续天数  │  │
│  └──────────┴──────────┴──────────────┘  │
└──────────────────────────────────────────┘
```

**New computations in SummaryProvider:**
- `averageEntryLength` — total words / entry count (CJK + EN word counting, same logic as card editor)
- `longestStreak` — longest consecutive days with entries (all time)
- `mostActiveDayOfWeek` — which weekday has the most entries
- `mostActiveHour` — which hour of day has the most entries (from `createdAt`)

**Files:** `summary_provider.dart` — 4 new getters; `cherished_memory_screen.dart` — `_WritingStatsSection`

### CT2. Checklist Analytics — ~45min

```
┌──────────────────────────────────────────┐
│  ✅ Checklist Insights             清单洞察 │
│  ┌──────────────────────────────────────┐│
│  │  📋 23 lists created               ││
│  │  ✅ 78% avg completion rate        ││
│  │  🔁 15 items carried forward       ││
│  │  📌 Top item: "Drink water" (12×)  ││
│  └──────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

**New computations in SummaryProvider:**
- `totalLists` — count entries with `EntryFormat.list`
- `checklistCompletionRate` — avg of `doneCount / totalCount` across all lists
- `totalCarriedForward` — count `ListItem`s with `fromPreviousDay: true`
- `topChecklistItem` — most common item text across all lists (normalized to lowercase)

**Files:** `summary_provider.dart` — 4 new getters; `cherished_memory_screen.dart` — `_ChecklistInsightsSection`

### CT3. Mood-Tag Correlation — ~1h

The most impressive insight (Daylio's killer feature): which activities/tags correlate with better moods?

```
┌──────────────────────────────────────────┐
│  🔬 Tag Impact on Mood           标签与情绪 │
│  ┌──────────────────────────────────────┐│
│  │  🏃 Exercise    →  😊 4.2 / 5       ││
│  │  📚 Reading     →  😌 3.8 / 5       ││
│  │  💼 Work        →  😐 3.2 / 5       ││
│  │  🍕 Fast food   →  😢 2.1 / 5       ││
│  └──────────────────────────────────────┘│
│  Tags with ≥3 entries shown            │
└──────────────────────────────────────────┘
```

**Data:** For each tag, find all entries with that tag → average `_emotionScores`. Show top 5 tags (by entry count, min 3 entries).

**New computation in SummaryProvider:**
- `tagMoodCorrelation` — `List<({String tagId, double avgScore, int entryCount})>` sorted by avgScore desc

**Visual:** Horizontal bar row per tag — colored bar from 0-5 scale, emotion emoji at right, label + score on left.

**Files:** `summary_provider.dart` — 1 new getter; `cherished_memory_screen.dart` — `_TagMoodSection`

### CT4. AI-Generated Personal Insights — ~1.5h

Use Blinking's existing LLM infrastructure to generate personalized text insights:

```
┌──────────────────────────────────────────┐
│  🤖 AI Insights              AI 个性化洞察  │
│  ┌──────────────────────────────────────┐│
│  │  "You write 3× more on Sundays —     ││
│  │   weekends are your reflection time.  ││
│  │   Your happiest days tend to involve  ││
│  │   'Exercise' or 'Family' tags. March  ││
│  │   was your most consistent month      ││
│  │   with 18 entries."                   ││
│  │                                  🤖  ││
│  └──────────────────────────────────────┘│
│          [Refresh Insights]              │
└──────────────────────────────────────────┘
```

**Approach:** Pre-compute a structured data summary, then send it to the LLM with a system prompt to generate 3-5 personalized insights in natural language.

**Data payload sent to LLM:**
```json
{
  "totalEntries": 42,
  "daysTracked": 180,
  "currentStreak": 7,
  "longestStreak": 12,
  "topEmotion": "😊 (42%)",
  "moodTrend": "improving (+0.3/5 this month)",
  "mostActiveDay": "Sunday",
  "topTags": ["Exercise (15)", "Family (12)", "Work (10)"],
  "tagMoodCorrelation": [
    {"tag": "Exercise", "avgMood": 4.2},
    {"tag": "Work", "avgMood": 3.2}
  ],
  "checklistCompletion": 0.78,
  "bestMonth": "March (18 entries, avg mood 4.1)",
  "wordCountAvg": 156
}
```

**System prompt:**
```
You are a personal journaling insights assistant for Blinking (记忆闪烁). 
Given the user's data below, generate 3-5 personalized, encouraging insights 
in natural language. Be warm, supportive, and data-driven. 
Highlight patterns, achievements, and suggestions. 
Respond in {language} (Chinese or English based on user's locale).
Keep to 150 words max. Do not use markdown.
```

**Caching:** Store last-generated insights + data fingerprint in `SharedPreferences`. Only regenerate when data changes significantly (e.g., +5 new entries, +1 week passed). Prevent excessive API calls.

**Fallback:** If no API key / trial expired, show a pre-computed rule-based insight instead:
- "You've written {n} entries — keep going!"
- "Your longest streak was {n} days — can you beat it?"
- "{tag} entries make you happiest 😊"

**Files:**
- `lib/core/services/llm_service.dart` — re-use existing `chat()` method
- `lib/providers/summary_provider.dart` — `generateInsightsData()` helper
- `lib/screens/cherished/cherished_memory_screen.dart` — `_AiInsightsSection`

---

## Full Layout (Proposed)

```
┌─────────────────────────────────────────┐
│  Insights                       洞察    │
├─────────────────────────────────────────┤
│  [Hero Cards: Entries | Streak | Habit | Mood]
│
│  ── 🫙 Mood Jars ── (carousel) ──      │
│
│  ── 📅 Writing Activity ── (heatmap) ── │
│
│  ── 🔥 Writing Stats ── (stats row) ──  │
│
│  ── 🎭 Mood Distribution ── (donut) ──  │
│
│  ── 📊 Trends ── (scope picker + 4 charts)
│
│  ── ✅ Checklist Insights ── (stats) ── │
│
│  ── 🔬 Tag Impact ── (correlation) ──   │
│
│  ── 🤖 AI Insights ── (text card) ──    │
│
└─────────────────────────────────────────┘
```

---

## Implementation Order

| # | Item | Category | Effort | Priority | Depends On |
|---|------|----------|:------:|:--------:|------------|
| C1 | Hero Stats Cards | Cosmetic | ~45min | P1 | ✅ Done 2026-05-03 |
| C2 | Calendar Heatmap | Cosmetic | ~1h | P1 | ✅ Done 2026-05-03 |
| C3 | Mood Distribution Donut | Cosmetic | ~30min | P2 | ✅ Done 2026-05-03 |
| C4 | Visual Hierarchy & Polish | Cosmetic | ~30min | P2 | ✅ Done 2026-05-03 |
| CT1 | Writing Streak & Stats | Content | ~45min | P1 | — |
| CT2 | Checklist Analytics | Content | ~45min | P2 | — |
| CT3 | Mood-Tag Correlation | Content | ~1h | P1 | — |
| CT4 | AI-Generated Insights | Content | ~1.5h | P3 | ✅ LLM infra (PROP-6) |

**Phase 1 complete (2026-05-03):** All cosmetic items implemented. Hero cards show total entries, streak, habit rate, today's mood. Calendar heatmap with all-time horizontal scroll. Mood distribution donut with 5-group categorization. Section cards with consistent borders/elevation. Mood jars moved to bottom.

**Recommended launch batch (P1):** C1 + C2 + CT1 + CT3 = ~3.5h — the most impactful improvements that differentiate Blinking from competitors.

**Polish batch (P2):** C3 + C4 + CT2 = ~1.5h — completes the visual refresh.

**Stretch (P3):** CT4 = ~1.5h — AI insights, depends on trial/purchase flow being implemented.

---

## Files Affected

| File | Changes |
|------|---------|
| `lib/screens/cherished/cherished_memory_screen.dart` | Major rewrite — new sections, widgets, layout |
| `lib/providers/summary_provider.dart` | 8 new computed properties (streak, avg length, checklist stats, tag correlation) |
| `lib/l10n/app_en.arb` | ~15 new i18n keys |
| `lib/l10n/app_zh.arb` | ~15 new i18n keys |

### New i18n Strings

| Key | EN | ZH |
|-----|----|----|
| `insightsTotalEntries` | "Total Entries" | "总记录" |
| `insightsDayStreak` | "Day Streak" | "连续天数" |
| `insightsRoutineRate` | "Routine Rate" | "习惯完成率" |
| `insightsTodayMood` | "Today's Mood" | "今日心情" |
| `insightsWritingActivity` | "Writing Activity" | "写作足迹" |
| `insightsMoodDistribution` | "Mood Distribution" | "情绪分布" |
| `insightsWritingStats` | "Writing Stats" | "写作统计" |
| `insightsAvgWords` | "avg words/entry" | "平均字数" |
| `insightsLongestStreak` | "longest streak" | "最长连续" |
| `insightsMostActiveDay` | "most active day" | "最活跃日" |
| `insightsChecklistInsights` | "Checklist Insights" | "清单洞察" |
| `insightsListsCreated` | "lists created" | "已创建清单" |
| `insightsAvgCompletion` | "avg completion" | "平均完成率" |
| `insightsItemsCarried` | "items carried forward" | "已结转事项" |
| `insightsTopItem` | "top item" | "最常见事项" |
| `insightsTagImpact` | "Tag Impact on Mood" | "标签与情绪" |
| `insightsAiInsights` | "AI Insights" | "AI 个性化洞察" |
| `insightsRefresh` | "Refresh Insights" | "刷新洞察" |

### No DB Changes Required

All new data dimensions are computed from existing tables:
- `entries` → streaks, word counts, emotion distribution, tag correlation
- `routines` / `completions` → routine completion rate
- `list_items` → checklist analytics

---

## Consultation Questions — RESOLVED (2026-05-03)

### Q1: Hero Cards — Which 4 stats?

**Competitive analysis:**

| Competitor | Hero/Headline Stats |
|------------|---------------------|
| **Daylio** | Entry count, mood streak, goal completion |
| **Reflectly** | Current streak, total entries, mood average |
| **Streaks** | Current streak, longest streak, today's completion % |
| **Day One** | Total entries, current streak, photo count, locations |
| **HabitNow** | Today's completions, weekly rate, current streak |

**Common pattern across all 5:** Every competitor shows a **streak counter** (it's the #1 engagement mechanic). Total entries is the second most universal. Mood/emotion summary appears in 3/5 (journaling-focused apps). Completion rate appears in 3/5 (habit-focused apps).

**What Blinking uniquely offers vs competitors:** Blinking is the only app combining journaling + habit tracking + ad-hoc checklists. No competitor has checklist analytics.

**Recommendation (selected):**
| Card | EN | ZH | Rationale |
|------|----|----|-----------|
| Total Entries | "Entries" | "总记录" | Universal baseline — all 5 competitors |
| Day Streak | "Day Streak" | "连续天数" | #1 engagement metric — all 5 competitors |
| This Week's Mood | "Week Mood" | "本周心情" | Mood apps (3/5) surface mood; "this week" more insightful than raw "today" |
| Checklist Done | "Tasks Done" | "清单完成" | Unique differentiator — no competitor has checklist analytics |

### Q2: Calendar Heatmap — Scope?

**Competitive analysis:**

| Competitor | Feature | Scope |
|------------|---------|-------|
| **Daylio** | "Year in Pixels" | Full year (365 days), non-scrollable |
| **Streaks** | Completion heatmap | 6-12 months, scrollable |
| **Day One** | Calendar heatmap | All-time, horizontal scroll |
| **GitHub** | Contribution graph | All-time (52+ weeks), horizontal scroll — gold standard |
| **HabitNow** | Monthly view | 1 month at a time |

**Common pattern:** All-time with horizontal scroll (Day One, GitHub) is the user-preferred approach. Users want to see their ENTIRE journey, not a truncated window. Daylio's 365-day fixed grid is limiting for multi-year users. GitHub's approach (all columns, scroll to see older) is the most praised UX pattern for this visualization type.

**Recommendation (selected): All-time with horizontal scroll.** Default viewport shows last ~20 weeks. Older weeks accessible via horizontal scroll. This matches GitHub's widely-praised contribution graph UX. A "last 6 months" toggle could be added later but all-time is the right default.

### Q3: Tag-Mood Correlation — Minimum Threshold

**Decision: 3 entries minimum.** Tags with < 3 entries are statistically meaningless for correlation. This filters noise.

### Q4: AI Insights — Generation Trigger

**Decision: On-demand (Refresh button).** Auto-generation risks API cost for users with their own API keys. A manual "Refresh Insights" button gives users control and avoids surprise API usage. Cached result persists until user taps refresh.

### Q5: Section Order

**Decision: Move mood jars to the bottom.** Hero cards are more informative and deserve the top position. Mood jars are visually appealing but shallow — they serve better as a "year in review" closer at the bottom of the tab.
