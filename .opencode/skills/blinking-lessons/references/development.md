# Development Anti-Patterns

## Cascading Edit Failures

**Problem:** Multiple edits to the same file in one session cause bracket imbalances, orphaned duplicate code blocks, and corrupted method signatures. Example: `routine_screen.dart` accumulated brace mismatches after ~15 edits. `byok_setup_screen.dart` lost 6 method definitions (155 lines) when one edit's oldString spanned from `_buildAdvancedSection` to `_testAndSave`, consuming everything between them.

**Mitigation:** Use `git` as checkpoint between editing phases. Prefer targeted edits to specific methods rather than large-block replacements that span class boundaries.

## Async Method Ordering Bugs

**Problem:** `rescheduleAll()` called `cancelAll()` which ran AFTER `scheduleRoutine()` due to `loadRoutines()` being async in a `create:` callback. Notifications were scheduled, then immediately cancelled.

**Mitigation:** Never put `cancelAll()` inside a method that might run after user actions. Cancel specific IDs, not everything. Chain async calls explicitly.

## Stale Seed Data (Duplicate Sources)

**Problem:** `DefaultRoutines.defaults` (3 old routines) was stale while `StorageService._getDefaultRoutines()` (31 new routines) was correct. `DefaultTags.defaults` (8 old tags) was stale while `StorageService._getDefaultTags()` (6+3 new tags) was correct. If anyone called `TagRepository.resetToDefaults()`, old data would overwrite new.

**Mitigation:** Every pre-built dataset must have ONE canonical source. If a class like `DefaultRoutines` exists, `StorageService` must import from it — not duplicate it.

## IDs Changed Without Global Search

**Problem:** `lens_builtin_zengzi`, `tag_reflection`, `tag_secrets` were hardcoded in 10+ files. When renamed, grep-and-replace missed references, created duplicates, and broke persona-specific lenses.

**Mitigation:** Every ID referenced in logic must be a named constant. Single source of truth. When renaming: global search for the old string across ALL files first.

## SharedPreferences Overload

**Problem:** Base64-encoded 256x256 images (24-34KB) exceeded iOS `NSUserDefaults` 4KB practical limit. Multi-custom styles saved only the last one.

**Mitigation:** If data > 1KB, use SQLite or filesystem. Images → `ApplicationDocumentsDirectory` with path stored in prefs.

## Default Persona Refactoring Checklist

When changing defaults (e.g. persona from Elara → Kael):

| File | What to check |
|------|---------------|
| Model constants | `defaultStyleId`, `defaultActiveSetId` |
| Provider defaults | `AiPersonaProvider._load()` initial values |
| Documentation | CLAUDE.md, session summaries |
| Seed data | `_getDefaultRoutines()`, `_getDefaultTags()` |
| Lens defaults | `DefaultLensSets.defaults()`, `defaultActiveSetId` |
| Global search | Search every file for the old default string |

## API Version Migration

**Problem:** `flutter_local_notifications` v21 changed `initialize()`, `zonedSchedule()`, `show()`, `cancel()` from positional to named parameters. Required rewriting entire `NotificationService`.

**Mitigation:** After `flutter pub add`, immediately `flutter analyze` and fix all new compilation errors. Don't defer API migration.

## Test Data Leaking Into Test Suite

**Problem:** Seed placed in `RoutineProvider.loadRoutines()` ran in both production and test. The test's `_FakeStorage` didn't seed defaults, so `_routines.isEmpty` was true, triggering seed and breaking test expectations.

**Mitigation:** Keep seed logic in `main.dart` (before `runApp()`), which doesn't execute in test files.

## State Machine Edge Cases

**Problem:** `_applyLocalPreview()` checked `if (_state == EntitlementState.restricted)`. On first launch, state was default `restricted` → preview started. On second launch, persisted `state = preview` made the condition false → days weren't recalculated. Banner showed "0 days left."

**Mitigation:** Check for absence of server data (`_jwt == null`) rather than cached state. Persist computed values in `_saveState()`. Don't rely on re-computation alone.

## Accumulation in Loops

**Problem:** Loop used `routine.completionLog` (always empty original) instead of accumulating. Each `storage.updateRoutine()` overwrote the previous with only ONE completion. Streaks showed 0.

**Mitigation:** Always verify mutable state is tracked across iterations:
```dart
var current = routine;
for (...) {
  current = current.copyWith(completionLog: [...current.completionLog, ...]);
  await storage.updateRoutine(current);
}
```

## Misleading Error Messages

**Problem:** Local preview token sent to server endpoint → 401 → "API key is invalid or expired." Actual problem: server not deployed.

**Mitigation:** Map error conditions to specific causes. Detect `trial_token == 'preview_local'` and surface a clear message.
