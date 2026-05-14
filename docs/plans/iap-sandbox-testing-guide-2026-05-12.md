# Apple Sandbox IAP Testing — Setup & Flow

**Date:** 2026-05-12 | **Status:** Pending Paid Apps Agreement activation

---

## 1. What the Sandbox Is

Apple's sandbox is a parallel App Store environment. Purchases are free, no real money moves, but the full StoreKit flow runs — receipts, entitlements, restore. All IAP testing (your UAT and Apple's review) happens here.

The RevenueCat Test Store (what you see on simulator with `test_` key) is different — it's a RevenueCat-created fake store that bypasses Apple entirely. The production `appl_` key routes through Apple's sandbox when the app isn't from the App Store (i.e., TestFlight or Xcode builds).

---

## 2. Sandbox Apple ID

### Create

App Store Connect → Users and Access → Sandbox → Test Accounts → +

| Field | Value |
|-------|-------|
| First/Last Name | Any (not your real name) |
| Email | Must be valid, must NOT be an existing Apple ID |
| Password | At least 8 chars, upper + lower + number |
| Secret Q&A | Any |
| Date of Birth | Any adult |
| App Store Territory | United States |

**Active testers:**
- `blinking.tester@gmail.com` / `BlinkTest123!`
- `jz6417653+blinktest@gmail.com` / `CNMDeD0Go5l2!$`

### Use on Device (CRITICAL)

**This is the #1 mistake.** You cannot test with your real Apple ID.

1. Settings → tap your name at top → Sign Out
2. Settings → App Store → tap email → Sign In
3. **Use the sandbox email/password** — NOT your real Apple ID
4. Do NOT sign into iCloud with the sandbox account
5. Only sign into the App Store

When you open the app and trigger a purchase, Apple will show the sandbox password prompt — confirm with the sandbox password.

### Switching Back

Settings → App Store → Sign Out → Sign back in with real Apple ID.

**Important:** Do not merge sandbox account data with your real account. If prompted to "Merge", tap "Don't Merge".

---

## 3. What Happens During Sandbox Purchase

```
1. Paywall → Tap "Get Pro"
2. RevenueCat calls Purchases.purchasePackage(pkg)
3. RevenueCat → StoreKit → Apple sandbox IAP sheet appears
4. Sheet shows:
   ┌────────────────────────────────┐
   │  Blinking Pro                  │
   │  $19.99                        │
   │  [Environment: Sandbox]        │  ← orange badge
   │  ────────────────────────      │
   │  [Cancel]    [Buy]             │
   └────────────────────────────────┘
5. Tap Buy → sandbox password prompt
6. Purchase completes → StoreKit returns receipt
7. RevenueCat validates receipt with Apple (sandbox URL)
8. RevenueCat updates customerInfo.entitlements.active['pro_access']
9. App gets callback → "Welcome to Pro!"
```

The `[Environment: Sandbox]` badge is how you know you're in the right environment.

---

## 4. RevenueCat's Role

When you use the `appl_` production key in a TestFlight/Xcode build:

1. `Purchases.configure(appl_key)` → RC detects it's a sandbox build (not App Store-signed)
2. RC routes to Apple's sandbox receipt verification URL: `https://sandbox.itunes.apple.com/verifyReceipt`
3. RC fetches products from Apple's sandbox product catalog
4. If Paid Apps Agreement is NOT active → Apple returns empty catalog → RC has zero products → "No offerings"

Once the agreement is active, the catalog populates. `blinking_pro` shows up even in "Waiting for Review" state — sandbox products don't need approval.

---

## 5. Common Sandbox Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Signed in with real Apple ID | "This account is not valid for purchases" or subscription prompt | Sign out, use sandbox ID for App Store only |
| Signed into iCloud with sandbox ID | iCloud prompts, potential account lock | Do NOT sign into iCloud — only App Store |
| Sandbox account already used for purchase | "You've already purchased this" | No issue for non-consumable — just restore |
| Paid Apps Agreement not active | "No offerings from store" | Wait 24h for activation |
| Forgot to sign out before real purchase | Charges real money | Always check for `[Environment: Sandbox]` badge |
| RevenueCat sandbox dashboard empty | Transactions might take a few minutes | Check RevenueCat → Customers → Sandbox tab |
| Purchase seems to hang | First sandbox purchase can be slow | Wait 30 seconds; second purchase is fast |

---

## 6. Step-by-Step UAT Plan (After Agreement Active)

### Phase 1: Verify RC Can See Products (Build 33)

1. Upload 33 to TestFlight, install on device
2. Sign device App Store into sandbox Apple ID
3. Launch app, complete onboarding
4. Debug toggle to restricted (5-tap version)
5. Tap dormant robot → Paywall
6. **Read the error message:**

| If you see... | Next step |
|---------------|-----------|
| "No offerings from store" | Agreement not active yet. Wait. |
| "Product 'blinking_pro' not in offerings. Found: [...]" | Product ID mismatch. Check RC Products tab. |
| Store loads (no error, button enabled) | Proceed to Phase 2 |

### Phase 2: Purchase

7. Tap "Get Pro"
8. System IAP sheet appears with `[Environment: Sandbox]`
9. Tap Buy → enter sandbox password
10. "Welcome to Pro!" green snackbar
11. Paywall dismisses
12. Check RevenueCat → Customers → Sandbox: new transaction appears

### Phase 3: Restore

13. Debug toggle back to restricted
14. Tap robot → Paywall → Restore Purchases
15. "Pro restored." green snackbar

### Phase 4: Verify Server-Side (optional)

16. Check `blinkingchorus.com/api/entitlement/status` with the JWT from the purchase
17. Or check RevenueCat Dashboard → Customers → the sandbox transaction

---

## 7. Apple Review Testing

Apple's internal reviewers follow the same sandbox process. They have their own sandbox Apple IDs. The `[Environment: Sandbox]` badge is what they see too.

What the reviewer will test:
1. ✅ App launches → onboarding → main screen
2. ✅ Paywall appears after preview/restricted
3. ✅ IAP sheet appears on "Get Pro" tap
4. ✅ Purchase completes in sandbox
5. ✅ App recognizes purchase ("Welcome to Pro!")
6. ✅ Pro features unlock (AI, habits, backup, etc.)
7. ✅ Restore purchases works

If any step fails, they reject with the exact step that failed. Your rejection said step 4 ("unable to complete the purchase"), which was the missing RC_API_KEY.
