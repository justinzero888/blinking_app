# Blinking Pro IAP — TestFlight Setup & UAT Guide

**Date:** 2026-05-07 | **Version:** 1.1.0-beta.8+24

---

## Architecture Overview

```
iPhone (TestFlight)
    └── Blinking App
          └── PurchasesService (appl_vgTGaiNtCARgmdgOzpJcZyITNAT)
                └── RevenueCat SDK
                      └── RevenueCat Server
                            ├── fetches products from App Store Connect
                            ├── validates receipts
                            └── returns CustomerInfo (entitlements)

App Store Connect                              RevenueCat Dashboard
├── Blinking App ✓                             ├── Product: blinking_pro (iOS) → Ready to Submit
├── IAP: blinking_pro → Ready to Submit        ├── Entitlement: pro_access
├── Sandbox Tester: blinking.tester@...        ├── Offering: ofrng88832e4ac2 (Current)
├── App-Specific Shared Secret ✓               ├── App Store Connected ✓
└── In-App Purchase Key: 4UK6U499RC ✓          └── API Key: appl_vgTGaiNtCARgmdgOzpJcZyITNAT
```

---

## Prerequisites Checklist

| # | Item | Status |
|---|------|--------|
| 1 | App Store Connect: `blinking_pro` IAP created (Non-Consumable, $19.99) | ✅ |
| 2 | App Store Connect: IAP status "Ready to Submit" (green) | ✅ |
| 3 | App Store Connect: Pricing $19.99 set | ✅ |
| 4 | App Store Connect: Localization EN + ZH with Display Name + Description | ✅ |
| 5 | App Store Connect: App-Specific Shared Secret | ✅ |
| 6 | App Store Connect: In-App Purchase API Key (4UK6U499RC) | ✅ |
| 7 | App Store Connect: Sandbox Tester created | ⬜ |
| 8 | RevenueCat: App Store connected with credentials | ⬜ Need to confirm save |
| 9 | RevenueCat: Product `blinking_pro` (iOS) → attached to `pro_access` | ✅ |
| 10 | RevenueCat: Offering `ofrng88832e4ac2` set as Current | ✅ |
| 11 | RevenueCat: Product in offering package | ⬜ Verify iOS version only |
| 12 | TestFlight: Build uploaded (v1.1.0-beta.8+24) | ✅ |
| 13 | TestFlight: Build processed and available | ⬜ Wait 20-30min |

---

## Step 1: Complete RevenueCat Configuration

### 1.1 Verify App Store Connection

1. Go to [app.revenuecat.com](https://app.revenuecat.com) → your Blinking project
2. **Apps & Providers** → click your iOS app entry
3. Verify all fields and save (blue button may require clicking outside field first):
   - Bundle ID: `com.blinking.blinking`
   - Key ID: `4UK6U499RC`
   - Issuer ID: `8525f01e-0925-49f8-9862-739031df8d50`
   - Shared Secret: `cb7d69f2d98245de95e9eab7b4e0bbaf`
   - .p8 file: `AuthKey_4UK6U499RC.p8` uploaded

### 1.2 Verify Product & Offering

1. **Products** → `blinking_pro` (iOS) → Status: Ready to Submit
2. **Offerings** → `ofrng88832e4ac2` → verify:
   - Marked as **Current** (green badge)
   - Package contains only the **iOS** `blinking_pro` (not Test Store)
3. **Entitlements** → `pro_access` → Products → `blinking_pro` attached

---

## Step 2: Create Sandbox Tester

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Users and Access** (top menu)
3. **Sandbox Testers** tab
4. Click **+** and fill in:
   - Email: `blinking.tester@gmail.com` (or any real email NOT your Apple ID)
   - Password: `BlinkTest123!` (meet Apple's complexity rules)
   - First/Last Name: any
   - Territory: United States
   - Date of Birth: any (must be ≥18)
5. Click **Save**
6. Check your email — Apple sends a verification email to the tester address

---

## Step 3: Configure Test Device

### On your iPhone:

1. **Settings → [Your Name] → Media & Purchases → Sign Out**
2. **Settings → App Store → Sandbox Account**
   - If you see "Sandbox Account" option: enter tester email + password
   - If you don't: restart the phone, reinstall TestFlight app, then check again

**How to check if sandbox is active:**
- Open any Apple app (App Store, Music)
- Try to buy something — should show "Environment: Sandbox" in the purchase dialog

---

## Step 4: Install & Test

### 4.1 Install from TestFlight

1. Open TestFlight on iPhone
2. Install the latest Blinking build (v1.1.0-beta.8+24)
3. Wait for install to complete

### 4.2 Navigate to Paywall

The app starts in 21-day preview. To test purchase without waiting:

1. Complete 3-page onboarding (or skip by skipping through)
2. Go to **Settings**
3. Scroll to About section → tap **"Version 1.1.0-beta.8"** 5 times quickly
4. Snackbar: "Debug: Switched to restricted mode"
5. Tap the floating robot 🤖 (bottom right)
6. **Paywall appears** showing "$19.99" with "Get Pro" button

### 4.3 Execute Test Purchase

1. Tap **Get Pro — $19.99**
2. Native Apple purchase sheet appears with **[Environment: Sandbox]** label
3. Sign in with sandbox tester credentials if prompted
4. Confirm purchase (no real charge)
5. Expected: **"Welcome to Pro!"** green snackbar
6. Paywall dismisses → Settings shows **"💎 Blinking Pro — Lifetime"**
7. Floating robot becomes active (bobbing)

### 4.4 Test Restore Purchases

1. Delete and reinstall app from TestFlight
2. Go to paywall via debug toggle
3. Tap **Restore Purchases**
4. Expected: **"Pro restored."** green snackbar

---

## Step 5: Verify in RevenueCat

After test purchase:

1. RevenueCat → **Customers**
2. Search by App User ID (check logs or console)
3. Or look for recent transaction in **Overview** / **Sandbox** tab
4. Should show `pro_access` entitlement as ACTIVE
5. Revenue: $0 (sandbox, no real charge)

---

## Step 6: App Review Preparation

Before submitting for App Review:

1. **App Store Connect → Blinking → In-App Purchases** → `blinking_pro`
   - Status: Ready to Submit ✅
   - Add review screenshot if still marked missing

2. **App Store Connect → Blinking → Prepare for Submission**
   - Under "In-App Purchases", select `blinking_pro`
   - Under "App Review Information", mention sandbox tester credentials

3. **Submit for Review**

---

## UAT Test Cases

### UAT-1: First-Time Purchase

| # | Step | Expected | Result |
|---|------|----------|--------|
| 1.1 | Install app from TestFlight | 3-page onboarding appears | |
| 1.2 | Complete onboarding | Main app opens with blue preview banner | |
| 1.3 | Settings → tap version 5x | Snackbar: "Debug: Switched to restricted mode" | |
| 1.4 | Tap floating robot | Paywall appears with $19.99 price | |
| 1.5 | Tap "Get Pro" | Native purchase sheet with [Environment: Sandbox] | |
| 1.6 | Confirm purchase | "Welcome to Pro!" snackbar | |
| 1.7 | Paywall dismisses | Returns to previous screen | |
| 1.8 | Settings → AI section | Green "Blinking Pro — Lifetime" banner | |
| 1.9 | "Get Blinking Pro" button | Gone | |
| 1.10 | Floating robot | Active (bobbing), tap opens AI assistant | |
| 1.11 | AI assistant | Can send message and get response (pro key) | |

### UAT-2: Restore Purchases

| # | Step | Expected | Result |
|---|------|----------|--------|
| 2.1 | Delete app, reinstall from TestFlight | Fresh install | |
| 2.2 | Go to paywall (debug toggle) | Paywall appears | |
| 2.3 | Tap "Restore Purchases" | "Pro restored." snackbar | |
| 2.4 | Settings → AI | Green Pro banner | |

### UAT-3: Error Handling

| # | Step | Expected | Result |
|---|------|----------|--------|
| 3.1 | Tap "Cancel" on purchase sheet | Returns to paywall, no error | |
| 3.2 | Without sandbox account signed in | Purchase shows Apple login prompt | |
| 3.3 | Tap "Restore" without prior purchase | "No previous Pro purchase found." | |

### UAT-4: Post-Purchase Access

| # | Step | Expected | Result |
|---|------|----------|--------|
| 4.1 | Add a habit | Should work (was blocked in restricted) | |
| 4.2 | Edit a habit | Should work | |
| 4.3 | Backup | Should work | |
| 4.4 | AI assistant | Works, uses pro key | |

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "blinking_pro not found" | Offering not Current, or product not in offering | RevenueCat: verify offering has iOS product, set as Current |
| Purchase sheet doesn't appear | Sandbox account not signed in | Settings → App Store → Sandbox account |
| Purchase fails with error | IAP metadata incomplete | App Store Connect: verify all IAP fields filled |
| "Welcome to Pro!" but state unchanged | EntitlementService not updated | Tap Restore Purchases, wait 30s, try again |
| TestFlight build shows "Processing" | Apple reviewing build | Wait 20-30min |
