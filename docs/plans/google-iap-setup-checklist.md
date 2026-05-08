# Google Play IAP Setup — Checklist & Verification

**Date:** 2026-05-08 | **Version:** 1.1.0-beta.8+28 | **Status:** ✅ Verified (Google Play purchase tested + refund + re-purchase)

---

## Overview

| Component | Status |
|-----------|--------|
| Google Play Console: Product `blinking_pro` | ✅ Created |
| Google Play Console: Service Account | ✅ Created |
| Google Play Console: License Testing | ⬜ Pending |
| RevenueCat: Google Play Connected | ✅ |
| RevenueCat: Entitlement `pro_access` + Product | ✅ |
| RevenueCat: Offering `ofrng88832e4ac2` (Current) | ✅ |
| App Build: BILLING permission | ✅ |
| App Build: AAB v26 with `goog_` key | ✅ |
| App Build: APK v26 for sideload (won't work for IAP) | ✅ |
| Internal Testing: AAB upload | ⬜ |

---

## Step-by-Step Checklist

### Step 1: Google Play Console — Product

| # | Check | Value | ✅ |
|---|-------|-------|----|
| 1.1 | Product ID | `blinking_pro` | |
| 1.2 | Type | Non-consumable (one-time) | |
| 1.3 | Status | Active | |
| 1.4 | Price | $19.99 USD | |
| 1.5 | Title (English) | `Blinking Pro` | |
| 1.6 | Description (English) | `Full access for life. AI, habits, backup.` | |
| 1.7 | Title (Chinese) | `Blinking Pro 终身版` | |
| 1.8 | Description (Chinese) | `终身解锁全部功能。AI、习惯、备份。` | |

### Step 2: Google Play Console — Service Account

| # | Check | Value | ✅ |
|---|-------|-------|----|
| 2.1 | Service Account Email | (in JSON file) | |
| 2.2 | JSON Key File | `project-66cfef04-ded9-4b8b-8a2-2b989a0c9a21.json` | |
| 2.3 | Google Cloud Pub/Sub API | Enabled | |
| 2.4 | Play Console: View financial data | Granted | |
| 2.5 | Play Console: Manage orders | Granted | |

### Step 3: RevenueCat — Google Play Connection

| # | Check | Value | ✅ |
|---|-------|-------|----|
| 3.1 | Apps & Providers → Google Play | Connected, green status | |
| 3.2 | Package Name | `com.blinking.blinking` | |
| 3.3 | Service Credentials JSON | Uploaded (file from Step 2.2) | |
| 3.4 | API Key (`goog_`) | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` | |
| 3.5 | Save button | Clicked and saved (not blue) | |

### Step 4: RevenueCat — Product, Entitlement, Offering

| # | Check | Value | ✅ |
|---|-------|-------|----|
| 4.1 | Product: `blinking_pro` (Google Play) | Imported, Active | |
| 4.2 | Entitlement: `pro_access` | Linked to `blinking_pro` | |
| 4.3 | Offering: `ofrng88832e4ac2` | Set as Current (green badge) | |
| 4.4 | Offering package | Contains `blinking_pro` (Google Play) | |
| 4.5 | Verify: entitlements, product, offering, app are linked | All three connected correctly | |

### Step 5: App Build

| # | Check | Value | ✅ |
|---|-------|-------|----|
| 5.1 | AndroidManifest BILLING permission | `com.android.vending.BILLING` present | |
| 5.2 | Build key: `--dart-define=RC_API_KEY=` | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` | |
| 5.3 | Trial AI key: `--dart-define=TRIAL_API_KEY=` | `sk-or-v1-e902497ff...` | |
| 5.4 | Pro AI key: `--dart-define=PRO_API_KEY=` | `sk-or-v1-e75d7a22513...` | |
| 5.5 | AAB built | `build/app/outputs/bundle/release/app-release.aab` (49.9MB) | |
| 5.6 | Version | `1.1.0-beta.8+26` | |
| 5.7 | APK for test (sideload won't work for IAP) | Built, but use Play Store install | |

### Step 6: Internal Testing

| # | Check | Status | ✅ |
|---|-------|--------|----|
| 6.1 | Upload AAB to Internal Testing | ✅ | |
| 6.2 | Create new release (v27) | ✅ | |
| 6.3 | Assign `blinking_pro` to release | ✅ | |
| 6.4 | Rollout to Internal Testing | ✅ | |
| 6.5 | Setup → License testing → add tester Google account | ✅ | |
| 6.6 | Install from Play Store internal link | ✅ | |
| 6.7 | Open app → complete onboarding | ✅ | |
| 6.8 | Settings → tap version 5x → forced restricted | ✅ | |
| 6.9 | Tap robot → paywall → Get Pro | ✅ | |
| 6.10 | Google Play purchase dialog appears | ✅ | |
| 6.11 | Complete test purchase → "Welcome to Pro!" | ✅ | |
| 6.12 | Refund test purchase → re-purchase verified | ✅ | |
| 6.13 | RevenueCat → Customers → verify transaction | ✅ | |

---

## All Credentials (Master Reference)

### Google Play Console
| Item | Value |
|------|-------|
| App Package Name | `com.blinking.blinking` |
| Product ID | `blinking_pro` |
| Price | $19.99 USD |
| Service Account JSON | `project-66cfef04-ded9-4b8b-8a2-2b989a0c9a21.json` |

### RevenueCat
| Item | Value |
|------|-------|
| Project | Blinking |
| Google API Key | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` |
| Apple API Key | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` |
| Test Store Key | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` |
| Entitlement | `pro_access` |
| Product | `blinking_pro` |
| Offering (Current) | `ofrng88832e4ac2` |

### AI Keys (dart-define)
| Key | Value |
|-----|-------|
| TRIAL_API_KEY | (see password manager) |
| PRO_API_KEY | (see password manager) |

### Build Command
```bash
flutter build appbundle --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=TRIAL_API_KEY=<trial_key> \
  --dart-define=PRO_API_KEY=<pro_key>
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Not configured for billing" | Sideloaded APK | Must install from Play Store |
| "No offerings — credentials incomplete" | RevenueCat save failed | Re-enter all fields, click Save |
| "Product blinking_pro not found" | Key mismatch | Verify `goog_` key in build matches RevenueCat |
| Purchase dialog doesn't appear | License test not enabled | Add tester in Play Console → License testing |
| "Welcome to Pro!" but state unchanged | Entitlement not synced | Tap Restore Purchases |
