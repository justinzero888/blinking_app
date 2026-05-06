# Lessons Learned — Session 2026-05-05

**Duration:** Full day (~10 hours)
**Scope:** 7 phases across 18 files, 106 tests, multiple deployment cycles

---

## What Went Well

### 1. Data-driven debugging
Analyzing the actual 1.6 GB backup ZIP file to understand the root cause (204 uncompressed 12MP photos) was far more effective than guessing. Concrete numbers made decisions easy: 99.93% of backup size was images. Solution was obvious.

### 2. Compression estimates before coding
Running Python/PIL on actual backup images to estimate compressed sizes (1.6 GB → ~89 MB → confirmed 4.8 MB on real test backup) gave confidence before implementing. No wasted code.

### 3. Visual build verification
When user couldn't see changes after multiple deploys, adding a visible text change ("Routines · Build/Do/Reflect" in app bar) immediately confirmed whether the right code was running. Saved hours of guessing.

### 4. Seed data for testing
Auto-generating test data (entries across 30 days, routines with completions) on first launch eliminated manual setup for every clean install. User could validate features immediately.

---

## What Went Wrong & Root Causes

### 1. File structural damage from cascading edits
**Symptom:** `routine_screen.dart` accumulated brace mismatches, extra closing parens, and orphaned code after ~15 edits to the same file. `byok_setup_screen.dart` lost 6 method definitions (155 lines) in one bad edit.

**Root cause:** Large oldString matches that spanned method boundaries. When an edit matched from inside `_buildAdvancedSection` to `_testAndSave`, it consumed everything between them — including 6 other methods.

**Fix going forward:** For files undergoing heavy edits in a single session, use `git` to checkpoint between phases. Without git, keep a backup copy. Also: prefer targeted edits to specific methods rather than large-block replacements that span class boundaries.

### 2. Deployment not refreshing code
**Symptom:** Three back-to-back deploys and user still saw old tab names (全部/今日/记录 instead of 建造/执行/反思).

**Root cause:** `flutter run` with hot restart preserves some state. Old SharedPreferences cached previous tab selection. Build artifacts from `build/` may not have been fully invalidated.

**Fix:** Nuclear clean sequence before deploy when changes aren't visible:
```bash
rm -rf build/ .dart_tool/
flutter clean
flutter pub get
xcrun simctl uninstall <device> com.blinking.blinking
flutter run
```

### 3. Test data seed running in test environment
**Symptom:** 5 HomeScreen tests failed because routine seed created completions that changed test expectations.

**Root cause:** Seed was placed in `RoutineProvider.loadRoutines()` which runs in both production and test environments. The test's `_FakeStorage` didn't seed defaults, so `_routines.isEmpty` was true, triggering the seed.

**Fix:** Moved seed to `main.dart` (before `runApp()`), which doesn't execute in test files. Production-only initialization belongs outside shared provider code.

### 4. Offline preview showing 0 days on fresh install
**Symptom:** Entitlement banner showed "0 days left" instead of "21 days" on second app launch.

**Root cause:** `_applyLocalPreview()` checked `if (_state == EntitlementState.restricted)`. On first launch, state was default `restricted` → preview started. On second launch, `_saveState()` had persisted `state = preview`, so the condition was false → days weren't recalculated.

**Fix:** Changed condition to `if (_jwt == null || _jwt!.isEmpty)` — always recalculate local preview when there's no server JWT, regardless of cached state. Also persisted `_previewDaysRemaining` in `_saveState()`.

### 5. Seed data accumulation bug
**Symptom:** Streaks showed 0 despite seed creating completions.

**Root cause:** Loop used `routine.completionLog` (always empty original) instead of accumulating. Each `storage.updateRoutine()` overwrote the previous with only ONE completion.

**Fix:** Used `current` variable to track accumulated state:
```dart
var current = routine;
for (...) {
  current = current.copyWith(completionLog: [...current.completionLog, ...]);
  await storage.updateRoutine(current);
}
```

### 6. Misleading error message for server unavailability
**Symptom:** "API key is invalid or expired" when actual problem was server not deployed.

**Root cause:** Local preview token `preview_local` was sent to the trial chat endpoint, server returned 401. `LlmService` interpreted 401 as invalid key without checking if it was a local-only token.

**Fix:** Detected `trial_token == 'preview_local'` in `LlmService._loadConfig()` and threw a clear message: "AI requires the server to be available. Use your own API key or wait for server deployment."

---

## Process Improvements

| Issue | Mitigation |
|-------|-----------|
| File damage from many edits | Use git checkpoint or backup file before heavy editing session |
| Deployment not refreshing | Nuclear clean + uninstall + visual verification marker |
| Test data leaking into tests | Keep seed logic in `main.dart`, never in shared providers |
| State machine edge cases | Persist ALL computed state; don't rely on re-computation alone |
| Accumulation in loops | Always verify mutable state is tracked across iterations |
| Error message accuracy | Map error conditions to specific causes, not generic HTTP codes |

---

## Architecture Decisions Validated

1. **Image copies in app sandbox are correct** — WeChat does the same. Gallery links are unreliable on both platforms.
2. **Three-layer compression (pick/save/export)** covers all entry points and handles existing data.
3. **Provider-based sync** already supported real-time cross-tab updates; only needed a TabController listener for edge cases.
4. **Seed data in main.dart** keeps tests clean and production bootstrap straightforward.
