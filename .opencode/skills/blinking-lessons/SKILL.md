---
name: blinking-lessons
description: >
  Anti-patterns, mistakes, and mandatory workflows for the Blinking Notes Flutter app.
  Use when working on this codebase to avoid repeating known failures. Covers:
  hardcoded IDs, SharedPreferences misuse, cascading edit failures, seed data consistency,
  async ordering bugs, build order, IAP/store configuration, locale logic, state machine
  edge cases, and deployment verification. Always load before making code changes.
---

# Blinking Lessons

Mandatory checks and workflows when working on the Blinking Notes Flutter app. These rules exist because each was learned the hard way.

## Daily Checklist (Run Before Starting)

```
flutter analyze --no-pub    # must be 0 errors
flutter test                # must all pass
```

## Development Workflow

```
Issue Reported
    │
    ├── 1. Root Cause Analysis — understand WHY before touching code
    ├── 2. Propose Solution — 1-2 options with impact assessment
    ├── 3. Evaluate — pick simplest fix; one bug, one fix
    ├── 4. Review Tests — update existing tests BEFORE coding
    ├── 5. Implement — minimal change
    │       flutter analyze → verify 0 errors
    │       flutter test → verify all pass
    ├── 6. Push to Sims — build for all 3 simulators, install fresh
    ├── 7. UAT on Sims — execute test cases on iPhone, iPad, Android
    └── 8. Build Production — only after UAT passes on all 3
```

## Critical Rules

### 1. One Edit = One `flutter analyze`

After EVERY edit, run `flutter analyze`. Never apply the next edit until zero errors. One broken edit cascades into 5 more broken edits trying to "fix" the previous.

### 2. Never Hardcode IDs in Logic

Every ID referenced in business logic must be a named constant defined in the model that owns it. Single source of truth for renames.

```dart
// ❌ DON'T
if (activeId == 'lens_builtin_zengzi') { ... }

// ✅ DO
static const kDefaultLensId = 'lens_style_kael';
if (activeId == DefaultLensSets.defaultActiveSetId) { ... }
```

### 3. SharedPreferences Is for Settings Only

No data > 1KB. No images. Images → `ApplicationDocumentsDirectory` with path stored in prefs. Large data → SQLite.

### 4. Seed Data: One Canonical Source

Every pre-built dataset must have ONE source. If `DefaultRoutines` exists, `StorageService` must import from it — not duplicate. Check both `StorageService._getDefault*()` and `Default*.defaults` when changing seed data.

### 5. Build Order: Clean Before Building

```bash
# ✅ Correct order
flutter clean && flutter build ipa && flutter build appbundle

# ❌ Never chain clean between builds
flutter build appbundle && flutter clean && flutter build ipa  # AAB gets deleted
```

### 6. Simulator ≠ Real Device

Simulators are for UI layout and basic flow. Functional testing (notifications, IAP, backup, icons) requires real devices. Document simulator-specific limitations.

### 7. Locale Logic: Audit Per-Field

For every user-facing field, verify both locales. One `isZh ? zhValue : enValue` swap per field breaks UX. Create a test that validates both.

### 8. Commit After Each Feature

Commit after each completed feature, not at end of day. This enables safe `git checkout` as checkpoint during heavy editing sessions.

### 9. Deployment Not Refreshing? Nuclear Clean

```bash
rm -rf build/ .dart_tool/
flutter clean && flutter pub get
xcrun simctl uninstall <device> com.blinking.blinking
flutter run
```

Add a visible text change (e.g. app bar title) to immediately confirm the right code is running.

### 10. Seed Data in `main.dart`, Never in Shared Providers

Production-only initialization (seed data) belongs in `main.dart` before `runApp()`. Seeds in shared providers leak into test environments.

### 11. State Machine: Persist ALL Computed State

Don't rely on re-computation alone. Persist computed values (e.g. `_previewDaysRemaining`) in `_saveState()` and check for stale cached state on init.

## Reference Files

- **Development anti-patterns**: See [references/development.md](references/development.md) — detailed examples of cascading edits, async bugs, renames that missed files, stale seed data, notifications cancelled silently
- **IAP/Store configuration**: See [references/iap.md](references/iap.md) — RevenueCat setup order, App Store Connect bugs, Google Play IAP quirks, credential management
