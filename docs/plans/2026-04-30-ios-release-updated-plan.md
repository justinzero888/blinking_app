# iOS Release — Updated Pipeline Plan
**Created:** 2026-04-30 (replaces 2026-04-28 draft)
**Status:** Immediate execute — Flutter dependency unblocked
**Flutter:** 3.41.8 stable (Apr 24, 2026) ← includes Xcode 26 deprecated API fix (3.41.4: simulator arm + 3.41.7: physical device debug)
**macOS:** 26.2 (Tahoe beta)
**Xcode:** 16.2 (must upgrade to 26.4.1 — macOS 26 native)

---

## Background

Apple's year-based versioning with Xcode 26 is now mandatory for App Store Connect. The previous plan (2026-04-28) was blocked on "Flutter stable > 3.41.2 with Xcode 26 support." That is no longer the case — Flutter 3.41.8 (released Apr 24) was installed today via `flutter upgrade` on stable channel. All 94 tests pass, `flutter analyze --no-pub` reports 0 errors.

The pipeline is restructured for **parallel tracks** — Android production (PROP-3) and iOS release can proceed independently.

---

## Quick Reference: Current State

| Component | Version | Status |
|-----------|---------|--------|
| Flutter | 3.41.8 (stable) | ✅ Upgraded |
| Dart | 3.11.5 | ✅ Ships with Flutter |
| Tests | 94/94 passing | ✅ Verified |
| Lint | 0 errors | ✅ Verified |
| DB schema | v11 | ✅ Current |
| App version | 1.1.0-beta.4+19 | ✅ Current |
| Xcode | 16.2 | ❌ Must upgrade to 26.4.1 |
| macOS | 26.2 (Tahoe beta) | ✅ Running |

---

## Pipeline Overview

```
Track A: Android (PROP-3)         Track B: iOS (new)
─────────────────────────────     ─────────────────────────────
A1. Monitor beta soak             B1. Install Xcode 26.4.1
A2. Promote to Production (10%)   B2. Fix Podfile platform
A3. Ramp to 100% rollout          B3. Install CocoaPods
                                  B4. Simulator smoke test
                                  B5. iOS 26 SDK compliance audit
                                  B6. Apple Developer setup
                                  B7. Build IPA & archive
                                  B8. Submit to App Store
```

Tracks are independent. Neither blocks the other.

---

## Track B — iOS Release

### B1 — Install Xcode 26.4.1

**Status:** Pending human action

| Step | Action | Command |
|------|--------|---------|
| B1.1 | Download Xcode 26.4.1.xip | [developer.apple.com/download/applications](https://developer.apple.com/download/applications) (~7 GB) |
| B1.2 | Extract the XIP | `xip --expand Xcode_26.4.1.xip` (5-10 min) |
| B1.3 | Install (or rename existing) | `mv /Applications/Xcode.app /Applications/Xcode-16.2.bak && mv ~/Downloads/Xcode.app /Applications/Xcode.app` |
| B1.4 | Accept license | `sudo xcodebuild -license accept` |
| B1.5 | Verify Flutter recognizes it | `flutter doctor -v` → `[✓] Xcode 26.x` |
| B1.6 | Install iOS 26 simulator runtime | `xcrun simctl list runtimes` then `xcrun simctl runtime add "iOS 26.0 Simulator Runtime"` if not present |

**If Xcode 26.4.1 is already in `/Applications/Xcode-26.app`** (side-by-side):
```bash
sudo xcode-select -s /Applications/Xcode-26.app
```

**Notes:**
- Xcode 26 is the first year-based version (not Xcode 17). macOS 26 Tahoe requires Xcode 26 — the current Xcode 16.2 will have simulator/device issues confirmed in CLAUDE.md's "BLOCKED" entry.
- ICloud download can be interrupted. Use `aria2c` or a download manager for reliability on ~7 GB files.

---

### B2 — Fix Podfile Platform

**Status:** Ready (1-line fix)

**File:** `ios/Podfile`, line 2

**Current:**
```ruby
# platform :ios, '13.0'
```

**Fix:** Uncomment it:
```ruby
platform :ios, '13.0'
```

**Why:** Several plugins (`permission_handler`, `sqflite`, `image_picker` CocoaPods) read the Podfile platform to determine minimum deployment target. Without it, pods may default incorrectly, especially under Xcode 26's stricter build validation.

---

### B3 — Install CocoaPods & Dependencies

| Step | Action | Command |
|------|--------|---------|
| B3.1 | Update CocoaPods repo | `pod repo update` |
| B3.2 | Reinstall pods | `cd ios && pod install && cd ..` |
| B3.3 | Verify no Xcode 26-related pod warnings | Pod output should contain no errors |

**Expected:** `Pod installation complete!` with no red warnings.

---

### B4 — Simulator Smoke Test

| Step | Action | Command |
|------|--------|---------|
| B4.1 | List available iOS 26 simulators | `xcrun simctl list devices available \| grep -E "iPhone 1[6-7]"` |
| B4.2 | Boot one | `xcrun simctl boot "iPhone 16 Pro"` |
| B4.3 | Build for simulator (no signing) | `flutter build ios --simulator --no-codesign` |
| B4.4 | Launch on simulator | `flutter run -d "iPhone 16 Pro"` |

**Smoke test checklist (on simulator):**
- [ ] App launches without crash to Calendar tab
- [ ] Add entry with emotion + tag + image → saves correctly
- [ ] Moment tab → entry visible, search works
- [ ] Routine tab → all 3 sub-tabs load, toggle completion works
- [ ] Keepsakes tab → Jar / Cards / Summary all render
- [ ] Cards tab → create card, edit with quill, preview PNG
- [ ] Settings → all rows render, locale switch (EN↔ZH)
- [ ] Robot FAB → opens Assistant screen (no API key required for UI)
- [ ] Export ZIP → share sheet opens

**Gate:** All smoke tests pass on iOS 26 simulator.

---

### B5 — iOS 26 SDK Compliance Audit

#### Privacy Manifest (`ios/Runner/PrivacyInfo.xcprivacy`)

Already exists with declarations for:
- `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1)
- `NSPrivacyAccessedAPICategoryFileTimestamp` (C617.1)
- `NSPrivacyAccessedAPICategoryDiskSpace` (E174.1)
- `NSPrivacyCollectedDataTypes` = empty (we collect no data)
- `NSPrivacyTracking` = false

**Checklist:**
- [ ] Verify no new iOS 26 required API reason categories (check latest Apple docs before submission)
- [ ] Confirm `NSPrivacyCollectedDataTypes` remains accurate (no analytics SDKs added)

#### Deployment Target

- `IPHONEOS_DEPLOYMENT_TARGET = 13.0` in project.pbxproj ✅
- Podfile will be set to `platform :ios, '13.0'` after B2

**Check:** Verify iOS 26 hasn't raised minimum above 13.0 (low risk — Apple typically supports 2-3 previous major versions; iOS 26 would still support iOS 13)

#### Info.plist Keys

Present:
- `NSPhotoLibraryUsageDescription` ✅
- `NSCameraUsageDescription` ✅
- `NSPhotoLibraryAddUsageDescription` ✅
- `UIFileSharingEnabled` ✅
- `LSSupportsOpeningDocumentsInPlace` ✅

Missing (not needed unless `flutter_local_notifications` added):
- `NSUserNotificationsUsageDescription` — not in current dependency tree

#### Widget / UI Regressions

Areas that differ between Android and iOS:
- [ ] `CardRenderer` (PNG text rendering — test on iOS simulator)
- [ ] `EmojiJarWidget` (CustomPainter — verify positioning)
- [ ] Bottom sheets / modals (iOS 26 may have changed presentation)
- [ ] Share sheet (`share_plus` / `UIActivityViewController`)
- [ ] Image picker (camera + gallery access flows)
- [ ] Locale switching (walk EN↔ZH on simulator)

#### DK* Pod xcassets Workaround

The `post_install` script in Podfile strips DKPhotoGallery xcassets. Verify this still works under Xcode 26:
- [ ] No `AssetCatalogSimulatorAgent` errors in simulator logs

**Gate:** Full golden-path walkthrough, zero crashes, zero visual regressions.

---

### B6 — Apple Developer Setup

| Step | Action | Notes |
|------|--------|-------|
| B6.1 | Verify Apple Developer Program membership | [developer.apple.com](https://developer.apple.com) — $99/yr |
| B6.2 | Register App ID `com.blinking.blinking` | If not already done |
| B6.3 | Create Distribution Certificate | Via Xcode → Settings → Accounts → Manage Certificates |
| B6.4 | Create App Store provisioning profile | Auto-managed if using Automatic signing |
| B6.5 | Create app record in App Store Connect | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps |
| B6.6 | Confirm Team ID | 10-char string; set in Xcode target if Automatic signing is used |

**Known:** The Xcode project uses `Automatic` signing with no `DEVELOPMENT_TEAM` hardcoded. Xcode will derive the team from your Accounts preference. This is fine if a single team is in use.

---

### B7 — Build Release IPA

| Step | Action | Command |
|------|--------|---------|
| B7.1 | Clean build | `flutter clean && flutter pub get` |
| B7.2 | Build archive | `flutter build ipa --release` |
| B7.3 | Verify IPA exists | `ls -lh build/ios/ipa/*.ipa` (expected ~30-80 MB) |

**If signing errors occur:** Open `ios/Runner.xcworkspace` in Xcode 26 → Runner target → Signing & Capabilities → confirm team and automatic signing.

**Alternative (Xcode archive path):**
```bash
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → TestFlight & App Store
```

---

### B8 — App Store Submission

| Step | Action | Notes |
|------|--------|-------|
| B8.1 | Upload IPA | Via Xcode Organizer (Distribute App → Upload) or `xcrun altool --upload-app` |
| B8.2 | Wait for processing | 5-30 min in App Store Connect |
| B8.3 | Prepare metadata | Description (EN + ZH), keywords, support URL (`blinkingfeedback@gmail.com`), privacy policy URL |
| B8.4 | Upload screenshots | iPhone 6.9" (1320×2868) + 5.5" (1242×2208); generate on iOS 26 simulator |
| B8.5 | Set age rating | Expected: 4+ (no objectionable content) |
| B8.6 | Set pricing | Free |
| B8.7 | Submit for App Review | Typical 24-48h |

**Metadata to prepare:**
- **App name:** Blinking
- **Subtitle (EN):** Memory & Habit Journal
- **Subtitle (ZH):** 记忆与习惯日记
- **Description (EN):** Capture daily moments, track habits, and build reflective memory cards... (use current Play Store listing text)
- **Description (ZH):** 记录每日瞬间，追踪习惯，制作回忆卡片...
- **Privacy Policy URL:** Serve from a GitHub Pages or gist (or copy the markdown from `docs/Blinking_Notes_Privacy_Policy.md`)
- **Support URL:** `mailto:blinkingfeedback@gmail.com`
- **Marketing URL (optional):** `https://blinkingchorus.com` (if applicable)

**Submission timing:** Allow 24-48h for App Review. First-time submissions may take longer.

---

## Open Questions Resolved vs New

| # | Question | Resolution |
|---|----------|-----------|
| Q1 | Which Flutter stable patches Xcode 26? | **RESOLVED** — 3.41.4+ contains simulator fix; 3.41.7+ contains device debug fix; 3.41.8 has both |
| Q2 | Does Flutter beta build against Xcode 26? | **MOOT** — stable channel already has the fix |
| Q3 | Did iOS 26 raise deployment target? | Re-evaluate during B5 — low risk |
| Q4 | Does iOS 26 require privacy manifest? | **Already exists** — verify during B5 |
| Q5 | Are Apple Developer certificates active? | Unknown — verify during B6 |
| Q6 | Does Chorus backend have iOS requirements? | Low risk — verify during smoke test B4 |

---

## Risk Register (Updated)

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Xcode 26.4.1 download/install failure | Medium | Delays B1 | Use download manager; allow 1-2h for xip extraction |
| Xcode 26 introduces CocoaPod compatibility issue | Low-Medium | B3 delay | Check pod versions on pub.dev for iOS 26 support |
| App Review rejects privacy manifest | Low | B8 delay | Audit during B5; PrivacyInfo.xcprivacy already exists |
| Automatic signing fails without DEVELOPMET_TEAM | Low | B7 delay | Set team manually during B6 |
| iOS 26 simulator contains UI regression in CustomPainter | Low | B4 rework | Test emoji jar + card renderer early |
| Android production (Track A) blocked by beta feedback | Low | No iOS impact | Parallel tracks are independent |

---

## Pre-Flight Checklist (Before Starting B1)

- [ ] `flutter test` — 94/94 passing
- [ ] `flutter analyze --no-pub` — 0 errors
- [ ] `git status` — clean working tree (commit or stash any pending changes)
- [ ] Apple ID ready for Xcode download (developer.apple.com)
- [ ] At least 15 GB free disk space (Xcode ~7 GB + extracted ~15 GB)
- [ ] Stable internet connection (Xcode download + Flutter engine)

---

## Revision Log

| Date | Author | Change |
|------|--------|--------|
| 2026-04-30 | Justin / Claude | Updated plan — Flutter 3.41.8 unblocks iOS pipeline immediately; parallel tracks with Android |
