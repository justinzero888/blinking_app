# UAT Simulator Launch Playbook

> **Last verified:** May 22, 2026  
> **Purpose:** Reliably launch all 3 simulators (iPhone 17 Pro, iPad Air 11" M4, Android Medium Phone API 36) and install the latest Blinking build before every UAT session.

---

## Pre-flight

```bash
# Verify Flutter and tools are ready
flutter doctor --device-license  # ensure licenses accepted
xcrun simctl list devices available | grep -E "iPhone 17 Pro|iPad Air.*M4"  # verify iOS sims exist
emulator -list-avds  # verify Android AVD exists

# Ensure no stale simulators running
xcrun simctl shutdown all
adb -s emulator-5554 emu kill 2>/dev/null || true
```

---

## Step 1: Build the App

```bash
# iOS simulator build (CRITICAL: use --simulator, NOT --no-codesign)
# --no-codesign builds for physical device (arm64 device slice) — will not run on simulator
flutter build ios --debug --simulator

# Android debug build (for emulator)
flutter build apk --debug
```

---

## Step 2: Launch iOS Simulators (sequential — launch one at a time)

```bash
# Step 2a: Boot iPhone 17 Pro
xcrun simctl boot E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA

# Wait for boot to complete
xcrun simctl bootstatus E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA -b

# Open Simulator app (brings window to foreground)
open -a Simulator

# Step 2b: Boot iPad Air 11-inch (M4)
xcrun simctl boot 39B46CD1-C3B5-43C1-B527-A5BCFECEA773

# Wait for boot
xcrun simctl bootstatus 39B46CD1-C3B5-43C1-B527-A5BCFECEA773 -b
```

## Step 3: Launch Android Emulator

```bash
# Launch Android emulator in background
emulator -avd Medium_Phone_API_36.1 -no-snapshot-load -no-boot-anim &
EMULATOR_PID=$!

# Wait for boot to complete (zsh: use variable name other than 'status' — that's read-only)
for i in $(seq 1 30); do
  boot_ok=$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$boot_ok" = "1" ]; then
    echo "Android booted after $((i*5))s"
    break
  fi
  echo "Waiting for Android... ($((i*5))s)"
  sleep 5
done

# Verify adb connection
adb -s emulator-5554 shell getprop sys.boot_completed
# Expected output: "1"
```

## Step 4: Install Blinking on All 3

```bash
# Install on iPhone 17 Pro (simctl is more reliable than flutter install for simulators)
xcrun simctl install E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA build/ios/iphonesimulator/Runner.app

# Install on iPad Air 11-inch
xcrun simctl install 39B46CD1-C3B5-43C1-B527-A5BCFECEA773 build/ios/iphonesimulator/Runner.app

# Install on Android emulator
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Step 5: Launch App on All 3

```bash
# iOS: now works correctly with simulator build
xcrun simctl launch E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA com.blinking.blinking
xcrun simctl launch 39B46CD1-C3B5-43C1-B527-A5BCFECEA773 com.blinking.blinking

# Android: launch via adb (reliable)
adb -s emulator-5554 shell am start -n com.blinking.blinking/.MainActivity
```

---

## Quick Smoke Check (30s per device)

| Check | iPhone | iPad | Android |
|-------|--------|------|---------|
| App launches without crash | ⬜ | ⬜ | ⬜ |
| Bottom nav visible (5 tabs) | ⬜ | ⬜ | ⬜ |
| Floating robot visible | ⬜ | ⬜ | ⬜ |
| Calendar renders | ⬜ | ⬜ | ⬜ |
| Settings → About → version shows from AppConstants | ⬜ | ⬜ | ⬜ |

---

## Shutdown

```bash
# Close all simulators
xcrun simctl shutdown all

# Kill Android emulator
adb -s emulator-5554 emu kill
```

---

## Troubleshooting

| Symptom | Root Cause | Fix |
|---------|------------|-----|
| `xcrun simctl boot` hangs | Simulator already booted | Run `xcrun simctl shutdown <UUID>` first |
| `bootstatus` timeout (>60s) | Simulator stuck during boot | `xcrun simctl shutdown <UUID>`, wait 5s, retry |
| `adb: device offline` | Android emulator starting up | Wait 30s, retry. Run `adb kill-server && adb start-server` if persists |
| `flutter install -d <ios-uuid>` fails | `flutter install` expects release build, not debug | Use `xcrun simctl install <UUID> build/ios/iphoneos/Runner.app` instead |
| `flutter install -d emulator-5554` fails | `flutter install` looks for `app-release.apk` by default | Use `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk` |
| `xcrun simctl launch` fails with "denied by SBMainWorkspace" | Debug builds need UI tap to launch on newer iOS sims | Open Simulator window and tap app icon. Or use `flutter run --debug` instead. |
| iOS app installed but tapping icon does nothing | Built with `--no-codesign` (produces arm64 **device** slice, not simulator) | **CRITICAL: Always use `flutter build ios --debug --simulator`** for simulator. Verify: `lipo -info build/ios/iphonesimulator/Runner.app/Runner` shows `x86_64 arm64`. |
| Android emulator exits immediately after boot | `status` is zsh read-only builtin; shell timeout killed process | Use `boot_ok` as variable name (not `status`). Launch with `nohup` if shell is timing out: `nohup emulator -avd Medium_Phone_API_36.1 -no-snapshot-load &` |
| Android emulator "shutdown gracefully" | Emulator process received kill signal (usually from timeout) | Use `nohup` to detach from shell. Check `pgrep -f Medium_Phone` to verify process running. |
