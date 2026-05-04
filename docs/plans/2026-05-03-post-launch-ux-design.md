# Post-Launch UX Polish — Detail Design
**Created:** 2026-05-03
**Status:** Design phase — pending user approval
**Total effort:** ~4.5h

---

## Issue #7: Calendar List Badge Indicator (P3, ~1.5h)

### Problem
Calendar day cells show emotion emojis and habit completion dots, but no indicator for days with checklist entries. Users can't tell which past days had lists without navigating into each day.

### Design

#### Data Source
Pre-compute a `Map<DateTime, bool>` in `HomeScreen`:

```dart
Map<DateTime, bool> _getDayLists() {
  final entryProvider = context.read<EntryProvider>();
  final Map<DateTime, bool> result = {};
  for (final entry in entryProvider.allEntries) {
    if (entry.format != EntryFormat.list) continue;
    final date = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
    result[date] = true;
  }
  return result;
}
```

#### Visual
- Position: Below emotion emoji, above habit dots
- Implementation: `Icons.checklist_rtl` icon, size 10px, color `Colors.grey[500]`
- Alternative: Unicode `☑` (U+2611) character, font-size 8px
- **Recommendation:** Use `Icons.checklist_rtl` for consistent rendering across Android/iOS

#### CalendarWidget changes
- Add optional `Map<DateTime, bool> dayListIndicators` parameter
- In `_buildDayCell()`, render indicator below emotion when `dayListIndicators[date] == true`

#### Priority decision
- Show for ALL days with lists (past + today), or today-only?
- **Recommendation:** Show for all days with lists — helps users find past lists

### Files
- `lib/screens/home/home_screen.dart` — add `_getDayLists()`, pass to CalendarWidget
- `lib/widgets/calendar_widget.dart` — accept new param, render indicator

### Edge cases
- Day with emotion + list + habits: indicator stacks below emotion, above habits
- Day with list only (no emotion): indicator shows in emotion slot position
- Month with zero lists: no indicators shown, no perf impact
- Performance: one pass over entries (O(n)), negligible for typical data sizes

---

## Issue #8: Robot Trial/Error State Clarity (P2, ~1h)

### Problem
Floating robot has multiple states but the visual difference between "no API key" and "trial expired" may not be clear enough to users.

### Design

#### State matrix

| State | Opacity | Animation | Badge | Tap Action |
|-------|:-------:|:---------:|:-----:|------------|
| **API key active** | 100% | Idle bobbing | None | Open Assistant |
| **Trial active** | 100% | Idle bobbing | "N days" chip | Open Assistant |
| **Trial expired** | 50% | Slow/sad pulse | "Expired" badge | Snackbar + Settings |
| **No key, no trial** | 50% | Still (no anim) | "!" badge | Snackbar + Settings |

#### Changes

1. **Expired badge** — replace current text with a small chip: clock icon + "Expired" / "已过期" (8px font)
2. **Expired tap** — navigate to Settings → AI Providers instead of showing snackbar. Removes the extra tap.
3. **Tooltip on long-press** — explain what to do:
   - EN: "Add your own API key in Settings → AI Providers to keep chatting"
   - ZH: "在设置 → AI 服务商中添加你的 API Key 以继续对话"
4. **App lifecycle re-check** — `didChangeAppLifecycleState(AppLifecycleState.resumed)` triggers `_checkRobotState()` so the robot updates immediately when app resumes (e.g., user added key in another app's browser)

#### Implementation

```dart
// In floating_robot.dart
void _onTap() {
  if (_hasActiveKey || _trialActive) {
    _openAssistant();
  } else {
    _navigateToSettings();
  }
}

void _navigateToSettings() {
  // Navigate to main screen with settings tab pre-selected
  // Or open Settings directly with AI Providers section scrolled
}
```

### Files
- `lib/widgets/floating_robot.dart` — state re-check, badge, tap behavior
- `lib/app.dart` — lifecycle listener if not already present

### Edge cases
- Rapid tap during animation: debounce or ignore during transition
- Trial expires while app is open: next lifecycle event or tab switch triggers re-check
- User dismisses expired badge: badge persists (don't hide — it's the only indicator)

---

## Issue #9: One-List-Per-Day Transition UX (P3, ~45min)

### Problem
When user toggles Note→List and a list already exists for today, `pushReplacement` navigates to the existing list without explanation. The screen swap feels jarring.

### Design

#### Before navigation
Show a brief snackbar **before** the pushReplacement:

```dart
// In AddEntryScreen._switchFormat()
if (existingList != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l.listAlreadyExistsHint), // "Today's list already exists — opening it" / "今天已有清单，正在打开"
      duration: const Duration(milliseconds: 800),
    ),
  );
  // Brief delay to let user read, then navigate
  await Future.delayed(const Duration(milliseconds: 400));
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => AddEntryScreen(existingEntry: existingList),
    ),
  );
  return;
}
```

#### Transition animation
Use `PageRouteBuilder` with a crossfade (300ms) instead of the default slide:

```dart
Navigator.of(context).pushReplacement(
  PageRouteBuilder(
    pageBuilder: (_, __, ___) => AddEntryScreen(existingEntry: existingList),
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  ),
);
```

#### Alternative: Disable the toggle
If user prefers no automatic navigation, disable the "List" segment when a list exists:

```dart
SegmentButton(
  segments: [
    ButtonSegment(value: EntryFormat.note, label: Text(l.noteFormat)),
    ButtonSegment(value: EntryFormat.list, label: Text(l.listFormat), enabled: !_hasTodayList),
  ],
  ...
)
```

**Recommendation:** Snackbar + fade transition. Keeps the feature working while removing confusion.

### Files
- `lib/screens/add_entry_screen.dart` — `_switchFormat()` method
- `lib/l10n/app_en.arb`, `app_zh.arb` — one new string: `listAlreadyExistsHint`

---

## Issue #10: Carry-Forward Banner Timing (P3, ~30min)

### Current state (after redesign)
The carry-forward is now an explicit dialog, not auto. After the user taps "Add", items are created with `fromPreviousDay: true` flag. The banner still auto-clears on next frame.

### Problem
The banner has been superseded by the explicit dialog. The user already chose to carry forward — they know what happened. The banner is now redundant for the carry-forward case but could still serve a purpose: reminding users mid-session which items came from yesterday.

### Design

#### Option A — Remove the banner (recommended)
Since the user explicitly chose to carry forward via dialog, the banner is unnecessary. The `fromPreviousDay` label on each item already serves as the indicator. Remove `_lastCarriedCount`, `clearCarriedBanner()`, and the banner rendering from `EntryCard`.

**Effort:** ~15min, cleanup only.

#### Option B — Keep banner but persist
Keep the banner but make it dismiss-on-tap (not auto-clear). User taps the banner or the "×" to dismiss. This gives users full control over when the banner goes away.

**Effort:** ~30min.

### Files (for either option)
- `lib/providers/entry_provider.dart` — modify or remove `_lastCarriedCount` / `clearCarriedBanner()`
- `lib/widgets/entry_card.dart` — modify or remove `_buildCarriedOverBanner()`
- `lib/screens/home/home_screen.dart` — modify `_buildListEntryCards()`

### Recommendation
**Option A** — the explicit dialog made the auto-banner redundant. Clean removal simplifies the code. The `fromYesterdayLabel` on items serves as the persistent indicator.

---

## Issue #11: List Checkbox UX Consistency (P3, ~1h)

### Current state (after redesign)
- **EntryCard** on today: checkboxes tappable + strikethrough
- **EntryCard** on past days: checkboxes greyed out, no tap
- **EntryDetailScreen**: same pattern as EntryCard
- **AddEntryScreen** (list editor): checkboxes tappable + reorder handles + "Yesterday" labels

### Problem
The three list views now have consistent checkbox styling but different interaction capabilities. Users may not understand which screen to use for what purpose.

### Design

#### Add subtle helper text to the edit screen

In `AddEntryScreen` list mode, add a small caption below the title field (only when items exist):

```
"Tap to check · Drag to reorder · × to remove"
"点击选中 · 拖动排序 · × 删除"
```

Style: `Theme.of(context).textTheme.labelSmall`, `Colors.grey[500]`, italic, 10px.

#### Make drag handle more discoverable

The current drag handle is a small `Icons.drag_handle` (20px, grey). Make it slightly more prominent:

- Size: 20px → 24px
- Add a very subtle background on hover/long-press (Material ripple)
- Keep the same icon and color

#### Add heading context in EntryDetailScreen

When viewing a list entry in detail, show a small subtitle below the title:

```
"Checklist · X/Y items done"
"清单 · X/Y 已完成"
```

This distinguishes list detail from note detail at a glance.

### Files
- `lib/screens/add_entry_screen.dart` — helper text + drag handle size
- `lib/screens/moment/entry_detail_screen.dart` — subtitle context
- `lib/l10n/app_en.arb`, `app_zh.arb` — 1 new string: `listEditHint`

---

## Issue #12: Settings Trial Banner Dismiss (P3, ~45min)

### Problem
The trial banner in Settings persists even after the user has added their own API key. It should be dismissible or auto-hide when no longer relevant.

### Design

#### Banner display logic

```dart
bool _shouldShowTrialBanner() {
  final trialStatus = TrialService.getTrialStatus();
  
  // Never show if user has own API key configured
  if (_llmProviderCount > 0) return false;
  
  // Show during active trial
  if (trialStatus == TrialStatus.active) return true;
  
  // Show when expired (encourage BYOK)
  if (trialStatus == TrialStatus.expired) return true;
  
  // Never used trial + no key: show the "Start trial" variant
  if (trialStatus == TrialStatus.neverUsed) return true;
  
  return false;
}
```

#### Dismiss behavior

- Add a small "Dismiss" / "不再显示" text button at the trailing edge of the banner
- On dismiss, set `SharedPreferences` key `trial_banner_dismissed` to `true`
- If user later removes their API key, reset the dismissed flag (banner reappears)
- Expired trial + no key: banner should NOT be permanently dismissible — it's the only way to know trial ended

#### Banner variants

| State | Banner Content | Dismissible? |
|-------|---------------|:------------:|
| **Trial never used** | "Try AI for Free — 7 Days" + Start button | Yes |
| **Trial active** | "Trial Active — X days remaining" | Yes |
| **Trial expired** | "Trial Expired — Add your own API key" | No (critical info) |
| **User has own key** | Hidden entirely | N/A |

### Files
- `lib/screens/settings/settings_screen.dart` — banner logic + dismiss
- `lib/core/services/trial_service.dart` — may need `neverUsed` status exposed

### Edge cases
- User starts trial → adds own key during trial: banner hides (key takes priority)
- User adds key → removes key later: banner reappears (state is trial-appropriate)
- Expired banner dismissed → app restarted → banner shows again (not dismissible when critical)

---

## Summary

| # | Issue | Recommendation | Effort | Phase |
|---|-------|---------------|:------:|-------|
| 7 | Calendar list badge | `Icons.checklist_rtl` on day cells with lists | ~1.5h | Month 1 |
| 8 | Robot trial states | Expired → tap opens Settings; tooltip; lifecycle re-check | ~1h | Month 1 |
| 9 | One-list transition | Snackbar + fade transition | ~45min | Month 1 |
| 10 | Carry-forward banner | Remove auto-banner (redundant after explicit dialog) | ~30min | Month 1 |
| 11 | Checkbox UX | Helper text + drag handle size + detail subtitle | ~1h | Month 1 |
| 12 | Trial banner dismiss | Smart logic: hide with own key, dismissible when non-critical | ~45min | Month 1 |

### Implementation order
1. **#8** (Robot states) — P2, most impactful for trial users
2. **#10** (Banner cleanup) — quick win, removes dead code
3. **#12** (Trial banner) — natural companion to #8
4. **#9** (List transition) — small improvement, smooths the list experience
5. **#11** (Checkbox UX) — ties together the list consistency work
6. **#7** (Calendar badge) — largest effort, lowest priority

### Files affected
| File | Issues |
|------|--------|
| `lib/widgets/floating_robot.dart` | #8 |
| `lib/providers/entry_provider.dart` | #10 |
| `lib/widgets/entry_card.dart` | #10 |
| `lib/screens/home/home_screen.dart` | #7, #10 |
| `lib/widgets/calendar_widget.dart` | #7 |
| `lib/screens/add_entry_screen.dart` | #9, #11 |
| `lib/screens/moment/entry_detail_screen.dart` | #11 |
| `lib/screens/settings/settings_screen.dart` | #12 |
| `lib/l10n/app_en.arb` / `app_zh.arb` | #9, #11 |

### New i18n strings (3 total)
| Key | EN | ZH |
|-----|----|----|
| `listAlreadyExistsHint` | "Today's list already exists — opening it" | "今天已有清单，正在打开" |
| `listEditHint` | "Tap to check · Drag to reorder · × to remove" | "点击选中 · 拖动排序 · × 删除" |
| `listDetailSubtitle` | "Checklist · {done}/{total} done" | "清单 · {done}/{total} 已完成" |

### Consultation questions

1. **#10 (Banner)** — Remove the auto-banner entirely, or keep it dismiss-on-tap?
2. **#8 (Robot)** — Should expired-state robot tap open Settings directly (skip snackbar)?
3. **#9 (List transition)** — Snackbar approach preferred, or disable the toggle?
4. **#7 (Calendar badge)** — Use `Icons.checklist_rtl` or Unicode `☑` character?
