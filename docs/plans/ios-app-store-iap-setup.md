# iOS App Store IAP Setup Guide — Blinking Pro ($9.99)

**Date:** 2026-05-06 | **Status:** In Progress

Complete step-by-step for setting up `blinking_pro` on Apple App Store Connect and connecting it to RevenueCat for production.

---

## Prerequisites

- Apple Developer account ($99/year)
- Access to [App Store Connect](https://appstoreconnect.apple.com)
- The app must already exist in App Store Connect (yours does — iOS App Store submission is done)

---

## Step 1: App Store Connect — Create the In-App Purchase

### 1.1 Navigate to In-App Purchases

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **Apps** → select **Blinking** (or your app)
3. In the left sidebar under **General**, click **In-App Purchases**

### 1.2 Create Non-Consumable

1. Click the **+** button (top right next to "In-App Purchases")
2. Select **Non-Consumable** (one-time purchase, not a subscription)
3. Fill in:

| Field | Value |
|-------|-------|
| **Reference Name** | `Blinking Pro` (internal only, not shown to users) |
| **Product ID** | `blinking_pro` (must match exactly what's in RevenueCat and code) |

4. Click **Create**

### 1.3 Configure Pricing

1. Under **Pricing and Availability**, set price:
   - **Price:** `$9.99` (Tier 12 in older UI, or type it in new UI)
   - Country/Region: leave default (all available)
2. Click **Save**

### 1.4 Configure Display Information

Under **App Store Promotion** (or similar section), set the display text shown in the purchase sheet:

| Locale | Display Name | Description |
|--------|-------------|-------------|
| English (U.S.) | `Blinking Pro` | `Unlock all features for life — one-time purchase. Full journal editing, unlimited AI reflections, habit management, backup & restore.` |
| Chinese (Simplified) | `Blinking Pro 终身版` | `一次性购买，终身解锁全部功能。完整笔记编辑、无限AI对话、习惯管理、备份恢复。` |

3. Click **Save**

### 1.5 Submit for Review

- The IAP status will show **"Ready to Submit"**
- It will go live when you submit the app version that includes it
- You don't need to submit now — sandbox testing works before submission

---

## Step 2: App Store Connect — Get Credentials for RevenueCat

RevenueCat needs two things to connect your App Store:

### 2.1 App Store Connect API Key (In-App Purchase Key)

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Keys**
2. Click **+** to add a new key
3. Fill in:
   - **Key Name:** `Blinking RevenueCat`
   - **Access:** select **In-App Purchase**
4. Click **Generate**
5. **Download the .p8 file** immediately (you only get one chance)
6. Also note:
   - **Issuer ID** — shown at the top of the Keys page (a UUID like `69a6de70-f0c5-...`)
   - **Key ID** — shown in the key row (like `ABC1234567`)
   - **.p8 file** — the downloaded private key file

### 2.2 App-Specific Shared Secret

1. Go to **Apps** → select your app → **App Information** (under General)
2. Scroll down to **App-Specific Shared Secret**
3. Click **Manage** → **Generate** if none exists
4. Copy the 32-character hexadecimal string

---

## Step 3: RevenueCat — Connect Apple App Store

### 3.1 Add Apple App Store Configuration

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Select your project **Blinking**
3. In the left sidebar: **Apps & Providers** (or **Project Settings → Apps**)
4. Click **+ New** → select **App Store**

### 3.2 Fill in Configuration

| Field | Where to Find It | Value |
|-------|-----------------|-------|
| **App Name** | Any name for your reference | `Blinking iOS` |
| **Bundle ID** | App Store Connect → App → General → Bundle ID | `com.blinking.blinking` |
| **Shared Secret** | App Store Connect → App → App Information → App-Specific Shared Secret | From Step 2.2 |
| **In-App Purchase Key** | RevenueCat needs the key files | See below |

### 3.3 Upload In-App Purchase Key

There are two ways. Use whichever RevenueCat's UI offers:

**Option A — Upload .p8 directly:**
1. In the "In-App Purchase Key" section, fill in:
   - **Key ID** (from Step 2.1)
   - **Issuer ID** (from Step 2.1)
   - Upload the **.p8 file** you downloaded

**Option B — App Store Connect API Key (alternate method):**
1. RevenueCat may ask for an "App Store Connect API Key" instead
2. This is the same as Step 2.1 — upload the same .p8 with Issuer ID + Key ID

### 3.4 Save

Click **Save** / **Add**. RevenueCat will validate the connection.

### 3.5 Get the Production API Key

After connecting:
1. Go to **Project Settings → API Keys**
2. You should now see a key starting with `appl_` — this is your **production Apple API key**
3. This replaces the `test_` key for release builds

---

## Step 4: Verify Connection

### 4.1 Import Products

1. RevenueCat → **Products**
2. Click **Import from App Store**
3. Select `blinking_pro` from the list
4. Attach it to the `pro_access` entitlement

### 4.2 Check Entitlement Linking

1. RevenueCat → **Entitlements** → `pro_access`
2. Under **Products**, verify `blinking_pro` is attached
3. Under **Offerings** → `ofrng88832e4ac2`, verify the product is in a package

---

## Step 5: Sandbox Testing

### 5.1 Create Sandbox Tester

1. App Store Connect → **Users and Access** → **Sandbox Testers**
2. Click **+** → fill in a test account:
   - Email: something real but not your Apple ID (e.g., `blinking.tester@gmail.com`)
   - Password: any password
   - Name: `Test User`
   - Territory: United States
3. Click **Save**

### 5.2 Sign Into Sandbox on Device

1. On your iPhone/simulator: **Settings → App Store → Sandbox Account**
2. Sign in with the sandbox tester email/password created above

### 5.3 Update App to Use Production Key

```bash
# Build with production Apple key
flutter run -d "iPhone 17 Pro" --debug --dart-define=RC_API_KEY=appl_YOUR_KEY
```

### 5.4 Test Purchase

1. Open the app → trigger paywall (debug toggle or after preview expires)
2. Tap **Get Pro — $9.99**
3. Native Apple purchase sheet appears with **[Environment: Sandbox]** label
4. Sign in with sandbox account if prompted
5. Confirm purchase → "Welcome to Pro!" snackbar
6. No real charge is made

### 5.5 Verify in RevenueCat

1. RevenueCat → **Customers** → search for the sandbox user
2. Should show `pro_access` as active
3. Transaction should appear

---

## Step 6: Submit for App Review

Once IAP works in sandbox:

1. App Store Connect → Your App → prepare a new version
2. Under **In-App Purchases**, select `blinking_pro` to include it
3. **App Review Information** tab → check `blinking_pro` under "In-App Purchase Information"
4. Submit for review

Apple will test the purchase flow with their own sandbox account during review.

---

## Quick Reference — IDs and Keys

| Item | Value |
|------|-------|
| App Bundle ID | `com.blinking.blinking` |
| IAP Product ID | `blinking_pro` |
| RevenueCat Entitlement ID | `pro_access` |
| RevenueCat Offering REST ID | `ofrng88832e4ac2` |
| RevenueCat Test Key | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` |
| Production Apple Key | TBD (starts with `appl_`) |
| Production Google Key | TBD (starts with `goog_`) |

## Build Commands

```bash
# Development (Test Store)
flutter run -d "iPhone 17 Pro" --debug

# Development (with production Apple key + sandbox)
flutter run -d "iPhone 17 Pro" --debug --dart-define=RC_API_KEY=appl_...

# Production build
flutter build ipa --release --dart-define=RC_API_KEY=appl_...
```
