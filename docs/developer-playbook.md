# Blinking App — Developer Playbook

> **For new dev team onboarding.** This document consolidates every process, lesson learned, and remaining task. Start here.

---

## 1. Quick Reference

| Item | Value |
|------|-------|
| **Flutter SDK** | 3.41.9 (stable) |
| **macOS / Xcode** | 26.2 Tahoe / 26.4.1 |
| **Repo** | `/Users/justinzero/ClaudeDev/blink/blinking_app` |
| **Current version** | 1.2.0+56 (dev), 1.1.0+40 (production), 1.2.0+51 (in review) |
| **IAP** | RevenueCat `blinking_pro` ($7.99 non-consumable, entitlement `pro_access`) |
| **Tests** | 557 pass, 8 pre-existing flaky (home_screen and db_index) |
| **Lint** | `flutter analyze --no-pub` — target 0 errors |
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
After every edit, run `flutter analyze`. Never batch edits.

### Lesson 2: Never hardcode IDs
Use named constants defined in the owning model.

### Lesson 6: Build order — IPA first, then AAB
`flutter clean` once at start. Never clean between builds.

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
One wrong character = zero offerings = wasted testing cycles. Centralized source of truth: `.opencode/skills/blinking-lessons/references/iap.md`. iOS: `appl_vgTGaiNtCARgmdgOzpJcZyITNAT`. Android: `goog_ITjNhBQowFMaFwdyZYvaCGqqioi`.

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

- ❌ Calling `refreshCustomerInfo()` after purchase → overwrites authoritative purchase result with stale data
- ❌ Testing purchase flow with same sandbox Apple ID → StoreKit auto-restores without sheet
- ❌ Changing store price after build cut → stale `StoreProduct` references
- ❌ `flutter build appbundle && flutter clean` → AAB deleted by clean
- ❌ Manual `PipelineOwner` for rendering → only works in test environment
- ❌ Missing `flutter clean && pod install` → `objective_c.framework` absent on iOS sim

---

## 10. Key Contacts

| Role | Contact |
|------|---------|
| Dev email | `alan.szhang1@gmail.com` |
| Feedback email | `blinkingfeedback@gmail.com` |
| Server config | `https://blinkingchorus.com/api/config` |
| App Store | [Blinking Notes](https://apps.apple.com/app/id6765900648) (Apple ID: 6765900648) |
