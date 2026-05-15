# Lessons Learned — Blinking May 12–15, 2026

## 1. Never Use Hardcoded Static IDs in Business Logic

**What happened:** `lens_builtin_zengzi`, `tag_reflection`, `tag_secrets` were hardcoded in 10+ files. When we renamed/replaced these values, grep-and-replace missed references, created duplicates, and broke persona-specific lenses for 2 days.

**Pattern to avoid:**
```dart
// ❌ DON'T
if (activeId == 'lens_builtin_zengzi') { ... }
if (e.tagIds.contains('tag_reflection')) { ... }
```

**Pattern to use:**
```dart
// ✅ DO
static const defaultLensId = 'lens_style_kael';
if (activeId == DefaultLensSets.defaultActiveSetId) { ... }
if (e.tagIds.contains(kSynthesisTagId)) { ... }
```

**Rule:** Every ID referenced in logic must be a named constant in the model that defines it. Single source of truth for renames.

---

## 2. Large Data Has No Place in SharedPreferences

**What happened:** Base64-encoded 256x256 images (24–34KB) exceeded iOS `NSUserDefaults` 4KB practical limit. Multi-custom styles saved only the last one. Took hours to diagnose.

**Rule:** SharedPreferences is for settings, not files. If data > 1KB, use SQLite or the file system. Images belong in `ApplicationDocumentsDirectory` with a path stored in prefs.

---

## 3. One Edit Tool Call = One Change

**What happened:** Multiple edits to `settings_screen.dart` (14+ in one session) caused bracket imbalances, orphaned duplicate code blocks (`_showCustomStyleDialog` had 200 lines of ghost code after a `}`), and corrupted `_saveCustomStyle` parentheses. Required 5+ debug rounds.

**Rule:** After every edit, run `flutter analyze`. Before the next edit, verify zero errors. One broken edit cascades into 5 more broken edits that each try to "fix" the previous.

---

## 4. Seed Data Must Be Consistent Across All Sources

**What happened:** `DefaultRoutines.defaults` (3 old routines) was stale while `StorageService._getDefaultRoutines()` (31 new routines) was correct. `DefaultTags.defaults` (8 old tags) was stale while `StorageService._getDefaultTags()` (6+3 new tags) was correct. If anyone called `TagRepository.resetToDefaults()`, old data would overwrite new.

**Rule:** Every pre-built dataset must have ONE canonical source. If a class like `DefaultRoutines` exists, it must be the single source, and `StorageService` must import from it — not duplicate it.

---

## 5. Async Method Ordering Causes Silent Failures

**What happened:** `rescheduleAll()` called `cancelAll()` which ran AFTER `scheduleRoutine()` due to `loadRoutines()` being async in a `create:` callback. Notifications were scheduled, then immediately cancelled.

**Rule:** Never put `cancelAll()` inside a method that might run after user actions. Cancel specific IDs, not everything. Chain async calls explicitly — don't rely on execution order when methods are called from different lifecycle hooks.

---

## 6. Build Order Matters — Clean Wipes Everything

**What happened:** `flutter build appbundle && flutter clean && flutter build ipa` — the AAB was built, then deleted by `clean` before the IPA build ran.

**Rule:** Build in dependency order: `clean → build ipa → build appbundle`. Or build separately, never chain clean between builds.

---

## 7. Simulator ≠ Real Device

**What happened:** Notifications worked on iOS sim once, never on Android emulator. iPad sim froze on backup due to memory constraints that real iPads don't have. Android emulator cached old app icons after 5 reinstalls.

**Rule:** Simulators are for UI layout and basic flow. Functional testing (notifications, IAP, backup, icons) requires real devices. Document simulator-specific limitations in the test plan.

---

## 8. Locale Logic Must Be Audited Per-Field

**What happened:** Description display was reversed — `isZh ? descriptionEn : description` showed English in Chinese mode and vice versa. The Edit dialog loaded `name` (always Chinese) instead of `displayName(isZh)`. Each field was broken independently.

**Rule:** For every user-facing field, create a test that verifies both locales. One `isZh ? zhValue : enValue` mistake per field is enough to break the UX.

---

## 9. Refactoring Checklist: Default Persona Edition

When changing defaults (like persona from Elara → Kael):

| File | What to check |
|------|---------------|
| Model constants | `defaultStyleId`, `defaultActiveSetId` |
| Provider defaults | `AiPersonaProvider._load()` initial values |
| Documentation | CLAUDE.md, TODO, session summaries |
| Seed data | `_getDefaultRoutines()`, `_getDefaultTags()` |
| Lens defaults | `DefaultLensSets.defaults()`, `defaultActiveSetId` |
| Global search | Search every file for the old default string |

---

## 10. API Version Changes Need Immediate Attention

**What happened:** `flutter_local_notifications` v21 changed `initialize()`, `zonedSchedule()`, `show()`, `cancel()` from positional to named parameters. This was caught at compile time but required rewriting the entire NotificationService. Earlier versions used different method signatures.

**Rule:** After `flutter pub add`, immediately `flutter analyze` and fix all new compilation errors. Don't defer API migration.

---

## Daily Checklist for Future Sessions

1. ✅ `flutter analyze` — 0 errors before starting
2. ✅ `flutter test` — all pass before starting
3. ✅ One edit → `flutter analyze` → verify → next edit
4. ✅ Check all 3 sims after each significant change
5. ✅ Never `clean` between build commands
6. ✅ Pre-built IDs: use constants, not strings
7. ✅ Seed data: one source of truth in model classes
8. ✅ SharedPreferences: no data > 1KB, no images
9. ✅ Commit after each completed feature (not at end of day)
10. ✅ Update CLAUDE.md when any default changes
