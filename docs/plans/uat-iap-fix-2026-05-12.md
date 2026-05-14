# IAP Purchase Flow UAT — App Review Fix Verification

**Date:** 2026-05-12 | **Version:** 1.1.0+32 | **Build:** `flutter build ios --debug --simulator`

**Review issue:** Apple rejected — "unable to complete the purchase" on iPad Air 11" (M3), iPadOS 26.4.2.
**Root cause:** Missing `--dart-define=RC_API_KEY` in production build command. Paywall had no loading state (StatelessWidget).

---

## Setup

```bash
# Build with all 3 keys (RC key was missing before):
flutter build ios --debug --simulator \
  --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT \
  --dart-define=TRIAL_API_KEY=sk-or-v1-... \
  --dart-define=PRO_API_KEY=sk-or-v1-...

# Install + launch:
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.blinking.blinking
```

Simulator: iPhone 17 Pro (iOS 26.5). Also test on iPad Air 11" (M4) for parity with review device.

---

## UAT-A: Store Initialization (RevenueCat)

| # | Step | Expected | ✅ |
|---|------|----------|----|
| A.1 | App launches fresh | Onboarding appears, no crash | |
| A.2 | Complete onboarding | Main screen loads | |
| A.3 | Debug toggle: Tap version 5x → switch to restricted | Orange banner appears in Settings → AI | |
| A.4 | Tap dormant robot → Paywall opens | Paywall screen appears | |
| A.5 | **Check "Get Pro" button is TAPPABLE** | Button is blue/primary, NOT greyed out | |
| A.6 | **Check NO "Store unavailable" orange message** | No orange text below Get Pro button | |
| A.7 | **Check button shows "Get Pro — $19.99"** (not spinner) | Text label visible, not loading | |

**Why important:** Before the fix, `RC_API_KEY` was missing — button showed "Store unavailable" on the submitted IPA.

---

## UAT-B: Purchase Flow — Loading State (Fixing StatelessWidget → StatefulWidget)

| # | Step | Expected | ✅ |
|---|------|----------|----|
| B.1 | Tap "Get Pro" | Button shows **spinning CircularProgressIndicator** immediately | |
| B.2 | During purchase | Button is **disabled** (greyed out, no second tap possible) | |
| B.3 | "Restore Purchases" button | Also **disabled** (greyed out) during purchase | |
| B.4 | Back + Close buttons in AppBar | **Disabled** during purchase | |
| B.5 | Test Store dialog appears | 3-button system dialog shown | |
| B.6 | Spinner stays visible while dialog is open | Loading indicator visible behind system dialog | |

**Why important:** The original `StatelessWidget` had no loading state. On iPad (slower animated transition), the button appeared frozen/unresponsive. Reviewer interpreted this as "unable to complete the purchase."

---

## UAT-C: Successful Purchase

| # | Step | Expected | ✅ |
|---|------|----------|----|
| C.1 | In Test Store dialog → tap "Test valid purchase" | Dialog dismisses | |
| C.2 | Wait < 3 seconds | Green "Welcome to Pro!" snackbar appears | |
| C.3 | Paywall auto-dismisses | Returns to previous screen | |
| C.4 | Floating robot | Active (bobbing animation) | |
| C.5 | Settings → AI banner | Green "💎 Blinking Pro — Lifetime" | |
| C.6 | **NO debug SnackBar** | No "Purchase returned: info=..." message | |

**Why important:** Before the fix, a debug SnackBar (`Purchase returned: info=..., isPro=..., error=none`) appeared for 5 seconds after every purchase. Unprofessional and could confuse the reviewer.

---

## UAT-D: Cancel Purchase (Clean Return)

| # | Step | Expected | ✅ |
|---|------|----------|----|
| D.1 | Debug toggle to restricted → Paywall → Get Pro | Test Store dialog appears | |
| D.2 | Tap "Cancel" on system dialog | Returns to paywall | |
| D.3 | **Spinner disappears** | Button returns to "Get Pro — $19.99" | |
| D.4 | **Button is tappable again** | Can tap "Get Pro" again | |
| D.5 | **NO error snackbar** | No red/orange error message shown | |

**Why important:** Before the fix, cancellation used fragile string matching (`msg.contains('cancelled')`) which could fail with iOS 26's localized strings. Now uses `PlatformException` code matching.

---

## UAT-E: Restore Purchases

| # | Step | Expected | ✅ |
|---|------|----------|----|
| E.1 | Debug toggle to restricted → Paywall → Restore Purchases | "Restore Purchases" text shows **spinner** | |
| E.2 | Restore button | **Disabled** during restore | |
| E.3 | "Get Pro" button | **Disabled** during restore | |
| E.4 | Restore completes | Green "Pro restored." snackbar | |
| E.5 | Paywall dismisses | Returns to previous screen | |
| E.6 | Tap restore with no prior purchase | "No previous Pro purchase found." snackbar | |
| E.7 | After no-purchase message | **Button returns to tappable** state | |

---

## UAT-F: iPad Compatibility

| # | Step | Expected | ✅ |
|---|------|----------|----|
| F.1 | Launch on iPad Air 11" (M4) simulator | Layout fits, no overflow | |
| F.2 | Paywall in portrait | Complete scrollable, all content visible | |
| F.3 | Paywall in landscape | Buttons stretch full width, no truncation | |
| F.4 | Get Pro button | At least 44x52pt touch target (Apple HIG) | |
| F.5 | System purchase dialog appears | Full IAP sheet, not clipped | |
| F.6 | Purchase completes | Same flow as iPhone UAT-B + UAT-C | |

**Why important:** The rejection was specifically on iPad. Need to confirm layout works on the exact device model the reviewer used.

---

## UAT-G: Direct Store-Not-Ready Check (Regression)

| # | Step | Expected | ✅ |
|---|------|----------|----|
| G.1 | Build WITHOUT RC_API_KEY | App builds (flutter build debug without key) | |
| G.2 | Launch → onboarding → paywall | Paywall appears | |
| G.3 | **"Store unavailable" orange message visible** | Text below Get Pro button: "Store unavailable, please try again later" | |
| G.4 | "Get Pro" button | Greyed out (disabled) | |
| G.5 | "Restore Purchases" button | Greyed out (disabled) | |

**Why important:** If the build config is ever broken again, the problem is now visible BEFORE the user taps. The reviewer would see an orange message instead of tapping a seemingly-broken button.

---

## Quick Reference

| Action | How |
|--------|-----|
| Force restricted | Settings → About → tap version 5x |
| Reset to preview | Settings → About → tap version 5x again |
| Reinstall app | `xcrun simctl uninstall booted com.blinking.blinking && xcrun simctl install booted build/ios/iphonesimulator/Runner.app` |
| Switch to iPad | `xcrun simctl boot "iPad Air 11-inch (M4)" && open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app` |
