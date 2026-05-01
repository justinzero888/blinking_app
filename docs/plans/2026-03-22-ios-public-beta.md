# iOS Public Beta Deployment Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Compile, test, and ship Blinking Note v1.1.0-beta.1 to TestFlight for external (public) beta testing.

**Architecture:** Flutter iOS build → Xcode archive → IPA signed with App Store Connect distribution cert → uploaded via `xcodebuild` / Transporter → TestFlight external testing group with no-expiry public link.

**Tech Stack:** Flutter 3.41.2, Xcode 16.2, CocoaPods 1.16.2, `flutter_local_notifications`, `image_picker`, `share_plus`, `file_picker`, `permission_handler`, App Store Connect / TestFlight.

---

## Prerequisites (manual — complete these before running any task)

These require human action in a web browser or on a physical device. Verify each before proceeding.

| # | Prerequisite | Where |
|---|-------------|-------|
| P1 | Enrolled in **Apple Developer Program** ($99/yr) | developer.apple.com |
| P2 | Know your **Team ID** (10-char string, e.g. `ABC1234XYZ`) | developer.apple.com → Membership |
| P3 | **App ID** `com.blinking.blinking` registered (or will be auto-created by Xcode) | developer.apple.com → Identifiers |
| P4 | **App record** created in App Store Connect with bundle ID `com.blinking.blinking` | appstoreconnect.apple.com → My Apps |
| P5 | Xcode signed in with your Apple ID | Xcode → Settings → Accounts |
| P6 | Physical iPhone available for smoke testing (recommended, not required) | — |

---

## Task 1: Fix missing iOS notification permission string

**Problem:** `flutter_local_notifications` on iOS requires `NSUserNotificationsUsageDescription` in `Info.plist` or the App Store review will reject the build. It is currently absent.

**Files:**
- Modify: `ios/Runner/Info.plist`

**Step 1: Add the missing key**

In `ios/Runner/Info.plist`, inside the root `<dict>`, add after the existing photo/camera entries:

```xml
<!-- Local notifications — used by routine reminder feature -->
<key>NSUserNotificationsUsageDescription</key>
<string>Blinking sends reminders to help you complete your daily routines.</string>
```

**Step 2: Verify the plist is valid XML**

```bash
plutil -lint ios/Runner/Info.plist
```
Expected: `ios/Runner/Info.plist: OK`

**Step 3: Commit**

```bash
git add ios/Runner/Info.plist
git commit -m "fix(ios): add NSUserNotificationsUsageDescription for flutter_local_notifications"
```

---

## Task 2: Create and configure the Podfile

Flutter generates a Podfile when you first run `flutter pub get` on iOS. The generated Podfile must set the correct minimum iOS platform; several plugins (`permission_handler`, `flutter_local_notifications`) require ≥ iOS 13.

**Files:**
- Create: `ios/Podfile` (generated, then verified)

**Step 1: Generate the Podfile**

```bash
cd /Users/justinzero/ClaudeDev/blink/blinking_app
flutter pub get
```
Expected: output ends with `Running "flutter pub get" in blinking_app... X.Xs`

**Step 2: Confirm Podfile has correct platform**

```bash
head -5 ios/Podfile
```
Expected first non-comment line: `platform :ios, '13.0'`

If the platform line is missing or lower than 13.0:

```bash
# Edit ios/Podfile line 1 to read:
platform :ios, '13.0'
```

**Step 3: Install pods**

```bash
cd ios && pod install --repo-update
```
Expected: ends with `Pod installation complete! There are N dependencies from the Podfile and N total pods installed.`

Watch for warnings about `IPHONEOS_DEPLOYMENT_TARGET` — if any pod complains about a version mismatch, ensure the Podfile platform matches `13.0`.

**Step 4: Verify workspace file was created**

```bash
ls ios/Runner.xcworkspace/
```
Expected: `contents.xcworkspacedata  xcshareddata/`

**Step 5: Return to project root**

```bash
cd ..
```

**Note:** `Pods/` and `Podfile.lock` are gitignored. Do **not** commit them. The Podfile itself should be committed.

**Step 6: Commit**

```bash
git add ios/Podfile
git commit -m "chore(ios): add Podfile with platform :ios, '13.0'"
```

---

## Task 3: Set the Apple Development Team ID in Xcode

Xcode's automatic signing requires the `DEVELOPMENT_TEAM` to be set. The project currently has an empty ORGANIZATIONNAME and no team set. You can do this via Xcode GUI (easiest) or by editing `project.pbxproj`.

**Method A — Xcode GUI (recommended)**

**Step 1: Open the workspace**

```bash
open ios/Runner.xcworkspace
```

**Step 2: Set signing in Xcode**

1. Select the `Runner` project in the navigator (left sidebar, top item)
2. Select the `Runner` target
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Set **Team** to your Apple Developer team
6. Verify **Bundle Identifier** is `com.blinking.blinking`
7. Xcode will update `project.pbxproj` automatically

**Step 3: Verify no signing errors appear** (the status area should show a valid provisioning profile, not a red error)

**Step 4: Close Xcode**

**Step 5: Commit the updated project file**

```bash
git add ios/Runner.xcodeproj/project.pbxproj
git commit -m "chore(ios): configure automatic signing with Apple Development Team"
```

---

## Task 4: Simulator smoke test — build and run on iOS Simulator

This confirms the app compiles for iOS and the core UI works without a physical device or Apple account.

**Step 1: List available simulators**

```bash
xcrun simctl list devices available | grep -E "iPhone 1[5-6]"
```
Expected: one or more iPhone 15/16 simulator entries

**Step 2: Boot a simulator (pick one from Step 1)**

```bash
xcrun simctl boot "iPhone 16"
```
Expected: no output (already boots in background)

**Step 3: Build and run on simulator**

```bash
flutter run -d "iPhone 16"
```
Expected: app launches in Simulator. Watch for any `Error` lines in the Flutter output.

**Step 4: Manual smoke test checklist in Simulator**

Work through each screen and verify no crashes or layout breaks:

- [ ] App launches to Calendar tab
- [ ] FAB → Add Entry → save entry → entry appears on calendar
- [ ] Tap Moment tab → entry visible
- [ ] Tap Routine tab → all 3 sub-tabs load
- [ ] Tap 珍藏 tab → 书架 / 卡片 / 总结 tabs load
- [ ] Tap Settings → all rows render
- [ ] Settings → Language → switch to English → all UI updates
- [ ] Settings → Language → switch back to Chinese
- [ ] Robot FAB → opens AI chat screen (LLM config not required to verify UI opens)
- [ ] Settings → Privacy Policy → document loads
- [ ] Settings → Terms of Service → document loads

**Step 5: Stop the app**

Press `q` in the terminal running `flutter run`.

---

## Task 5: Validate flutter analyze — zero errors

The App Store build pipeline is stricter. Catch issues now.

**Step 1: Run the linter**

```bash
flutter analyze --no-pub 2>&1
```
Expected: `No issues found!`

If issues are found: fix each one before continuing. Do not proceed with warnings that Dart treats as errors.

**Step 2: Commit any lint fixes**

```bash
git add -p   # stage only changed Dart files
git commit -m "fix: resolve flutter analyze warnings for iOS release build"
```

---

## Task 6: Build the release IPA

`flutter build ipa` compiles a release IPA suitable for TestFlight upload. It uses the `ExportOptions.plist` at `ios/ExportOptions.plist` which is already configured for `app-store-connect` with automatic signing.

**Step 1: Clean previous build artifacts**

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

**Step 2: Build the release IPA**

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Expected final lines:
```
Built IPA to /Users/justinzero/ClaudeDev/blink/blinking_app/build/ios/ipa/blinking.ipa
```

**If you see a signing error:**
```
error: No signing certificate "iOS Distribution" found
```
→ Go back to Task 3 and ensure the team is set. Or run `flutter build ipa --release` without `--export-options-plist` and let Xcode handle export via the Organizer (see Task 7 alternative).

**If you see a code signing identity error for "iPhone Developer":**
The project.pbxproj still has the old identity string. Open Xcode, go to Signing & Capabilities, and re-confirm automatic signing is set for the Release configuration specifically.

**Step 3: Confirm IPA file exists**

```bash
ls -lh build/ios/ipa/*.ipa
```
Expected: a `.ipa` file ~30-80 MB.

---

## Task 7 (alternative): Archive and export via Xcode Organizer

Use this if Task 6 fails due to signing issues. This is the most reliable manual path.

**Step 1: Archive in Xcode**

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Set scheme to **Runner** (top-left dropdown)
2. Set destination to **Any iOS Device (arm64)**
3. Menu → **Product → Archive**
4. Wait for archive to complete (2-5 min)
5. Organizer window opens automatically

**Step 2: Export from Organizer**

1. Select the new archive
2. Click **Distribute App**
3. Choose **TestFlight & App Store**
4. Choose **Upload** or **Export** → **Automatically manage signing**
5. Click **Next → Next → Upload** (or export to disk if you want to upload separately)

---

## Task 8: Upload IPA to App Store Connect / TestFlight

**Method A — Command line upload (recommended if IPA built in Task 6)**

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/blinking.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

Replace `YOUR_API_KEY` and `YOUR_ISSUER_ID` with values from App Store Connect → Users & Access → Integrations → App Store Connect API.

Alternative using Transporter app (no API key needed):
```bash
open -a Transporter
# Drag and drop the IPA file
# Click Deliver
```

**Method B — Via Xcode Organizer (if you used Task 7)**

Click **Upload** in the Organizer distribute flow. It uploads directly.

**Step 2: Wait for processing**

TestFlight processing takes 5-30 minutes. You'll receive an email when the build is ready.

---

## Task 9: Configure TestFlight external testing group

**Step 1: In App Store Connect → TestFlight**

1. Select the uploaded build (version 1.1.0-beta.1, build 9)
2. Navigate to **TestFlight → External Testing**
3. Click **+** to create a group (e.g. "Public Beta")
4. Add the build to the group
5. Add **Beta Review Information** (required for external groups):
   - Contact info, demo account (if needed — this app needs no login)
   - Beta App Description (English): "Blinking Note is a personal memory and habit journaling app. Capture daily moments, track routines, and build reflective memory cards."
   - Beta App Feedback Email: your email
6. Click **Submit for Beta Review**

**Step 2: Get the public link (after Apple approves, ~24-48h)**

1. In the external group, toggle **Enable Public Link**
2. Copy the TestFlight public link (format: `https://testflight.apple.com/join/XXXXXXXX`)
3. Share this link with beta testers — it works without them being individually invited

---

## Task 10: Verify beta build on physical device

After TestFlight processing:

**Step 1:** Install TestFlight on a real iPhone (App Store)

**Step 2:** Open the public beta link on the device or accept invitation

**Step 3:** Install and run the app

**Step 4: Physical device smoke test checklist**

- [ ] App launches without crash
- [ ] System dialog: "Blinking would like to send notifications" — verify it appears and Accept
- [ ] Add journal entry with camera photo → photo appears in entry
- [ ] Add journal entry with photo library image → works
- [ ] Settings → Export → ZIP created and shareable via share sheet
- [ ] Settings → Import → file picker opens
- [ ] Create a memory card → share as PNG via share sheet
- [ ] Routine reminder set → notification fires at correct time (test with 1-minute future time)
- [ ] App backgrounded and re-opened → state preserved

---

## Known Gaps & Deferred Items

These do NOT block the beta but are noted for post-beta follow-up:

| Item | Notes |
|------|-------|
| Notification permission dialog fires immediately on first launch | `main.dart:16` calls `requestPermissions()` at startup. Consider deferring to first routine creation. |
| No `Podfile.lock` committed | Acceptable for development; pin before production release. |
| ORGANIZATIONNAME empty in project.pbxproj | Cosmetic only; set it to your org name in Xcode project settings. |
| iPad layout not designed | `TARGETED_DEVICE_FAMILY = "1,2"` allows iPad; verify no broken layouts. |
| Firebase commented out | Cloud sync remains P3. Do not enable without security review. |

---

## Quick Reference: Key File Locations

| Purpose | Path |
|---------|------|
| iOS Info.plist | `ios/Runner/Info.plist` |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` |
| Export options | `ios/ExportOptions.plist` |
| Bundle ID | `com.blinking.blinking` (in `project.pbxproj`) |
| App version | `1.1.0-beta.1+9` (in `pubspec.yaml`) |
| Deployment target | iOS 13.0 (in `project.pbxproj`) |
| Notification service | `lib/core/services/notification_service.dart` |
| Main entry (notification init) | `lib/main.dart:15-16` |
