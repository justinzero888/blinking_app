# Session Summary — May 14 Late (Notification Fix & Final Build)

**Version:** 1.1.0+37 | **Tests:** 164/164 | **Lint:** 0 errors

---

## Final Changes

### Notifications — Working
- Root cause: `matchDateTimeComponents` silently fails on iOS; `cancelAll()` race condition killed schedules
- Fix: one-shot scheduling + `rescheduleAll()` on app launch for daily repeat
- Timezone: EDT → America/New_York mapping added
- AppDelegate: simplified to clean state (removed custom `willPresent`)
- Behavior: fires in background, suppresses in foreground (standard iOS)
- Tested and confirmed working on iOS simulator

### Private Tag AI Filter — All 5 Entry Points
- `JarProvider.getDayEmotions()` — excludes `tag_private` emotions
- `ReflectionSessionScreen` — filters entries before AI context
- `emoji_jar.dart` (Ask AI) — filters entries
- `cherished_memory_screen.dart` (Annual Reflection) — filters entries
- `AssistantScreen` — already had filter

### Daily AI Counter Fix
- Counter now increments only on successful API response (not timeout)

### Version
- Bumped to 1.1.0+37, production AAB + IPA rebuilt, committed to GitHub

---

## Builds
| Platform | Path |
|----------|------|
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` |
| iOS IPA | `build/ios/ipa/blinking.ipa` |
