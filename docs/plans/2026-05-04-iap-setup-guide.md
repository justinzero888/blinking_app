# IAP Setup Guide — Blinking Pro ($9.99)

**Created:** 2026-05-04  
**Status:** Human action required  
**Est. time:** ~2h (one-time setup)

---

## Overview

Blinking Pro is a **one-time, non-consumable** in-app purchase at **$9.99 USD**. The product ID is `blinking_pro`. RevenueCat handles the StoreKit/Play Billing integration. Server validates receipts and transitions entitlement state to PAID.

---

## Step 1: RevenueCat Setup (~30min)

### 1.1 Create RevenueCat Project

1. Go to [app.revenuecat.com](https://app.revenuecat.com)
2. Create project: **"Blinking"**
3. Every new project comes with a **Test Store** and a pre-generated `test_` API key.
   - Find it at: **Project Settings → API Keys** (the key that starts with `test_`)
   - This key works immediately for development/testing without any store credentials.
   - It is already configured in `lib/main.dart` via the `RC_API_KEY` environment variable.

### 1.2 Add Blinking Pro (Test Products)

1. RevenueCat → **Products** → **+ New**
2. In the Test Store section, add product:
   - ID: `blinking_pro`
   - Type: **Non-consumable**
   - Price: $9.99
3. Create **Entitlement** → ID: `pro_access` → attach `blinking_pro`

### 1.3 Connect Platform Stores (for production keys)

For real `appl_` / `goog_` keys, you must add store configurations under **Apps & Providers**:

**iOS (requires App Store Connect setup first):**
1. Apps & Providers → **+ New** → **App Store**
2. Enter Bundle ID: `com.blinking.blinking`
3. Requires: App Store Connect Shared Secret + In-App Purchase Key
4. After saving, the `appl_` key appears under Project Settings → API Keys

**Android (requires Google Play Console setup first):**
1. Apps & Providers → **+ New** → **Google Play**
2. Enter Package Name: `com.blinking.blinking`
3. Upload: Google Play Service Credentials JSON
4. After saving, the `goog_` key appears under Project Settings → API Keys

### 1.4 Switch to Production Keys (before launch)

When ready for production, set the platform keys via environment variable:

```bash
flutter build appbundle --release --dart-define=RC_API_KEY=goog_YOUR_KEY
```

Or update the default in `lib/main.dart` from the `test_` key to the production `appl_`/`goog_` key.

Or add after provider tree in `app.dart`:

```dart
ChangeNotifierProvider(create: (_) {
  final service = PurchasesService();
  service.init(
    appleApiKey: 'appl_xxx',
    googleApiKey: 'goog_xxx',
  );
  return service;
}),
```

---

## Step 2: App Store Connect Setup (~45min)

### 2.1 Create the In-App Purchase

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app → **In-App Purchases** tab
3. Click **+** → **Non-Consumable**
4. Reference Name: `Blinking Pro`
5. Product ID: `blinking_pro`
6. Price: **$9.99** (Tier 12)
7. Display Name (EN): `Blinking Pro`
8. Display Name (ZH): `Blinking Pro 终身版`
9. Description (EN): `Unlock all features for life. Includes 1,200 AI reflections per year, full habit management, backup & restore, and Share to Chorus.`
10. Description (ZH): `终身解锁全部功能。包含每年 1,200 次 AI 对话、完整习惯管理、跨设备备份恢复、分享至 Chorus。`
11. **Save**

### 2.2 Add App Store Screenshot

- Upload a promotional image (1024×1024) for the IAP
- Required before submission

### 2.3 Add to App Review Information

1. Go to App Store Connect → Your App → **App Review** tab
2. Under "In-App Purchase Information", check `blinking_pro`

### 2.4 Enable Family Sharing

1. RevenueCat → Products → `blinking_pro` → iOS → **Advanced**
2. Enable "Family Sharing"

### 2.5 Sandbox Testing

1. App Store Connect → **Users and Access** → **Sandbox Testers**
2. Create test account: `blinking.tester@example.com`
3. On device: Settings → App Store → Sandbox Account → sign in with test account
4. Test purchase with `blinking_pro` — no real charge

---

## Step 3: Google Play Console Setup (~30min)

### 3.1 Create the In-App Product

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app → **Monetize** → **Products** → **In-app products**
3. Click **Create product**
4. Product ID: `blinking_pro`
5. Title (EN): `Blinking Pro`
6. Title (ZH): `Blinking Pro 终身版`
7. Description (EN): `Unlock all features for life — one-time purchase. Includes 1,200 AI reflections/year, full habit management, backup & restore.`
8. Description (ZH): `一次性购买，终身解锁全部功能。每年 1,200 次 AI 对话、完整习惯管理、跨设备备份恢复。`
9. Price: **$9.99** (select from price templates)
10. Status: **Active**
11. **Save**

### 3.2 Enable for Testing

1. Go to **Grow** → **Store presence** → **Pricing & distribution**
2. Ensure app is available in all territories you want to sell in
3. Create a **License Testing** account for purchase testing:
   - Play Console → **Setup** → **License testing**
   - Add test Google accounts

### 3.3 Test Purchase

1. On test device, sign in with license testing Google account
2. Install app from Play Store or Test Track
3. Purchase `blinking_pro` — no real charge for test accounts

---

## Step 4: Server Setup (~10min)

### 4.1 Deploy Migrations

```bash
cd /Users/justinzero/ClaudeDev/chorus/chorus-api

# Create entitlements table
npx wrangler d1 execute blinking-chorus-v0 --remote --file=migrations/0010_entitlements.sql

# Create receipts table
npx wrangler d1 execute blinking-chorus-v0 --remote --file=migrations/0011_receipts.sql
```

### 4.2 Set Secrets

```bash
# Generate a random JWT secret (save this securely)
npx wrangler secret put JWT_SECRET
# Enter: a random 64-char string, e.g. output of `openssl rand -hex 32`

# Enable the entitlement feature
npx wrangler secret put ENTITLEMENT_ENABLED
# Enter: true
```

### 4.3 Deploy

```bash
npm run deploy
```

### 4.4 Verify

```bash
# Health check
curl https://blinkingchorus.com/api/v1/health

# Entitlement init
curl -X POST https://blinkingchorus.com/api/entitlement/init \
  -H "Content-Type: application/json" \
  -d '{"device_id":"test-12345678"}'
# Should return: { "token": "...", "state": "preview", ... }

# Admin still works
curl https://blinkingchorus.com/api/v1/admin/queue
```

---

## Step 5: End-to-End Test Flow

1. Fresh install app → PREVIEW auto-starts (21 days, 9 AI/day)
2. After 21 days OR manually transition to RESTRICTED
3. Tap floating robot (dormant) → Paywall opens
4. OR Settings → AI → "Get Blinking Pro" → Paywall opens
5. Tap **"Get Pro — $9.99"** → Apple/Google native payment sheet appears
6. Complete purchase with test account → **"Welcome to Pro!"** toast
7. Check Settings → AI: entitlement state should show PAID
8. Check AI quota: 1,200/year
9. Tap **"Restore Purchases"** on another device → **"Pro restored."**
10. Uninstall → reinstall → Restore Purchases → Pro restored

---

## Pricing Summary

| Product | ID | Type | Price |
|---------|----|------|:-----:|
| Blinking Pro | `blinking_pro` | Non-consumable | $9.99 |
| AI Top-up (future) | `blinking_topup_500` | Consumable | $4.99 |

Both platforms: standard 15-30% revenue share to Apple/Google.

---

## Files Reference

| File | Purpose |
|------|---------|
| `lib/core/services/purchases_service.dart` | RevenueCat wrapper — init, purchase, restore |
| `lib/screens/purchase/paywall_screen.dart` | Paywall UI with Get Pro + Restore buttons |
| `lib/app.dart` | Provider tree — `PurchasesService` registered |
| `lib/core/services/entitlement_service.dart` | State machine synced from server |
| `src/routes/receipt.ts` | Server receipt validation + PAID transition |
| `src/routes/entitlement.ts` | Server entitlement state machine |
| `migrations/0010_entitlements.sql` | D1 entitlements table |
| `migrations/0011_receipts.sql` | D1 receipts table (deduplication) |
