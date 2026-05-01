# UX Implementation Plan — Blinking Notes
**Based on:** Blinking_Notes_UX_Review.docx + TODO-2026-03-23.md
**Date:** 2026-03-23
**Rule:** All changes build in debug first, verify on emulator before any release build.

---

## C1 Decision — Floating AI Robot

**Chosen approach:** Keep robot, apply smart visibility + API-state awareness.

### Visibility rules (which tabs show the robot)

| Tab | Show Robot? | Rationale |
|-----|-------------|-----------|
| Calendar (0) | ✅ Yes | Reflect on today's entries and habits |
| Moments (1) | ✅ Yes | Analyze past entries, ask about patterns |
| Routine (2) | ✅ Yes | Motivation prompts, habit coaching |
| Keepsakes (3) | ❌ No | Charts/cards are self-contained; AI adds no clear action |
| Settings (4) | ❌ No | Config screen; AI entirely out of context here |

**Implementation:** Pass `currentTabIndex` from `MainScreen` into `FloatingRobotWidget`.
Hide (`SizedBox.shrink()`) when `currentTabIndex >= 3`.

### API key state awareness

| State | Visual | Tap behaviour |
|-------|--------|---------------|
| API key configured | Full opacity, bobbing animation (current) | Opens `AssistantScreen` |
| No API key | 50% opacity, no animation, small badge `!` | Shows snackbar: "Add your API key in Settings → AI Providers to use the assistant" |

**Implementation:** Add `static Future<bool> hasApiKey()` to `LlmService` (reads SharedPrefs).
`FloatingRobotWidget.initState()` calls it once and stores result in `_hasApiKey` state bool.
Re-check on `didChangeDependencies` so it updates immediately after user saves key in Settings.

---

## Phase 1 — Critical UX Fixes + All Visible Language Bugs (~6–7 hours)
*One debug build → full emulator test across all screens → then Phase 2*

### GROUP A — Critical UX (C1–C5)

### P1-1: Robot smart visibility + API-state awareness (C1)
**Files:** `lib/app.dart`, `lib/widgets/floating_robot.dart`, `lib/core/services/llm_service.dart`

`app.dart` changes:
- Pass `_currentIndex` to `FloatingRobotWidget`

`floating_robot.dart` changes:
- Accept `currentTabIndex` parameter
- Return `SizedBox.shrink()` when `currentTabIndex >= 3`
- On `initState` + `didChangeDependencies`: call `LlmService.hasApiKey()` → store in `_hasApiKey`
- When `!_hasApiKey`: render at `Opacity(opacity: 0.5)`, stop animations, show `!` badge
- Different `onTap`: show snackbar instead of opening screen

`llm_service.dart` changes:
- Add `static Future<bool> hasApiKey()` — loads prefs, checks selected provider's `apiKey` is non-empty

### P1-2: Calendar day-of-week + month header (C2)
**File:** `lib/widgets/calendar_widget.dart:54,75`

Weekday labels — current: `const weekdays = ['日','一','二','三','四','五','六'];`
Fix: Pass `isZh` into calendar widget; use locale-appropriate array.
EN: `['Sun','Mon','Tue','Wed','Thu','Fri','Sat']`
ZH: `['日','一','二','三','四','五','六']`

Month/year header — current: always `DateFormat('yyyy年M月')`
Fix: EN → `DateFormat('MMMM yyyy').format(date)` → "March 2026"
ZH → `DateFormat('yyyy年M月').format(date)` → "2026年3月"

### P1-3: Truncated AI chip (C3)
**File:** `lib/screens/assistant/assistant_screen.dart:531-539`

Fix: Shorten chip labels to fit. Add `overflow: TextOverflow.ellipsis` to all chip `Text` widgets as safety net.

### P1-4: ❌ icon → ○ for pending habits (C4)
**File:** `lib/screens/home/home_screen.dart:193-200`

Replace `Icons.cancel` (red) with `Icons.radio_button_unchecked` (grey/neutral) for
habits that are pending or missed on the Calendar habit check-in row.

### P1-5: Reminder field disclaimer (C5)
**File:** `lib/screens/routine/routine_screen.dart` — Reminder field section

Add `helperText` to the reminder `TextField`:
EN: `"Local only — no data is sent anywhere"`
ZH: `"仅本地提醒，不发送任何数据"`

---

### GROUP B — All Remaining Visible Language Bugs

### P1-6: Routine frequency labels (HIGH VISIBILITY)
**Files:** `lib/models/routine.dart:116`, `lib/screens/routine/routine_screen.dart:251,440`

Current: `frequencyLabel` getter always returns Chinese ("每天", "每周一三五", "随时")
Shown on every routine card in All tab and History tab.

Fix: Add `frequencyLabelFor(bool isZh)` method to `Routine` model:
```
daily    → EN "Daily"         ZH "每天"
weekly   → EN "Weekly: M W F" ZH "每周一三五"
scheduled → EN "2026-03-23"   ZH "2026年3月23日"
adhoc    → EN "On demand"     ZH "随时"
```
Update both call sites to pass `isZh` from context.

### P1-7: Add Routine — weekly day picker labels
**File:** `lib/screens/routine/routine_screen.dart:549`

Current: `static const List<String> _dayLabels = ['', '一', '二', '三', '四', '五', '六', '日'];`
Shown in the Add/Edit Routine dialog when Frequency = Weekly.

Fix: Make locale-aware inside `build()`:
EN: `['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']`
ZH: `['', '一', '二', '三', '四', '五', '六', '日']`

### P1-8: AI assistant default name
**File:** `lib/providers/ai_persona_provider.dart:9,19`

Current: default name hardcoded as `'AI 助手'` regardless of locale.
Fix: On first load, check SharedPreferences locale (or use device locale fallback):
EN default: `'AI Assistant'` | ZH default: `'AI 助手'`
Note: If user has already saved a custom name, do NOT override it.

### P1-9: Entry card share subject
**File:** `lib/widgets/entry_card.dart:66`

Current: `Share.share(entry.content, subject: '来自 Blinking')`
Fix: Make locale-aware — requires passing `isZh` to `EntryCard` or reading locale from context.
EN: `'From Blinking'` | ZH: `'来自 Blinking'`

### P1-10: Card preview share text
**File:** `lib/screens/cherished/card_preview_screen.dart:94-95`

Current: share text always appends `'— 来自 Blinking ✨'` regardless of locale.
Fix: `isZh` already read at line 92.
EN: `'— From Blinking ✨'` | ZH: `'— 来自 Blinking ✨'`

---

## Phase 2 — High Priority + AI Features + Bug Fixes
*Updated 2026-03-23 after Phase 1 completion and user decisions*

### Status of original P2 items
| ID | Status |
|----|--------|
| P2-2 Rename Keepsakes→Insights | **DEFERRED** — "Keepsakes" covers shelf+cards+summary; "Insights" only fits summary. Revisit after beta. |
| P2-8 AI default name | **DONE in P1** — `displayNameFor(isZh)` already implemented. |

---

### P2-1: App color — iOS blue → brand teal
**File:** `lib/core/config/theme.dart`

| Role | Current | New |
|------|---------|-----|
| Primary | `Color(0xFF007AFF)` | `Color(0xFF2A9D8F)` |
| Primary dark | `Color(0xFF0056CC)` | `Color(0xFF21867A)` |
| Background | `Color(0xFFF2F2F7)` | `Color(0xFFF4F8F7)` |

Everything derived from `primaryColor` (FAB, nav icons, chips, calendar selection, progress bars)
updates automatically. No manual color changes elsewhere needed.

### P2-2: DEFERRED — Keepsakes tab rename
Revisit post-beta once tab purpose is clearer to users.

### P2-3: Mood emoji label — show on selection only (H4)
**File:** `lib/screens/add_entry_screen.dart`

- When an emotion emoji is tapped, show its name below the row (e.g. "😊 Joyful")
- No label shown when nothing is selected (keep UX clean)
- Add `Semantics(label: emojiName)` to each emoji tap target for TalkBack accessibility
- Add ARB keys for all 10 emotion names: `moodJoyful`, `moodSad`, etc.

### P2-4: Habit completion chart — hide when all-zero (H6)
**File:** `lib/screens/cherished/summary_tab.dart`

Add: `final allZero = rates.values.every((v) => v == 0.0);`
→ if `rates.isEmpty || allZero` → show placeholder instead of flat-zero chart.

### P2-5: Cards empty state — improve visual (H7)
**File:** `lib/screens/cherished/cards_tab.dart`

Replace `🎴` emoji placeholder with `Icon(Icons.style_outlined, size: 64)` using teal color.
EN copy: `"No cards yet"` → `"Your first card is a tap away"`

### P2-6: AI "Secrets" tag — exclude private notes from AI context
**Files:** `lib/core/services/storage_service.dart`, `lib/screens/assistant/assistant_screen.dart`, `lib/l10n/`

Seed system tag on next app launch (same migration pattern as `tag_reflection`):
```
id: 'tag_secrets', name: 'Secrets'/'秘密', color: '#9E9E9E', isSystem: true
```
In `AssistantScreen._filterEntriesInRange()`, silently exclude tagged entries before
building the AI context block. Update the loaded-entries message:
EN: `"📖 Loaded N entries (M private entries excluded)"`
ZH: `"📖 已加载 N 条笔记（已排除 M 条私密笔记）"`

### P2-7: OpenRouter onboarding — tappable link + move to top
**Files:** `lib/core/services/llm_service.dart`, `lib/screens/settings/settings_screen.dart`

- Move OpenRouter to position 0 in the default providers list (first shown to new users)
- Pre-fill its `baseUrl` as `https://openrouter.ai/api/v1`
- In Settings AI Provider edit dialog: add a tappable "Get a free key →" link below the API key field
  that opens `https://openrouter.ai` via `url_launcher`
- Add helper text on the API key field: "Paste your key here"

### P2-BUG-1: API key save → robot re-check not triggered
**Root cause:** `FloatingRobotWidget` calls `LlmService.hasApiKey()` in `initState` and
`didChangeDependencies`, but saving an API key in Settings only writes to SharedPreferences —
no Provider notifies the widget tree, so `didChangeDependencies` never fires.

**Fix:** Add a lightweight `LlmConfigNotifier extends ChangeNotifier` to the Provider tree.
Settings screen calls `context.read<LlmConfigNotifier>().notify()` after saving any provider.
`FloatingRobotWidget` watches `LlmConfigNotifier` to re-run `_checkApiKey()` immediately.

**Files:** new `lib/providers/llm_config_notifier.dart`, `lib/app.dart`, `lib/screens/settings/settings_screen.dart`, `lib/widgets/floating_robot.dart`

### P2-BUG-2: Active provider not visually distinct when multiple keys configured
**File:** `lib/screens/settings/settings_screen.dart`

Current: radio button alone indicates active provider — easy to miss.
Fix: Highlight the active provider tile with:
- `color: tealPrimary.withOpacity(0.08)` background on the active tile
- `"Active"` badge chip (small, teal) next to the provider name
- Radio button retained for tap-to-switch

---

## Phase 3 — Medium Priority (v1.1, post-beta)

| ID | Issue | File | Effort |
|----|-------|------|--------|
| M1 | `Moment` tab ≠ `Moments` screen title | `app_en.arb` | 15 min |
| M3 | `我的卡片` filter chip in English UI | `cards_tab.dart` | 15 min |
| M4 | Add Tag misplaced at top of Settings | `settings_screen.dart` | 1 hr |
| M5 | Heavy bordered text field in Add Memory | `add_entry_screen.dart` | 1 hr |
| M6 | Completed habits no visual feedback in Today | `routine_screen.dart` | 2 hrs |
| M7 | First-launch onboarding card | new widget + SharedPrefs flag | 2–3 hrs |

---

## Phase 4 — Post-Beta Sprint

| Item | Notes |
|------|-------|
| H2 — Streak badges on Routine cards | Needs streak computation in `RoutineProvider` |
| H3 — Backdate field in Add Memory | Medium feature; careful UX design needed |
| H8 — AI avatar (blink-arc motif) | Needs design asset first |
| Card AI image generation (TODO item 1) | Future: when AI image gen available |
| Custom empty state illustrations | Design asset creation needed |

---

## File Change Map

| File | Phase | Change summary |
|------|-------|----------------|
| `lib/core/services/llm_service.dart` | P1 | Add `static hasApiKey()` |
| `lib/widgets/floating_robot.dart` | P1 | Tab visibility + API state greying |
| `lib/app.dart` | P1, P2 | Pass tab index to robot; rename Keepsakes |
| `lib/widgets/calendar_widget.dart` | P1 | Locale-aware day labels + month header |
| `lib/screens/assistant/assistant_screen.dart` | P1, P2 | Chip fix; Secrets tag exclusion; locale-aware count message |
| `lib/screens/home/home_screen.dart` | P1 | ❌ → ○ on pending habits |
| `lib/screens/routine/routine_screen.dart` | P1 | Reminder disclaimer |
| `lib/core/config/theme.dart` | P2 | Blue → teal palette |
| `lib/screens/add_entry_screen.dart` | P2 | Mood emoji labels + semantics |
| `lib/screens/cherished/summary_tab.dart` | P2 | All-zero chart → empty state |
| `lib/screens/cherished/cards_tab.dart` | P2 | Empty state icon + copy |
| `lib/core/services/storage_service.dart` | P2 | Seed `tag_secrets` system tag |
| `lib/screens/settings/settings_screen.dart` | P2 | Trial key helper text + OpenRouter default |
| `lib/providers/ai_persona_provider.dart` | P2 | Locale-aware default name |
| `lib/l10n/app_en.arb` | P1, P2 | calWeekday keys, insightsTab, moodLabels, aiSecretsTagName |
| `lib/l10n/app_zh.arb` | P1, P2 | Same keys in ZH |

---

## Effort Summary

| Phase | Items | Est. Time |
|-------|-------|-----------|
| Phase 1 — Critical UX + all language bugs | 10 items | ~6–7 hrs |
| Phase 2 — High priority + AI features | 8 items | ~8–10 hrs |
| **Total P1+P2** | **18 items** | **~2–3 dev days** |
| Phase 3 — Medium | 6 items | ~1 dev day |
| Phase 4 — Post-beta | — | separate sprint |

---

## Recommended Execution Order

1. **Phase 1** as one batch → single debug APK → emulator smoke test all 5 changes
2. **Phase 2** as one batch → single debug APK → full visual regression (all 13 screens)
3. If both pass → release AAB → upload to Play Internal Testing
4. **Phase 3** after first internal tester feedback
