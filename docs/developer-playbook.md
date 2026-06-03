# Blinking App — Developer Playbook

> **For new dev team onboarding.** This document consolidates every process, lesson learned, and remaining task. Start here.

---

## 1. Quick Reference

| Item | Value |
|------|-------|
| **Flutter SDK** | 3.41.9 (stable) |
| **macOS / Xcode** | 26.2 Tahoe / 26.4.1 |
| **Repo** | `/Users/justinzero/ClaudeDev/blink/blinking_app` |
| **Current version** | 1.2.0+56 (dev HEAD) · v1.2.0+54 iOS pending review · v1.2.0+55 Google Play pending review |
| **IAP** | RevenueCat `blinking_pro` ($7.99 non-consumable, entitlement `pro_access`) |
| **Tests** | 578/578 passing, 0 failures |
| **Lint** | `flutter analyze --no-pub` — 0 errors, 2 known false-positive warnings |
| **Context doc** | `CLAUDE.md` — full architecture, file map, commit history |

---

## 2. Daily Workflow

### Before touching any code
```
flutter analyze --no-pub    # target: 0 errors
flutter test                # all must pass
```

### Building for simulators (UAT)
```
flutter clean
cd ios && pod install && cd ..
flutter build ios --simulator
flutter build apk --debug
```

### Building for production (store upload)
```bash
# Single command — validates keys, builds both platforms, verifies output
TRIAL_API_KEY=<key> PRO_API_KEY=<key> bash scripts/build-release.sh
```

The script handles: key validation, `flutter analyze` + `flutter test`, clean once, iOS IPA first, Android AAB second, merged manifest check (no leaked media permissions), artifact verification.

Manual (if script not used):
```bash
flutter clean && flutter pub get
flutter build ipa --release --dart-define=...   # iOS FIRST
flutter build appbundle --release --dart-define=...  # Android SECOND
# NEVER flutter clean between builds
```

### Pushing to sims
```
xcrun simctl uninstall <device> com.blinking.blinking
xcrun simctl install <device> build/ios/iphonesimulator/Runner.app
xcrun simctl launch <device> com.blinking.blinking
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.blinking.blinking 1
```

### Version bumps
- **Sim builds:** no bump needed
- **Store builds (IPA/AAB):** MUST increment build number every time
- Current: `1.2.0+54`

---

## 3. Architecture Rules

### RevenueCat is the single source of truth for Pro state
- `PurchasesService.isPro` (`_customerInfo.entitlements.active.containsKey('pro_access')`) determines paid status
- `EntitlementService.init(isPro:)` syncs from RC on app start
- After purchase, the `PurchaseResult.customerInfo` is authoritative — do NOT `refreshCustomerInfo()` in the purchase handler
- `_markEntitlementPaid()` writes to SharedPreferences AND calls `EntitlementService.init()`

### Purchase flow checkpoints
1. "Get Pro" visible ↔ `EntitlementService.isRestricted`
2. Tap "Get Pro" → check `PurchasesService.isPro`:
   - `true` → auto-restore Pro (user already owns it)
   - `false` → show native payment sheet
3. After purchase: `_customerInfo` set from purchase result → `service.isPro` true → "Welcome to Pro!"

### State providers
- `EntryProvider` — source of truth for entries
- `RoutineProvider` — source of truth for routines
- `PurchasesService` — RevenueCat IAP (init in main.dart)
- `EntitlementService` — preview/restricted/paid state machine (syncs from RC)
- Never hardcode IDs; use named constants

### Entity relationship
```
PurchasesService (RC server)  ──isPro──▶  EntitlementService (local)
                                              │
                                              ├── isRestricted → "Get Pro" CTA visible
                                              ├── isPreview → trial mode
                                              └── isPaid → Pro unlocked
```

---

## 4. Purchase Flow — Complete Trace

```
User taps "Get Pro"
  │
  ├─ _handlePurchase(context, isZh)
  │     ├─ isInitialized? ──no──▶ "Store not ready" snackbar
  │     ├─ _isPurchasing = true (button shows spinner)
  │     ├─ purchaseProduct('blinking_pro')
  │     │     ├─ Offerings refresh (30s timeout, proceeds with cached on failure)
  │     │     ├─ Product lookup → blinking_pro
  │     │     ├─ Purchases.purchase() (90s timeout)
  │     │     │     ├─ iOS: native payment sheet
  │     │     │     └─ Android: Play Billing flow
  │     │     └─ Returns customerInfo → _customerInfo set
  │     ├─ _isPurchasing = false
  │     ├─ info == null && lastError == null → cancelled (return)
  │     ├─ service.isPro || info != null
  │     │     ├─ true → _markEntitlementPaid() → "Welcome to Pro!" → pop paywall
  │     │     └─ false → show lastError snackbar
  │     └─ On exception: _isPurchasing stays true (bad!) → future taps dead
  └─ Done
```

---

## 5. Lessons Learned

### Lesson 1: One edit, one analyze
After every edit, run `flutter analyze`. Never batch edits. One broken edit cascades into 5 more that try to "fix" the previous.

### Lesson 2: Never hardcode IDs
Every ID referenced in logic must be a named constant in the model that defines it. Single source of truth for renames — otherwise grep-and-replace misses references in 10+ files.

### Lesson 3: SharedPreferences is for settings, not data
If data > 1KB, use SQLite or the filesystem. Images belong in `ApplicationDocumentsDirectory` with a path stored in prefs. Base64-encoded images exceed iOS NSUserDefaults limits and silently truncate.

### Lesson 4: Seed data must have one canonical source
If a class like `DefaultRoutines` exists, it must be the single source and `StorageService` imports from it — not duplicates it. Stale duplicates silently overwrite correct data on reset.

### Lesson 5: Keep seed logic in `main.dart`, not in shared providers
Seed code in `RoutineProvider.loadRoutines()` runs in both production and test environments. This causes test failures when the seed creates unexpected state. Production-only initialization belongs outside shared provider code.

### Lesson 6: Build order — IPA first, then AAB
`flutter clean` once at start. Never clean between builds.

### Lesson 7: Model field addition is a 7-layer write chain
Adding one field requires changes in: `[ ] Model [ ] DB create [ ] DB migrate [ ] Storage insert [ ] Storage select [ ] Repository [ ] Provider [ ] Version test`. Missing any layer = data works in memory but is lost on restart.

### Lesson 8: Use `--simulator` not `--no-codesign` for simulator builds
`flutter build ios --debug --no-codesign` produces a device (`arm64`) binary. Installing on a simulator causes silent failure — the app icon does nothing. Always use `flutter build ios --debug --simulator`. Verify with `lipo -info` — should show `x86_64 arm64`.

### Lesson 9: Check dependency API before design
`flutter_local_notifications` v21 removed `onDidReceiveLocalNotification` (existed in v10+). Design assumed the callback existed. Verify installed package source with `grep`, not pub.dev docs which may show older versions.

### Lesson 10: Android emulator TTS is broken
Google TTS native library (`libgoogle_speech_sbg_tts_jni.so`) crashes on emulated ARM. `flutter_tts.speak()` returns success — the crash is in the native process. Test TTS on iPhone simulator or real Android device.

### Lesson 11: JSON-encode complex types for SQLite
`List<String>`, `Map`, and `Set` cannot be stored directly in SQLite `TEXT` columns. Use `jsonEncode()` on insert and `jsonDecode()` on read. Use a helper that handles both raw and encoded formats for backward compatibility.

### Lesson 12: Async ordering — never put `cancelAll()` inside async lifecycle
`cancelAll()` inside `loadRoutines()` (async, called from `create:`) can run AFTER `scheduleRoutine()` due to async ordering. Always cancel specific IDs, not everything. Chain async calls explicitly.

### Lesson 13: OverlayEntry only for off-screen rendering
`_renderOffscreen`/`renderToFile` is test-only. OverlayEntry at `Positioned(left: -2000)` is the only production path.

### Lesson 14: Raw assets out of bundle
PNGs in `dev/cards-raw/`, JPGs in `assets/cards/`. Only `assets/cards/` in pubspec.

### Lesson 15: Every store build increments
`flutter build ipa` or `flutter build appbundle` → new build number. No exceptions.

### Lesson 16: Clean-build for iOS sim
`flutter clean && cd ios && pod install` before every sim build. Native frameworks need CocoaPods re-link.

### Lesson 17: Don't redesign a working pipeline
Fix the specific failure mode within existing architecture.

### Lesson 20: Price changes BEFORE build cut
Changing store prices after deployment creates stale `StoreProduct` references in cached `_offerings`. Offerings now refresh before every purchase (defense-in-depth).

### Lesson 21: Local device test before store upload
Never upload to TestFlight/Play Store blind. 3-gate process: local device → store upload → store download verification.

### Lesson 22: Simulator StoreKit ≠ real IAP
Simulator test store is isolated from live stores. Maestro passes on sim do not validate real purchase flow.

### Lesson 25: TestFlight sandbox returns non-null CustomerInfo always
`Purchases.purchase()` on TestFlight returns `CustomerInfo` even on cancel. Check `entitlements.active`, not `!= null`.

### Lesson 26: Purchase gate must trust RC as single source of truth
`service.isPro` alone is the gate. Never add `|| info != null` — the race condition that required it (v1.1.0 `refreshCustomerInfo()`) is eliminated. `_customerInfo` is set directly from `PurchaseResult`, and `EntitlementService.init(isPro:)` syncs on app start.

### Lesson 27: RevenueCat API keys must be verified character-for-character
One wrong character = zero offerings = wasted testing cycles. iOS: `appl_vgTGaiNtCARgmdgOzpJcZyITNAT`. Android: `goog_ITjNhBQowFMaFwdyZYvaCGqqioi`.

### Lesson 28: `refreshCustomerInfo()` in the restore handler overwrites the authoritative result
`restorePurchases()` already returns the freshest `CustomerInfo`. Calling `refreshCustomerInfo()` immediately after can overwrite it with a pre-sync server state on slow connections. The restore result IS the authoritative state — don't re-fetch it.

### Lesson 29: Restore errors show misleading message without `lastError` branch
The `_handleRestore` else branch ("No previous Pro purchase found.") fires for BOTH the no-prior-purchase case AND store errors (where `info == null && lastError != null`). Always add `else if (service.lastError != null)` before the catch-all else to surface actual error messages.

### Lesson 30: Every feature needs automated tests, not just a design doc
Tests documented in a design doc are not tests — they are intentions. After every feature or bug fix, verify: test file exists, test count increased, analyze returns 0 errors. A feature is not "done" until automated tests exist. UAT is for human UX verification, not regression protection.

### Lesson 31: Maestro feedback ≠ new code needed
Before fixing a Maestro-reported "code fix needed", check `git log` first. If the fix is already committed, the issue is a stale installed build, not a code gap. Treat "needs new build" feedback as "verify in code first."

### Lesson 32: Automation failures ≠ customer bugs — classify before fixing
After every Maestro/UAT failure, ask: "Does this affect a real human user?" If a finger tap works but Maestro fails → P2-automation, batch at end of day. Only drop everything for P0-human (crash, data loss, feature broken for real users). DEF-V-001 consumed a full day across 7 versions for a zero-customer-impact automation gap.

### Lesson 33: Server deployment — verify with curl, not "the app works"
The app can work via compile-time dart-define fallback keys even when the server is never deployed. "AI works" does not mean "server is deployed." After every `wrangler deploy`, verify each endpoint independently:
```bash
curl -s https://blinkingchorus.com/api/config | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK')"
```

### Lesson 34: Git status before claiming "deployed"
`wrangler deploy` pushes whatever is in the filesystem — including uncommitted changes. A subsequent deploy from committed code overwrites them silently. Always `git status` + `git push` before deploying. The source of truth is git, not the deployed server.

### Lesson 35: Locale logic must be verified per-field in both locales
`isZh ? descriptionEn : description` (reversed) and `name` instead of `displayName(isZh)` are silent bugs — each field fails independently. For every user-facing string, create a test that verifies both EN and ZH render correctly.

---

## 6. Maestro UAT

### Run scripts
```bash
cd maestro-tests
./ci/run-uat-iphone.sh --device E755BD80
./ci/run-uat-ipad.sh --device 39B46CD1
./ci/run-uat-android.sh --device emulator-5554
```

### Flow descriptions
| ID | Tests |
|----|-------|
| k1–k10 | Keepsake card CRUD, templates, overlays, edit, locale, photo |
| p1 | Paywall ready — RC init, price display, button enabled |
| p2 | Paywall CTA smoke — Restore round-trip, cancel recovery |

---

## 7. Production Debt / Deferred

| Priority | Item | Effort | Notes |
|----------|------|--------|-------|
| P2 | Personas web page at blinkingchorus.com/personas | ~2h | Not started |
| P2 | Habit template browse/import UI | ~2h | Not started |
| P2 | Marketing plan (launch strategy, ASO) | TBD | Not started |
| P3 | Firebase / Cloud Sync | Large | All deps commented out |
| P3 | Card History screen (grid) | ~3h | Deferred to v1.3.0 |
| P3 | Voice notification — background TTS | ~4h | Deferred to v1.3.0 |
| P3 | Entitlement server enabling (`ENTITLEMENT_ENABLED`) | ~4h | Blocks trial abuse prevention |
| P3 | True Kaishu font (LXGW WenKai) | ~2h | Currently using MaShanZheng xingshu |

---

## 8. RC–Google Play Sync Diagnostic

**When to use:** A purchase shows in Google Play's order management (play.google.com/console → Orders) but does NOT appear in RevenueCat → Customers → Sandbox/Production. This means RC's receipt validation rejected or never received the receipt.

### Why this happens

RC validates Google Play receipts by calling Google Play Developer API server-side. Failures are silent in production logs — the SDK swallows the HTTP error and the order never lands in RC. Common causes:

| Error code | Meaning | Fix |
|------------|---------|-----|
| `400` | Malformed receipt or wrong bundle ID | Verify `applicationId` in `build.gradle` matches Play Console |
| `403` | Service account missing permission | Play Console → Setup → API access → grant the service account "Order management" permission |
| `401` | RC Google credentials expired or wrong key | Re-download service account JSON from Google Cloud → re-upload to RC dashboard |
| No RC API call at all | Purchase callback never fired | Play Billing integration issue — check `BillingClient.startConnection()` |

### The sideloading constraint

**Lesson Learned:** Sideloaded APKs cannot make new purchases via `launchBillingFlow()` — the Play Store rejects billing requests from apps not installed through the Store. However, the diagnostic only needs **Restore Purchases**, which calls `queryPurchasesAsync()` to query the Google account's existing order history. This is a read operation against the Google account, not against the installation source, and it works on properly signed sideloaded APKs.

Two distinct Play Billing operations — different rules:

| Operation | Sideloaded APK | Requires Play Store install |
|-----------|---------------|----------------------------|
| `launchBillingFlow()` — new purchase | ❌ Fails | ✅ |
| `queryPurchasesAsync()` — restore | ✅ Works (production-signed) | — |

The diagnostic only uses restore → sideloading a production-signed release APK is sufficient.

### Build the diagnostic APK

**Critical:** Do NOT use a debug APK (`--debug`). Debug builds have the Test Store key hard-coded as fallback, and the Test Store key cannot validate real Play receipts. Use a **release APK** with the `RC_DEBUG_LOG` flag:

```bash
flutter build apk --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=RC_DEBUG_LOG=true
```

The `RC_DEBUG_LOG=true` flag enables `LogLevel.debug` in `purchases_service.dart` even in release mode — full RC HTTP logging without any production impact on the normal release build (which never sets this flag).

### Tier 1 — Sideloaded release APK (fastest, try first)

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Then:
1. Open app on the device signed in with the Google account that has the unsynced order
2. Settings → About → tap version 5× to enter restricted mode → tap robot → open paywall
3. Tap **Restore Purchases**

Watch the log stream on your machine:
```bash
adb logcat | grep -iE "RevenueCat|revenuecat|api\.revenuecat\.com"
```

You will see one of:
- `POST api.revenuecat.com/v1/receipts → 200` — receipt accepted; order appears in RC
- `POST api.revenuecat.com/v1/receipts → 400/403/401` — rejection with specific error body
- No RC API call — `queryPurchasesAsync()` returned nothing; escalate to Tier 2

### Tier 2 — Internal Testing track (if Tier 1 restore returns no results)

If the sideloaded restore triggers no RC API call, Play Billing's `queryPurchasesAsync()` is not returning the purchase token for the sideloaded APK. Upload the same build to the Internal Testing track and install it from the Play Store:

```bash
# Use the same APK built above — already has RC_DEBUG_LOG=true
# Upload to Play Console → Internal Testing → upload APK (not AAB — faster processing)
# Internal Testing typically processes in 5–15 minutes
# Install on device via the Internal Testing opt-in link
```

Then repeat the restore + logcat steps above. Installation via the Play Store ensures `queryPurchasesAsync()` returns the full purchase history.

### What NOT to do

- ❌ Debug APK (`--debug`) — uses Test Store key which cannot validate production receipts
- ❌ Check RC dashboard before running the restore — sync only triggers on an active SDK call
- ❌ Run this on iOS for a Google Play order — receipts are platform-specific
- ❌ Make a new purchase during the diagnostic — not needed and adds billing complexity

---

## 9. Common Pitfalls  <!-- was §8 -->

**Purchase / IAP**
- ❌ `refreshCustomerInfo()` after purchase or restore → overwrites authoritative result with stale data
- ❌ `|| info != null` as Pro gate → TestFlight always returns non-null CustomerInfo, grants Pro for free
- ❌ Same sandbox Apple ID for consecutive tests → StoreKit auto-restores without showing payment sheet
- ❌ Changing store price after build cut → stale `StoreProduct` references, silent purchase failure
- ❌ Debug APK for RC sync diagnostic → Test Store key can't validate production Play receipts; use `RC_DEBUG_LOG=true` release build

**Build / Deploy**
- ❌ `flutter build appbundle && flutter clean` → AAB deleted by clean; never clean between builds
- ❌ `flutter build ios --debug --no-codesign` for simulator → arm64 device binary, silent failure on sim; use `--simulator`
- ❌ "App works" = "server deployed" → compile-time fallback keys mask deployment gaps; always verify with curl
- ❌ `wrangler deploy` before `git push` → uncommitted changes deployed, then silently lost on next deploy

**Flutter / Dart**
- ❌ Manual `PipelineOwner` for rendering → only works under `TestWidgetsFlutterBinding`, breaks on device
- ❌ Missing `flutter clean && pod install` → `objective_c.framework` absent on iOS sim
- ❌ Complex types (`List`, `Map`) inserted directly into SQLite → use `jsonEncode()`/`jsonDecode()`
- ❌ Seed data in shared providers → runs in test environment; keep in `main.dart`
- ❌ `ALTER TABLE ADD COLUMN` idempotency tests → not idempotent by design; framework ensures migrations run once

**Testing**
- ❌ Treating every Maestro failure as P0 → automation-only failures have zero customer impact; classify first
- ❌ Feature "done" without automated tests → design doc test plans are intentions, not tests

---

## 10. Key Contacts

| Role | Contact |
|------|---------|
| Dev email | `alan.szhang1@gmail.com` |
| Feedback email | `blinkingfeedback@gmail.com` |
| Server config | `https://blinkingchorus.com/api/config` |
| App Store | [Blinking Notes](https://apps.apple.com/app/id6765900648) (Apple ID: 6765900648) |
