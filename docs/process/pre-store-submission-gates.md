# Pre-Store Submission Gates — Mandatory Process

> **Applies to:** Any Flutter app with IAP, RevenueCat, or platform store integration.  
> **Rule:** No build may enter TestFlight, Internal Testing, Closed Testing, or production without completing ALL gates.

---

## Gate 0 — Local Build Verification

**Before uploading anything to any store.** Catches IAP integration bugs, missing native frameworks, and stale build artifacts without waiting for store review.

### iOS (real device)
```bash
flutter clean && flutter pub get
flutter build ios --release --dart-define=RC_API_KEY=appl_...
# Open ios/Runner.xcworkspace in Xcode
# Run on real iPhone via USB or WiFi
```
Device must be signed in with a sandbox Apple ID (Settings → App Store → Sandbox Account).

### Android (real device)
```bash
flutter clean && flutter pub get
flutter build apk --release --dart-define=RC_API_KEY=goog_...
adb install build/app/outputs/flutter-apk/app-release.apk
```
Device must be signed in with a Google Play test account added in Play Console → Internal Testing → Testers.

### Verify on both devices

- [ ] App launches without crash
- [ ] Paywall shows price from store (not hardcoded fallback)
- [ ] No "Store unavailable" warning
- [ ] "Get Pro" button is enabled
- [ ] Tap "Get Pro" → native payment sheet appears with correct price
- [ ] Cancel → paywall recovers cleanly (not stuck, not dismissed)
- [ ] Complete sandbox purchase → "Welcome to Pro!" shows, paywall closes
- [ ] Force-kill and reopen → Pro entitlement persists

**If any check fails:** Fix and rebuild locally. Do NOT upload to stores.

---

## Gate 1 — Store Upload

Only after Gate 0 passes on both platforms.

- [ ] iOS: Upload IPA to TestFlight via Transporter or `xcrun altool`
- [ ] Android: Upload AAB to Play Console → Internal Testing / Closed Testing track

---

## Gate 2 — Store-Testing Verification

Run on devices that received the store build (TestFlight / Play download).

- [ ] Launch — no crash
- [ ] Paywall: price matches store, button enabled
- [ ] Purchase flow: cancel + complete (real-device purchase checklist)
- [ ] Restore flow
- [ ] Entitlement persists after force-kill

---

## Post-Release Gate — Pricing Change

If prices change in App Store Connect / Play Console AFTER a build is live:

- [ ] The code fix (offerings refresh in `purchaseProduct`) handles stale cached products
- [ ] Run Gate 0 items 5-8 on the ALREADY-DEPLOYED build — verify purchase still works without rebuilding
- [ ] If purchase fails, rebuild and re-submit with new build number

---

## Checklist Summary

| Gate | Where | When |
|------|-------|------|
| **Gate 0** | Local real device (USB/WiFi) | Before ANY store upload |
| **Gate 1** | TestFlight / Play Console upload | After Gate 0 passes |
| **Gate 2** | Real device via store download | After store build available |
| **Price change** | Existing deployed build | Before promotion after price change |

---

## Change Classification Matrix

**Which gates are required for each type of change?**

| Change | flutter test | Gate 0 | Gate 1+2 | Checklist sections |
|--------|-------------|--------|----------|--------------------|
| `purchases_service.dart` | ✅ | ✅ | ✅ | All sections |
| `paywall_screen.dart` | ✅ | ✅ | ✅ | All sections |
| `entitlement_service.dart` | ✅ | ✅ | ✅ | Already-Pro, Restore |
| RC API key change | ✅ | ✅ | ✅ | Pre-purchase, Purchase Complete |
| Price change in store console (no code) | — | ✅ on existing build | No new build | Price-Change Resilience |
| `app.dart` / provider tree | ✅ | ✅ | No | Smoke only |
| Unrelated UI change | ✅ | No | No | — |

**Rules:**
- Any file touching purchase, entitlement, or RC → Gate 0 + real-device checklist before upload
- Price changes in the store console after a build is live → run Gate 0 items 14–18 on the **already-deployed** build without a rebuild
- Never upload a build that hasn't been smoke-tested on a real device with a real sandbox account
- The stuck-`_isPurchasing` bug and the false-positive Pro gate both shipped because Gate 0 was skipped — it takes 15 minutes and catches both classes of bug
