# DEF-M-001: Save Keepsake Fails on iOS (regression)

**Defect ID:** DEF-M-001  
**Severity:** P2 — feature-blocking on iOS  
**Version:** v1.2.0+44 (commit `3e3f67b`)  
**Platform:** iOS only (iPhone + iPad simulators). Android works correctly.  
**Reported:** 2026-05-31

---

## Symptom

Tap "Save Keepsake" in `CardBuilderSheet` → "Render failed, please retry" snackbar. Card is not persisted. Occurs on both iPhone and iPad simulators. Android emulator saves successfully.

---

## Root Cause Analysis

### Code changes: no keepsake code was touched

Diff between v42 (working) and v44 (broken) — all 7 production source changes:

| File | Change | Touches card render? |
|------|--------|:---:|
| `main.dart` | Crash guard + removed demo entries | No |
| `purchases_service.dart` | `proPriceString` getter + error propagation | No |
| `paywall_screen.dart` | Dynamic price from RC | No |
| `onboarding_screen.dart` | `context.watch<PurchasesService>` for price | No |
| `settings_screen.dart` | Same | No |
| `transition_screen.dart` | Same | No |
| `floating_robot.dart` | Same | No |
| `soft_prompt_service.dart` | Price string + provider import | No |

**Zero changes** to `card_builder_sheet.dart`, `card_render_service.dart`, `card_provider.dart`, or any keepsake-related code.

### Failure path

```
_handleSave() → OverlayEntry.insert() → await endOfFrame → captureFromKey()
                                                              ↓
                                                    boundaryKey.currentContext
                                                    ?.findRenderObject() == null
                                                              ↓
                                                    return null → "Render failed"
```

`captureFromKey()` at `card_render_service.dart:109` returns `null` when the `RepaintBoundary` has not been laid out/painted. The `await endOfFrame` on line 525 is intended to wait for this, but on iOS simulators the overlay rendering can complete AFTER `endOfFrame` resolves.

### Why it worked before and fails now

The `OverlayEntry` off-screen rendering pipeline (insert widget at `Positioned(left: -2000)` then capture) is **known to be fragile on iOS** (CLAUDE.md Lesson 13). It was the third attempt and the only one that partially worked, but it relies on a timing assumption (`endOfFrame` guarantees the overlay is painted) that is not universally true on iOS.

Two factors increased failure probability:

1. **Removal of demo entries** (`_seedDemoEntries` in `main.dart`): In v42, the 8 demo entries caused multiple render cycles during launch (entries loading → calendar → moment list). This "pre-warmed" the rendering pipeline. Without them, the first overlay insert may happen on a "colder" pipeline where the frame timing is tighter.

2. **iOS 26.x beta simulator**: The iOS 26 beta (shipping with Xcode 26.4.1 on macOS 26.2 Tahoe) may have changed the compositor timing for off-screen `Positioned` widgets in overlays.

### Evidence

- Android (same code, different compositor): works every time
- No card/keepsake code changed between v42 and v44
- `captureFromKey` returns null on iOS — the `RepaintBoundary` findRenderObject fails

---

## Recommended Fix

Add a `postFrameCallback` delay before `captureFromKey` to guarantee the overlay has been painted:

```dart
// lib/widgets/card_builder_sheet.dart, ~line 525
await WidgetsBinding.instance.endOfFrame;
await Future.delayed(const Duration(milliseconds: 100));  // ← ADD THIS
renderedPath = await CardRenderService.captureFromKey(key);
```

Or, more robustly, use a `Completer` triggered by `addPostFrameCallback`:

```dart
final completer = Completer<void>();
WidgetsBinding.instance.addPostFrameCallback((_) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    completer.complete();
  });
});
await completer.future;
renderedPath = await CardRenderService.captureFromKey(key);
```

---

## Workaround

- Create at least one entry and navigate around the app before attempting Save Keepsake — this "warms" the rendering pipeline
- Or: test on Android emulator where the issue does not occur
- Or: test on a physical iOS device (may behave differently from sim)

---

## Impact Assessment

| Area | Impact |
|------|--------|
| iOS production | **P2** — if production behaves like sim, keepsake save fails on all iOS devices. v42 production IPA may also be affected (same code path). |
| iOS simulator UAT | Blocked — keepsake creation flows (k1–k10) cannot pass |
| Android | Not affected |

---

## Verification

1. Apply fix
2. `flutter analyze` — 0 errors
3. Fresh install on iPhone + iPad sims
4. Create entry → EntryDetail → Save as Keepsake → assert "Keepsake saved" snackbar
5. Run k1 Maestro flow — should pass
