# Mood Jar AI — Feature Design Doc

**Date:** 2026-05-09  
**Feature:** Surface A — Mood Moment (reactive, not proactive)  
**Version:** 1.1.0-beta.8+

---

## 1. Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Flexible: 3 AI calls/day, any posture combination | Avoids "each posture once" friction. User can use NOTICE 3 times if preferred. |
| D2 | Consumed postures shown greyed out with saved text link | Gives user visibility into what was already explored. Tapping shows the saved reflection. |
| D3 | Previous day reflections use same sheet, read-only | Consistent UI. Unconsumed postures shown but not tappable for past dates. |
| D4 | Storage: SharedPreferences keyed by date | Simple. No DB migration needed. Resets daily at midnight. |
| D5 | Title: "My Mood Jar — Mon·May 9" | Matches "My Day" tab naming convention. Locale-aware date format. |
| D6 | Button text: "Ask AI ✨" (0 saved) → "Mood Reflection" (≥1 saved) | Clear state indication. User knows whether they have pending or saved reflections. |
| D7 | Posture sheet renders instantly (no API call on open) | 3 posture cards always visible immediately. API call only on tap. |
| D8 | "Keep this" saves to journal + persists in mood_reflections | Dual storage: journal entry (tag_reflection) + SharedPreferences (for sheet state). |

---

## 2. Data Model

### SharedPreferences Key
```
mood_reflections_{year}_{month}_{day}  →  JSON array
```

### JSON Schema
```json
[
  {
    "posture": "NOTICE|SOFTEN|STAY",
    "text": "AI-generated reflection text..."
  }
]
```

### Daily Limit
- `MAX_PER_DAY = 3`
- Counter = `reflections.length`
- Resets at midnight (new date key)

---

## 3. State Machine

```
                    ┌─────────────────┐
                    │  selectedDate   │
                    │  is TODAY?      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │ YES                         │ NO (past)
              ▼                             ▼
     ┌─────────────────┐          ┌─────────────────────┐
     │ canUseAI? +     │          │ hasSavedReflections?│
     │ jarHasEmoji?    │          └──────┬──────────────┘
     └────────┬────────┘                 │
              │                  ┌────────┴────────┐
    ┌─────────┴─────────┐       │ YES             │ NO
    │ NO                │ YES   │                 │
    ▼                   ▼       ▼                 ▼
┌────────┐      ┌──────────────┐  ┌─────────────┐  ┌──────────┐
│No      │      │ count = 0?   │  │"Mood        │  │Jar only, │
│button  │      │              │  │Reflection"  │  │no button │
└────────┘      └───┬────┬─────┘  │→ read-only  │  └──────────┘
                    │0   │1-3     │  sheet      │
                    ▼    ▼        └─────────────┘
              ┌─────────┐  ┌──────────────┐
              │"Ask AI  │  │"Mood         │
              │✨"      │  │Reflection"   │
              │→ sheet  │  │→ sheet       │
              │(all     │  │(consumed=    │
              │tapable) │  │grey+text,    │
              └─────────┘  │remaining=    │
                           │tapable)      │
                           └──────────────┘
```

### Posture Sheet Internal States
```
posture tapped → API call → show response → "Keep this" tapped
                                                    │
                                      ┌─────────────┘
                                      │
                                      ▼
                              save to journal entry
                              save to SharedPreferences
                              update sheet: posture now consumed (grey+text)
                              
                              if count == 3: all consumed, button now "Mood Reflection"
```

---

## 4. File Changes

### 4.1 `lib/screens/home/home_screen.dart` — `_EmojiJarSection`

**Changes:**
- Title: `isZh ? '今日情绪罐' : "Today's Mood Jar"` → locale-aware date format
  - `"My Mood Jar — Mon·May 9"` / `"情绪罐 — 5月9日周一"`
- Check `context.read<EntitlementService>().canUseAI`
- Check if selected date is today (`_isSameDay(selectedDate, DateTime.now())`)
- Load saved reflections from SharedPreferences for the selected date
- Pass `canUseAI`, `existingReflections`, `isToday`, `selectedDate` to `EmojiJarWidget`
- `showAskAi` only true when `canUseAI && isToday && jarHasEmoji`
- Wire sheet callbacks to reload reflections after save

**Imports added:**
- `shared_preferences` (or use context to get prefs)
- `entitlement_service.dart`
- `mood_moment_sheet.dart`

### 4.2 `lib/widgets/emoji_jar.dart` — `EmojiJarWidget`

**Changes:**
- **Remove**: `showAskAi` parameter (replaced by new params)
- **Add**:
  - `bool canUseAI` — from home_screen
  - `bool isToday` — whether the jar date is today
  - `List<Map<String,String>> existingReflections` — saved reflections for this date
  - `int maxPerDay` — max AI calls per day (default 3)
  - `VoidCallback? onReflectionSaved` — callback to reload state after save
- **Button logic**:
  ```
  if (!isToday) → no button
  if (!canUseAI) → no button
  if (emotions.isEmpty) → no button
  if (existingReflections.isEmpty) → "Ask AI ✨"
  else → "Mood Reflection"
  ```
- **Sheet**: pass `existingReflections`, `maxPerDay`, `onReflectionSaved`, current date

### 4.3 `lib/screens/reflection/mood_moment_sheet.dart` — Major Rework

**Changes:**
- **Accept**:
  - `List<Map<String,String>> existingReflections`
  - `int maxPerDay` (default 3)
  - `DateTime selectedDate` — for SharedPreferences key
  - `VoidCallback? onSaved` — callback after "Keep this"
- **Posture cards**:
  - All 3 always visible
  - Unconsumed + remaining slots → tapable, full card style
  - Consumed → greyed out, show saved text, tapping shows the full reflection in an expanded state
  - Past date (not today) → ALL unconsumed not tappable
- **AI call**: only on unconsumed posture tap (today only)
- **Save flow**:
  1. Call `entryProvider.addEntry(type: freeform, emotion, tagIds: [tag_reflection])`
  2. Save to SharedPreferences under `mood_reflections_YYYY_M_D`
  3. Update local state (mark as consumed)
  4. Call `onSaved` if provided
- **Count remaining**: `maxPerDay - existingReflections.length` shown as subtitle

**Remove:**
- `DraggableScrollableSheet` → use simple scrollable sheet (no drag handle needed for this use case)
- "Try a different posture" button (redundant with all 3 visible)

---

## 5. SharedPreferences Helper

Add to `lib/core/services/storage_service.dart`:

```dart
static const _moodReflectionsPrefix = 'mood_reflections_';

Future<List<Map<String, String>>> getMoodReflections(DateTime date) async {
  final key = '$_moodReflectionsPrefix${date.year}_${date.month}_${date.day}';
  final json = _prefs.getString(key);
  if (json == null) return [];
  return (jsonDecode(json) as List).cast<Map<String, String>>();
}

Future<void> saveMoodReflection(DateTime date, String posture, String text) async {
  final key = '$_moodReflectionsPrefix${date.year}_${date.month}_${date.day}';
  final existing = await getMoodReflections(date);
  existing.add({'posture': posture, 'text': text});
  await _prefs.setString(key, jsonEncode(existing));
}
```

---

## 6. UAT Test Cases

| # | Setup | Action | Expected |
|---|-------|--------|----------|
| UAT-3.1 | Today, no emoji in jar | My Day tab → scroll to jar | Jar visible, **no "Ask AI" button** |
| UAT-3.2 | Today, add entry with emoji | My Day → jar now has emoji | **"Ask AI ✨"** appears below jar |
| UAT-3.3 | Tap "Ask AI ✨" | Posture sheet opens | 3 cards: Notice/Soften/Stay, all tapable, "3 remaining" subtitle |
| UAT-3.4 | Tap NOTICE | API call → show response | Response text appears. "Keep this" button visible |
| UAT-3.5 | Tap "Keep this" | Saves to journal + state | Sheet updates: NOTICE now greyed out with saved text. "2 remaining" |
| UAT-3.6 | Tap NOTICE again (greyed out) | Card expands | Shows saved reflection text, read-only |
| UAT-3.7 | Tap SOFTEN → Keep this → Tap STAY → Keep this | 3/3 consumed | All greyed out. "0 remaining". Jar button now **"Mood Reflection"** |
| UAT-3.8 | Close app, reopen, same day | My Day → jar | "Mood Reflection" — reflections persist across app restart |
| UAT-3.9 | Navigate to a PAST day that has reflections | Calendar → select day with emoji | Jar shows. **"Mood Reflection"** → sheet: all read-only |
| UAT-3.10 | Navigate to a FUTURE day | Calendar → select tomorrow | Jar not shown (future dates locked) |
| UAT-3.11 | Past day with no reflections | Calendar → select day with emoji but no AI used | Jar visible, **no button** |
| UAT-3.12 | Debug toggle → restricted mode | Today's jar | **No "Ask AI" button** (canUseAI = false) |
| UAT-3.13 | Title format | Compare with My Day header | "My Mood Jar — Mon·May 9" matches "My Day — Mon·May 9" |
| UAT-3.14 | Midnight boundary | Add reflection today, change device date to tomorrow | Counter resets — "Ask AI ✨" appears again, 3 new slots |

---

## 7. Summary of Logic Rules

1. **Button visibility**: `canUseAI && isToday && emotions.isNotEmpty`
2. **Button text**: `reflections.isEmpty ? "Ask AI ✨" : "Mood Reflection"`
3. **Sheet posture state**: consumed → grey+text, unconsumed with slots remaining → tapable
4. **Per-day counter**: `mood_reflections` array length, max 3
5. **Flexible postures**: any posture combination within 3 daily slots
6. **Save persistence**: dual — journal entry (tag_reflection) + SharedPreferences (for sheet state)
7. **Past dates**: read-only sheet if reflections exist
8. **Timeout**: 30s per call, posture unconsumed on timeout — daily slot not wasted. Retry button shown on error.
9. **Per-posture tracking**: `Map<String, String?> _responses` and `_errors` — each posture card independently tracks its state. Tapping one posture never affects another.
10. **Response context**: each posture generates response using the day's notes + habits + mood + posture tone. Distinct responses per posture.
11. **Validation**: ✅ All UAT cases 3.1–3.14 validated on iOS + Android.
