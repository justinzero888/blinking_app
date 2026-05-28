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

### 12. Manual Testing: Always Get Clarification — Never Assume

When the user reports a visual issue (yellow lines, wrong ratio, stuck screen), **do not guess what they see**. Ask clarifying questions before writing any code:

```
// ❌ DON'T — 7+ iterations wasted guessing "yellow lines"
"I think it's the backdrop color. Let me change it."
"I think it's the gradient. Let me change it."
"I think it's the font. Let me change it."

// ✅ DO — root cause found in 1 round
"Are the yellow lines under ALL text (body, tags, dates, footer)?"
→ "Yes, every piece of text has an underline."
→ Root cause: inherited TextDecoration.underline from Overlay theme.
→ Fix: add `decoration: TextDecoration.none` to all TextStyle.
```

**Rule**: For visual/manual testing feedback, ask the user to describe:
1. Which elements are affected (body text only? tags? dates? footer?)
2. What exactly it looks like (underline? backdrop? gradient band?)
3. Does it appear on all templates or specific ones?

**Never** iterate on a visual fix without clarifying what the user actually sees on screen.

### 13. Off-Screen Rendering: OverlayEntry Is NOT Cross-Platform Reliable

Card rendering (1080×1440 PNG capture) has three attempted pipelines. Only one is stable:

| Pipeline | Status | Why |
|----------|--------|-----|
| `OverlayEntry` + `captureFromKey` | ✅ Works | Insert widget into app's overlay, capture. Position widget at `left: -2000` so it's never visible to the user even if `remove()` fails. |
| `renderToFile` → `_renderOffscreen` | ❌ Device-only failure | Manual `PipelineOwner` + `BuildOwner` + `element.mount(null, null)` only works under `TestWidgetsFlutterBinding`, not production `WidgetsFlutterBinding`. |
| `DecorationImage(MemoryImage)` | ❌ Android failure | Image decode is async; `RepaintBoundary.toImage()` captures before decode completes. |

**Rule**: Always use `OverlayEntry` with `Positioned(left: -2000, top: 0)` wrapper + `try/finally` with `addPostFrameCallback` for removal. Never attempt manual pipeline creation for production rendering.

**Cross-platform background images**: Pre-decode asset bytes via `rootBundle.load()` + `decodeImageFromList()` → pass `dart:ui Image` as `RawImage(image:)`. This avoids all async decode timing issues.

**Always `flutter clean` before switching build targets** (simulator ↔ device). Building for device then simulator without cleaning produces "incompatible platform" dyld errors.

### 14. Production vs Development Assets — Keep Raw Files Out of the Bundle

When generating optimized assets (e.g., converting PNG to JPG for size), move the raw source files to a separate directory OUTSIDE the `assets/` tree. Flutter bundles EVERY file in declared asset directories — including raw intermediate files.

```
// ❌ DON'T — both PNG and JPG bundled, 22MB wasted
assets/cards/bg_ink_rhythm.png  (2.2MB raw)
assets/cards/bg_ink_rhythm.jpg  (0.9MB optimized)

// ✅ DO — only JPGs in assets, raw PNGs in dev/
assets/cards/bg_ink_rhythm.jpg  (0.9MB optimized)
dev/cards-raw/bg_ink_rhythm.png (2.2MB raw, not bundled)
```

**Result:** AAB went from 85MB → 66MB, IPA from 62MB → 46MB just by removing raw PNGs from the asset bundle.

### 15. Every Build Must Increment the Version Number

**Any** change that produces a new binary requires a new build number. This includes bug fixes, asset changes, removing files, or rebuilding for a different target.

```
// ❌ DON'T — same build number, different binary
Fix bug → rebuild IPA/AAB → same version 1.2.0+42
→ App Store rejects: "build 42 already exists"
→ Google Play rejects: "versionCode 42 already used"

// ✅ DO — increment every time
Fix bug → bump to 1.2.0+43 → rebuild IPA/AAB
→ Clean submission
```

**Rule:** If `flutter build ipa` or `flutter build appbundle` runs, the build number MUST be higher than any previously submitted build. No exceptions — Apple and Google both enforce this.

### TODO: True Kaishu Font

Currently using **MaShanZheng** (马山政体, xingshu/行书) mapped to `fontFamily: 'serif'` for all calligraphic templates. To upgrade to true kaishu/楷体:

1. Download **LXGW WenKai** (霞鹜文楷) from https://github.com/lxgw/LxgwWenKai — free under SIL OFL
2. Place `.ttf` in `assets/fonts/`
3. Register in `pubspec.yaml` fonts section
4. Add new `'kaishu'` case to `_resolveFontFamily()` in `card_render_service.dart`
5. Set `fontFamily: 'kaishu'` on templates that need kaishu (e.g., 青花, 素笺)
6. Keep `'serif'` → MaShanZheng for xingshu-style templates (墨韵, 竹影, etc.)

## Reference Files

- **Development anti-patterns**: See [references/development.md](references/development.md) — detailed examples of cascading edits, async bugs, renames that missed files, stale seed data, notifications cancelled silently
- **IAP/Store configuration**: See [references/iap.md](references/iap.md) — RevenueCat setup order, App Store Connect bugs, Google Play IAP quirks, credential management
