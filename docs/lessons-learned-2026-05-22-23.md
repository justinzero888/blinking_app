# Lessons Learned — May 22–23, 2026

---

## 1. Flutter Build: `--no-codesign` vs `--simulator`

**What happened:** `flutter build ios --debug --no-codesign` produced an `arm64` device binary in `build/ios/iphoneos/Runner.app`. Installing this on a simulator caused silent failure — tapping the app icon did nothing. No error message, no crash log.

**Root cause:** `--no-codesign` forces a physical device build. The binary slice is incompatible with the simulator runtime (which needs `x86_64` + `arm64` simulator slices).

**Fix:** Always use `flutter build ios --debug --simulator` for simulators. Output goes to `build/ios/iphonesimulator/Runner.app`. Verify with `lipo -info` — should show `x86_64 arm64`.

**Prevention:** Added to `simulator-launch-playbook.md`. Never use `--no-codesign` in any simulator workflow.

---

## 2. `flutter_local_notifications` v21 Removed `onDidReceiveLocalNotification`

**What happened:** Design assumed `flutter_local_notifications` had a foreground notification callback for TTS. The callback `onDidReceiveLocalNotification` was removed in v10+ in favor of `DarwinNotificationDetails.presentAlert` for visual banners only — no Dart callback for foreground delivery exists in v21.

**Root cause:** API deprecation in a dependency, not checked before design.

**Fix:** Switched to `Timer.periodic(30s)` in `RoutineProvider._startForegroundCheck()`. Acceptable trade-off: 0-30s latency for TTS after reminder time arrives. Deduplication via `Set<String>` prevents repeat speaking.

**Prevention:** Check dependency APIs against design assumptions before implementation. Run `grep` on the installed package version's source, not pub.dev docs (which may show older versions).

---

## 3. Android Emulator TTS is Fundamentally Broken

**What happened:** Google TTS engine crashed on Android emulator (API 36.1 with Google Play). Native library `libgoogle_speech_sbg_tts_jni.so` crashed on emulated ARM hardware. Dart-side `flutter_tts.speak()` returned success — the crash happened in the native process, not our app.

**Root cause:** Emulator lacks hardware features required by Google's TTS native libraries. Not fixable in app code.

**Fix:** Documented as known limitation. Test TTS on iPhone simulator (works natively) or real Android device. Added "Test Voice" debug button in Settings to verify TTS engine availability.

**Prevention:** Add TTS platform capability check at startup: `flutter_tts.isLanguageAvailable('en-US')` before enabling voice features. If unavailable, hide the global toggle entirely.

---

## 4. Model Field Addition Requires Full Write Chain

**What happened:** Adding `voiceEnabled` to the `Routine` model, `fromJson`, and `copyWith` was insufficient. The field was never written to or read from SQLite. Routine dialog toggle appeared to work (used in-memory state), but the value was lost on app restart.

**Root cause:** Assumed `fromJson`/`copyWith` were the only integration points. In reality, `StorageService.getRoutines()` manually maps SQLite columns to a `routineMap` before calling `fromJson`, and `addRoutine()` manually builds the insert map. Both needed explicit `voice_enabled` handling. Additionally, DB migration v14 was needed.

**Fix:** Updated 7 layers:
1. `Routine.voiceEnabled` (model field + `fromJson` + `toJson` + `copyWith`)
2. `database_service.dart` `_onCreate` (schema column)
3. `database_service.dart` `_onUpgrade` (v14 migration)
4. `storage_service.dart` `addRoutine()` (insert)
5. `storage_service.dart` `getRoutines()` (query mapping)
6. `routine_provider.dart` `addRoutine()` (pass-through)
7. `routine_repository.dart` `create()` (pass-through)

**Prevention:** When adding a model field, use this checklist:
```
[ ] Model: field + constructor + fromJson + toJson + copyWith
[ ] DB: _onCreate schema
[ ] DB: _onUpgrade migration
[ ] Storage: INSERT in add/update methods
[ ] Storage: SELECT mapping in get/list methods
[ ] Repository: pass-through if it maps to model constructor
[ ] Provider: pass-through if it calls repository
[ ] Test: kSchemaVersion in db_version_test.dart
```

---

## 5. iPad UIActivityViewController Popover is Untestable by Automation

**What happened:** Maestro could not interact with share sheet flows on iPad. All 5 share flows failed with "UIPopover (permanent)". On iPad, iOS requires `UIActivityViewController` to render as a popover (per Apple HIG), which lives in a separate UIKit window. Accessibility automation tools cannot traverse system popover windows.

**Root cause:** UIKit restriction, not a Flutter bug. Even with `sharePositionOrigin` fix, the popover is controlled by iOS, not the app.

**Workaround for automation:** Use coordinate-based taps to dismiss the popover. `tapOn: "Share"` triggers the popover, then `tapOn: point: "50%,90%"` taps outside it to dismiss. Skip validation of share sheet content.

**Prevention:** Document which UI flows are automation-untestable on iPad. Require manual human UAT for share sheet on real iPad.

---

## 6. `json.fuse(utf8).decode()` Optimization Pattern

**What happened:** `restoreFromBackup()` parsed `data.json` with two steps: `utf8.decode(bytes)` → `json.decode(string)`. Each step created a copy in RAM. For large backups (>100MB data.json), this caused ~4x memory overhead (raw bytes + string + parsed objects).

**Fix:** `json.fuse(utf8).decode(bytes)` fuses UTF-8 decode + JSON parse into a single step, avoiding the intermediate String allocation. Reduces peak RAM from ~4x to ~1.5x data.json size. Added `archive.removeFile()` after import to immediately free decompressed bytes.

**Pattern:** Anywhere you do `json.decode(utf8.decode(bytes))`, replace with `json.fuse(utf8).decode(bytes)`. Saved ~62% peak RAM in restore flow.

---

## 7. Zsh `status` is Read-Only — Variable Name Matters

**What happened:** Boot polling script used `status=$(adb shell getprop sys.boot_completed)` which failed silently because `status` is a zsh read-only builtin. The variable assignment was ignored, but no error was shown. The loop condition always evaluated to false, making the boot poll timeout.

**Root cause:** Zsh reserved word collision. `status` stores the exit status of the last command — it's read-only in zsh (unlike bash where it's writable).

**Fix:** Renamed variable to `boot_ok`. Updated `simulator-launch-playbook.md`.

**Prevention:** Avoid single-word variable names in zsh scripts: `status`, `path`, `argv`, `fignore`. Use descriptive multi-word names: `boot_ok`, `emu_status`, `sim_path`.

---

## 8. Maestro Feedback ≠ All Needs New Build

**What happened:** Received Maestro feedback listing 3 "code fixes needed" and 4 "YAML fixes." Time was spent investigating the code fixes, only to discover all 3 were already in the codebase from a prior session.

**Root cause:** Maestro agent runs against the installed build, not the latest code. If the build is stale (even if code is updated), the test report reflects the installed version's state.

**Prevention:** Before investigating Maestro-reported "code fixes," run `git log` to check if the fix is already committed. Check the build timestamp against the most recent session's commits. Treat "needs new build" feedback as "verify in code first."

---

## 9. Every Feature Needs Tests — Not Just Design Doc Promises

**What happened:** T-6 (voice notification) was designed with 8 unit tests and 4 widget tests in the design document. Only UAT cases were created. When asked to confirm the test count, the gap was discovered: zero automated tests existed for the voice notification feature. All 3 new test files had to be written retroactively.

**Root cause:** Tests were documented but not implemented. The design doc served as a checklist, but the checklist wasn't executed. The test pass count was used as the truth, but new features added no new assertions to validate them.

**Fix:** Added 26 tests across 3 files: 7 model (voiceEnabled lifecycle), 5 service (init/speak/stop/language), 4 DB persistence (SQLite round-trip). Total: 458 to 484.

**Prevention:** After every feature or bug fix, verify:
- Test file exists with documented cases
- Test count increased (not just maintained)
- Analyze returns 0 errors

A feature is not "done" until automated tests exist. UAT is for human verification of UX, not a substitute for regression protection.
