# Infrastructure Upgrade & iOS Release Plan
**Created:** 2026-04-28
**Status:** DRAFT — pending Flutter stable release and Xcode 26 testing
**Trigger:** Xcode 26 mandatory for App Store (effective 2026-04-28); Flutter 3.41.2 has deprecated iOS API issues requiring Flutter upgrade before iOS build is viable

---

## Background

Apple shifted to year-based versioning with iOS/Xcode 26. As of April 28, 2026, App Store Connect requires apps to be built with Xcode 26 + iOS 26 SDK. Our current toolchain (Xcode 16.2, Flutter 3.41.2 stable, Feb 18 build) predates Xcode 26 and uses deprecated iOS APIs that Flutter itself has not yet patched in the stable channel. The iOS build is therefore blocked on two upstream dependencies:

1. A Flutter stable release that patches the Xcode 26 deprecated API issues
2. Xcode 26.4.1 installation (available since April 16, 2026)

Android is unaffected and proceeds on its own track.

---

## Goals

- Ship Android v1.1.0-beta.3+18 to Google Play Production
- Upgrade Flutter to a version compatible with Xcode 26 / iOS 26 SDK
- Build and ship the iOS app to the App Store at feature parity with Android
- Leave the codebase in a clean, stable state for both platforms going forward

---

## Phases

### Phase 1 — Android Release
**Status:** Ready to execute
**Depends on:** Nothing — AAB already built and tested (56/56 tests passing)

| Step | Action | Notes |
|------|--------|-------|
| 1.1 | Upload `app-release.aab` to Google Play Console | Internal Testing track |
| 1.2 | Smoke test on physical Android device | Golden paths: add entry, card, locale switch, export |
| 1.3 | Promote to Closed Testing (beta) | Soak for a few days |
| 1.4 | Promote to Production | Once stable |

**Gate:** Production rollout confirmed stable before proceeding to Phase 2.
**Do not modify Flutter channel or iOS toolchain during this phase.**

---

### Phase 2 — Flutter Upgrade
**Status:** Waiting — blocked on Flutter stable shipping Xcode 26 deprecated API fix
**Depends on:** Phase 1 complete; Flutter stable release with Xcode 26 support

#### What we are waiting for
Flutter 3.41.2 (Feb 18, 2026) predates Xcode 26. The deprecated iOS API fixes will ship in the next Flutter stable release (~quarterly cadence, expected ~May 2026). Monitor:
- Flutter blog / GitHub releases for a stable tag > 3.41.2 that lists Xcode 26 / iOS 26 support
- Fallback: switch to Flutter beta channel if stable hasn't shipped by the time Phase 1 completes

#### Steps (once Flutter version available)
| Step | Action | Command |
|------|--------|---------|
| 2.1 | Upgrade Flutter stable | `flutter channel stable && flutter upgrade` |
| 2.2 | Confirm version > 3.41.2 | `flutter --version` |
| 2.3 | Run full regression tests | `flutter test` — must be 56/56 |
| 2.4 | Static analysis | `flutter analyze --no-pub` — must be 0 errors |
| 2.5 | Rebuild Android AAB | `flutter build appbundle --release` |
| 2.6 | Verify AAB size is comparable | Expect ~47-65 MB |
| 2.7 | Resolve any plugin breakage | Update pubspec if image_picker / permission_handler / share_plus / sqflite versions need bumping |
| 2.8 | Commit lock files and fixes | `pubspec.lock`, `Podfile.lock`, any dep updates |

**Gate:** `flutter test` 56/56, `flutter build appbundle --release` clean, Android smoke test passes.

#### Fallback — beta channel
If Flutter stable has not shipped by the time Phase 1 completes:
```bash
flutter channel beta && flutter upgrade
```
Beta ships monthly. Accept the risk of minor API churn; pin the exact version in CLAUDE.md.

---

### Phase 3 — iOS Toolchain Setup
**Status:** Ready to execute once Phase 2 complete
**Depends on:** Phase 2 complete (upgraded Flutter)

| Step | Action | Notes |
|------|--------|-------|
| 3.1 | Install Xcode 26.4.1 | Mac App Store or developer.apple.com |
| 3.2 | Accept Xcode license | `sudo xcodebuild -license accept` |
| 3.3 | Verify Flutter recognizes Xcode 26 | `flutter doctor -v` → `[✓] Xcode 26.x` |
| 3.4 | Update CocoaPods repo | `cd ios && pod repo update` |
| 3.5 | Reinstall pods | `pod install` |
| 3.6 | First simulator build (no signing) | `flutter build ios --simulator --no-codesign` |
| 3.7 | Launch on iOS 26 simulator | `flutter emulators --launch apple_ios_simulator && flutter run` |

**Gate:** App launches on iOS 26 simulator with no crash on startup.

---

### Phase 4 — iOS 26 SDK Compliance
**Status:** Not started
**Depends on:** Phase 3 complete

Areas to audit and fix:

| Area | Risk | What to check |
|------|------|---------------|
| Deployment target | Medium | Raise `platform :ios` in Podfile and Xcode project if Apple raised minimum above 13.0 |
| Privacy manifests | Medium | iOS 26 may require `PrivacyInfo.xcprivacy` for file timestamps, UserDefaults, disk space APIs |
| Image picker | Medium | Test camera + gallery on simulator; PHPhotoLibrary behavior may have changed |
| Share sheet | Low | `share_plus` uses `UIActivityViewController` — verify unchanged |
| SQLite / sqflite_darwin | Low | Pure C library, expect no issues |
| Locale switching | Low | Walk Chinese ↔ English on simulator — validated on Android in v1.1.0-beta.3 |
| UI regressions | Medium | iOS 26 may introduce new design language; check card renderer, emoji jar, bottom sheets, modals |
| DK* pod xcassets workaround | Low | Podfile already strips DKPhotoGallery xcassets — verify still effective under Xcode 26 |

**Gate:** Full golden-path walkthrough on iOS 26 simulator with no crashes or visual regressions; `flutter analyze --no-pub` 0 errors; `flutter test` 56/56.

---

### Phase 5 — App Store Connect Setup & Submission
**Status:** Not started
**Depends on:** Phase 4 complete; Apple Developer Program membership active

| Step | Action | Notes |
|------|--------|-------|
| 5.1 | Confirm Apple Developer Program membership | $99/yr — allow 24-48h if enrolling fresh |
| 5.2 | Register App ID | `com.blinking.blinking` in Apple Developer portal |
| 5.3 | Create Distribution Certificate | In Xcode → Settings → Accounts or developer.apple.com |
| 5.4 | Create App Store provisioning profile | Linked to App ID and certificate |
| 5.5 | Configure Xcode signing | Automatically manage signing → select team in Runner target |
| 5.6 | Build IPA | `flutter build ipa --release` |
| 5.7 | Upload via Xcode Organizer | Open `build/ios/archive/Runner.xcarchive` |
| 5.8 | Create app record in App Store Connect | Name, subtitle, bundle ID, primary language |
| 5.9 | Prepare metadata | Description (EN + ZH), keywords, support URL, privacy policy URL |
| 5.10 | Upload screenshots | Required: iPhone 6.9" (1320×2868) and 5.5" (1242×2208); optional: iPad 13" |
| 5.11 | Set age rating | Expected: 4+ (no objectionable content) |
| 5.12 | Submit for App Review | Typical review time: 24-48h |

**Gate:** App approved and live on App Store.

---

## Open Questions
*(To be resolved as information arrives)*

| # | Question | Impact |
|---|----------|--------|
| Q1 | Which Flutter stable version patches the Xcode 26 deprecated APIs? | Determines Phase 2 start date |
| Q2 | Does Flutter beta currently build cleanly against Xcode 26.4.1? | Fallback timing for Phase 2 |
| Q3 | Did iOS 26 raise the minimum deployment target above 13.0? | Phase 4 scope — may require Info.plist / Podfile changes |
| Q4 | Does iOS 26 require a `PrivacyInfo.xcprivacy` privacy manifest for our API usage? | Phase 4 — potential App Review rejection risk if missing |
| Q5 | Are Apple Developer Program certificates already active? | Phase 5 timing — 24-48h delay if enrollment needed |
| Q6 | Does the Chorus backend API have iOS-specific requirements? | Feature parity — PostToChorusSheet needs iOS smoke test |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Flutter stable doesn't ship Xcode 26 fix before Android production | Medium | Delays iOS start | Switch to Flutter beta channel |
| Plugin breakage after Flutter upgrade | Medium | Delays Phase 2 | Patch pubspec versions; check pub.dev for iOS 26-compatible releases |
| iOS 26 introduces breaking UI changes to core widgets | Low | Phase 4 rework | Test early on simulator; Flutter engine team typically patches quickly |
| Privacy manifest rejection by App Review | Medium | Phase 5 delay | Audit during Phase 4; add `PrivacyInfo.xcprivacy` proactively |
| Android regression after Flutter upgrade | Low | Critical — would block production | Full regression suite + physical device test before promoting AAB |

---

## Dependencies & Sequencing

```
Phase 1 (Android Release)
    ↓ complete
Phase 2 (Flutter Upgrade)  ← also waits for Flutter stable release
    ↓ complete
Phase 3 (iOS Toolchain)
    ↓ complete
Phase 4 (iOS 26 SDK Compliance)
    ↓ complete
Phase 5 (App Store Submission)
```

Phases 1 and 2 have a shared gate — Phase 2 should not start until Phase 1 has reached Production, to avoid any risk of a Flutter upgrade destabilizing the Android release in flight.

---

## Revision Log

| Date | Author | Change |
|------|--------|--------|
| 2026-04-28 | Justin / Claude | Initial draft |
