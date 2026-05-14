# IAP App Review — Configuration Audit

**Date:** 2026-05-12 | **Build:** 1.1.0+33 | **Purpose:** Verify every link in the purchase chain before resubmitting

---

## App Reviewer's Perspective (What Happens)

```
1. Reviewer installs app via TestFlight (same build, same binary)
2. Reviewer opens app → completes onboarding
3. Settings → AI → sees "21-Day Preview" banner
4. Reviewer switches to restricted mode (or preview expires)
5. Taps dormant robot → Paywall opens
6. Taps "Get Pro — $19.99"
7. System IAP sheet appears → reviewer enters sandbox Apple ID password
8. Purchase completes → "Welcome to Pro!" + paywall dismisses
9. Settings → AI shows green "Blinking Pro — Lifetime" banner
```

**The reviewer uses Apple's internal sandbox test environment — NOT the RevenueCat Test Store.**

---

## Parameter Map (Code → RevenueCat → Apple)

Every string the app checks and where it's configured:

```
                   CODE                          REVENUECAT DASHBOARD           APP STORE CONNECT
                   ────                          ───────────────────           ─────────────────

  rc_key ───────> "appl_vgTGaiNt..."  ──────>  Project Settings →            App Store Connect →
                                               API Keys (iOS Production)      Keys → In-App Purchase
                                                                              Key ID + Issuer + .p8

  offering ─────> _offerings.current  ───────>  Offerings → offering         (none)
                                               "Set as Current" checked

  product_id ───> "blinking_pro"      ───────>  Products → Store Product ID  Features → In-App Purchases
                                               (under App Store connection)  → Product ID: blinking_pro

  entitlement ──> "pro_access"        ───────>  Entitlements → Identifier    (none)
                                               Attached to blinking_pro

  bundle_id ────> com.blinking.blinking ─────>  App Settings (iOS)           App Information
                                               Bundle ID must match
```

---

## Checklist A: RevenueCat Dashboard

**Login:** https://app.revenuecat.com → Project "Blinking"

### A.1 — App Store Connection (Apps & Providers)

| # | Item | Expected | Source |
|---|------|----------|--------|
| A.1a | App Store connection exists | "App Store" tile visible under Apps & Providers | User check |
| A.1b | Bundle ID matches | `com.blinking.blinking` | User check |
| A.1c | In-App Purchase Key ID | `S7GU3FWWH5` | From setup doc |
| A.1d | Issuer ID | `8525f01e-0925-49f8-9862-739031df8d50` | From setup doc |
| A.1e | Private key (.p8) uploaded | AuthKey file uploaded | User check |
| A.1f | Connection status | Green "Active" or "Connected" | User check |

### A.2 — Entitlement (`pro_access`)

| # | Item | Expected | Source |
|---|------|----------|--------|
| A.2a | Entitlement exists | Name: `pro_access` | Entitlements tab |
| A.2b | Identifier | `pro_access` (exact string — code checks this) | Entitlements tab |
| A.2c | Attached to product | `blinking_pro` listed under this entitlement | Click entitlement |

### A.3 — Product (`blinking_pro`)

| # | Item | Expected | Source |
|---|------|----------|--------|
| A.3a | Product exists under App Store section | NOT under "Test Store" | Products tab |
| A.3b | Store Product ID | `blinking_pro` (exact string — code searches for this) | Products tab |
| A.3c | Type | Non-Consumable | Products tab |
| A.3d | Entitlement | Attached to `pro_access` | Products tab |
| A.3e | Price | Should display actual price (or placeholder) | Products tab |

### A.4 — Offering

| # | Item | Expected | Source |
|---|------|----------|--------|
| A.4a | Offering exists | Any name | Offerings tab |
| A.4b | Contains package | Package references `blinking_pro` product | Click offering |
| A.4c | "Current" flag | Marked as Current (green check or dot) | Offerings tab, ⋮ menu |

---

## Checklist B: App Store Connect

**Login:** https://appstoreconnect.apple.com → App "Blinking"

### B.1 — Agreements

| # | Item | Expected | Source |
|---|------|----------|--------|
| B.1a | Paid Apps Agreement | Status: "Active" | Agreements, Tax, Banking |
| B.1b | Free Apps Agreement | Status: "Active" | Agreements, Tax, Banking |

### B.2 — In-App Purchase Product

| # | Item | Expected | Source |
|---|------|----------|--------|
| B.2a | Product exists | Reference Name: any, Product ID: `blinking_pro` | Features → In-App Purchases |
| B.2b | Type | Non-Consumable | Product detail |
| B.2c | Price | $19.99 (Tier 20) | Product detail → Price Schedule |
| B.2d | Status | "Ready to Submit" | Product list |
| B.2e | Cleared for Sale | Yes | Product detail |
| B.2f | Review Screenshot | Uploaded (required for review) | Product detail → Review Screenshot |
| B.2g | Review Notes | Optional but recommended | Product detail → App Store Localization |

### B.3 — App Store Connect API Key (for RevenueCat)

| # | Item | Expected | Source |
|---|------|----------|--------|
| B.3a | Key exists | Name: any, Key ID matches RC setup (S7GU3FWWH5) | Users & Access → Keys |
| B.3b | Role | "In-App Purchase" or "App Manager" | Key detail |
| B.3c | .p8 file | Downloaded (was uploaded to RevenueCat) | Key detail |

### B.4 — Sandbox Tester (for your own UAT, not reviewer)

| # | Item | Expected | Source |
|---|------|----------|--------|
| B.4a | Sandbox tester exists | At least one test account | Users & Access → Sandbox Testers |
| B.4b | Tester email | Valid email (not tied to real Apple ID) | Sandbox Testers |
| B.4c | Used for TestFlight UAT | Signed into device Settings → App Store as sandbox account | Device Settings |

### B.5 — App Submission

| # | Item | Expected | Source |
|---|------|----------|--------|
| B.5a | App Store Review Information | Contact info, demo account if needed | App Store → App Review |
| B.5b | IAP attached to submission | `blinking_pro` selected when submitting | Submission page |
| B.5c | Export Compliance | Answered (encryption) | App Store → Export Compliance |
| B.5d | Content Rights | Answered | App Store → Content Rights |

---

## Checklist C: App Code Verification

These are verified. No action needed.

| # | Item | Value in Code | Verified |
|---|------|-------------|----------|
| C.1 | RC API key in build | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` via dart-define | ✅ Build script enforces |
| C.2 | Entitlement ID check | `'pro_access'` in `purchases_service.dart:24` | ✅ Code audit |
| C.3 | Product ID search | `'blinking_pro'` in `paywall_screen.dart:339` | ✅ Code audit |
| C.4 | `isPro` check | `entitlements.active.containsKey('pro_access')` | ✅ Code audit |
| C.5 | Offering fallback | Searches current → all offerings → first available | ✅ Code audit |
| C.6 | `purchases_flutter` version | `9.16.1` (≥ 9.8 required) | ✅ pubspec.yaml |

---

## Checklist D: TestFlight UAT Before Submission

| # | Step | Expected | ✅ |
|---|------|----------|----|
| D.1 | Install via TestFlight | App launches, no crash | |
| D.2 | Complete onboarding | Main screen appears | |
| D.3 | Debug toggle to restricted | Settings → About → 5-tap version → switch to restricted | |
| D.4 | Tap dormant robot → Paywall | Paywall opens | |
| D.5 | Check "Get Pro" button | **NOT** greyed out (Store is ready) | |
| D.6 | Check NO "Store unavailable" text | No orange warning below button | |
| D.7 | **Sign in with SANDBOX Apple ID** | Device Settings → App Store → sandbox account | |
| D.8 | Tap "Get Pro" | iOS purchase sheet appears (NOT "Test Store") | |
| D.9 | Confirm purchase | Apple asks for sandbox password | |
| D.10 | Purchase completes | "Welcome to Pro!" green snackbar | |
| D.11 | Paywall dismisses | Returns to previous screen | |
| D.12 | Settings → AI | Green "Blinking Pro — Lifetime" banner | |
| D.13 | Floating robot active | Bobbing animation | |
| D.14 | Restore test | Toggle restricted → paywall → Restore → "Pro restored." | |

---

## Error Diagnosis

Based on the diagnostic error message now in build 33:

| Error Shown | Meaning | Fix |
|-------------|---------|-----|
| "No offerings from store. Check: Paid Apps Agreement accepted?" | RC received zero products from Apple. Either Agreement not active, or IAP not approved, or RC→Apple connection broken. | Checklist A.1 (App Store connection), B.1 (Paid Apps Agreement) |
| "Product 'blinking_pro' not in offerings. Found: [...]" | RC found products, but `blinking_pro` not among them. Product ID mismatch or product not imported into RC. | Checklist A.3 (Product ID matches) |
| "Store not ready, try again later" | RC not initialized at all. | RC_API_KEY missing or Purchases.configure failed |
| Spinner shows, then nothing happens | Purchase was cancelled or timed out | No issue (user cancelled) |
