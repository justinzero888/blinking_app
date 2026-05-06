# iOS Build & TestFlight Release Guide

## Overview

This document covers the full pipeline for building a signed IPA and pushing it to TestFlight for internal testing. Steps are split between **AI** (build/upload) and **Human** (App Store Connect web actions + device testing).

---

## Platform Version String Convention

Android and iOS use different version strings due to Apple's restriction that `CFBundleShortVersionString` can only contain 3 integers (major.minor.patch):

| Platform | Version Field | Source | Example |
|----------|--------------|--------|---------|
| **Android** | `versionName` | `pubspec.yaml` version name | `1.1.0-beta.7` |
| **Android** | `versionCode` | `pubspec.yaml` build number | `22` |
| **iOS** | `CFBundleShortVersionString` | Manual in `ios/Runner/Info.plist` | `1.1.0` (3 integers only) |
| **iOS** | `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` from pubspec | `22` |

**Important:** When bumping the version name (e.g. `1.1.0-beta.7` → `1.1.0-beta.8`), the iOS `CFBundleShortVersionString` only needs updating if the major.minor.patch portion of the version changes. The build number (`CFBundleVersion`) is what actually ties both platform builds together as the same release.

---

## Step 1 — Pre-Build: Verify Version Sync (Human + AI)

### Human
- Bump the version in `pubspec.yaml` (both version name and build number)
- Update `lib/core/config/constants.dart` `AppConstants.appVersion` to match
- If the major.minor.patch portion changed, update `ios/Runner/Info.plist` `CFBundleShortVersionString` to the 3-integer form

### AI
- Run tests and analysis to confirm nothing broken:

```bash
cd /Users/justinzero/ClaudeDev/blink/blinking_app
flutter analyze --no-pub
flutter test
```

---

## Step 2 — Build Unsigned Archive (AI)

```bash
cd /Users/justinzero/ClaudeDev/blink/blinking_app
flutter clean && flutter pub get
flutter build ipa --no-codesign
```

**What it produces:**
- `build/ios/archive/Runner.xcarchive` — unsigned archive
- `--no-codesign` avoids Xcode picking the wrong signing identity (development instead of distribution)

**Verify output:**
- Check the terminal for `Version Number: 1.1.0` and `Build Number: 22` in the "[✓] App Settings Validation" section

---

## Step 3 — Export Signed IPA (AI)

```bash
cd /Users/justinzero/ClaudeDev/blink/blinking_app
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates
```

**Key details:**
- `ios/ExportOptions.plist` — configures `app-store-connect` export method, Team ID `4Q4LMBRDM3`
- `-allowProvisioningUpdates` — lets Xcode auto-manage signing identities and profiles
- Expect `** EXPORT SUCCEEDED **` in output

**Output:** `build/ios/ipa/blinking.ipa`

---

## Step 4 — Upload to App Store Connect (AI)

```bash
cd /Users/justinzero/ClaudeDev/blink/blinking_app
xcrun altool --upload-app \
  -f build/ios/ipa/blinking.ipa \
  -t ios \
  --apiKey 6S889FNN6R \
  --apiIssuer 8525f01e-0925-49f8-9862-739031df8d50
```

**Expect:** `UPLOAD SUCCEEDED with no errors`

**Credentials:**
- API Key: `6S889FNN6R` (App Manager role, stored in App Store Connect → Users and Access → Keys)
- Issuer ID: `8525f01e-0925-49f8-9862-739031df8d50`

---

## Step 5 — App Store Connect Web Actions (Human)

### 5a. Wait for Processing
1. Go to https://appstoreconnect.apple.com
2. Navigate to **My Apps** → **Blinking Notes** → **TestFlight**
3. The new build appears with status "Processing" — wait 20–60 minutes until status shows "Complete"

### 5b. Handle Export Compliance (if needed)
- If a yellow ⚠️ icon appears next to the build, click it
- Answer the encryption question: select **"No"** (the app's `Info.plist` declares `ITSAppUsesNonExemptEncryption=false`)

### 5c. Add Build to Internal Testing
1. In the TestFlight tab, click on the new build (e.g. **1.1.0 (22)**)
2. Go to **Internal Testing** section
3. Under the **Builds** tab, click the **"+"** button and add the new build
4. (If this is the first time, also add testers under the **Testers** tab)

### 5d. Notify Testers (optional)
- TestFlight automatically notifies internal testers via email when a new build is added
- No manual notification needed

---

## Step 6 — Install/Update on iPhone (Human)

1. Open the **TestFlight** app on iPhone
2. Tap **Blinking Notes**
3. Tap **Update** (or **Install** if first time)
4. Wait for download to complete
5. Start testing

---

## Quick Reference: Command Cheat Sheet

```bash
# Verify
cd /Users/justinzero/ClaudeDev/blink/blinking_app
flutter analyze --no-pub
flutter test

# Build & Sign
flutter clean && flutter pub get && flutter build ipa --no-codesign && \
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates

# Upload
xcrun altool --upload-app \
  -f build/ios/ipa/blinking.ipa \
  -t ios \
  --apiKey 6S889FNN6R \
  --apiIssuer 8525f01e-0925-49f8-9862-739031df8d50
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build not appearing in TestFlight | Still processing — wait longer (up to 60 min) |
| Export compliance warning | Answer "No" to encryption question in App Store Connect |
| Signing errors during export | Ensure ExportOptions.plist has correct Team ID (`4Q4LMBRDM3`); run with `-allowProvisioningUpdates` |
| Wrong version number on iPhone | Check that build was added to Internal Testing group (Step 5c); pull down to refresh in TestFlight app |
| `altool` auth failure | Verify API Key `6S889FNN6R` is active in App Store Connect → Users and Access → Keys |
| Landscape crash on older iPhones | Known issue with Xcode 26/Metal shader validation; use `--no-codesign` build path |
