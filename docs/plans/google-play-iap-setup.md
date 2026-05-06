# Google Play Console IAP Setup — Blinking Pro ($9.99)

**Date:** 2026-05-06 | **Status:** In Progress

---

## Step 1: Create the In-App Product

1. Go to [play.google.com/console](https://play.google.com/console)
2. Select the **Blinking** app
3. Left sidebar → **Monetize** → **Products** → **In-app products**
4. Click **Create product**
5. Fill in:

| Field | Value |
|-------|-------|
| **Product ID** | `blinking_pro` |
| **Type** | Non-consumable (one-time purchase) |
| **Status** | Active |
| **Title (English)** | `Blinking Pro` |
| **Description (English)** | `Unlock all features for life with a single purchase. Full journal editing, unlimited AI reflections, habit management, backup and restore.` |
| **Title (Chinese)** | `Blinking Pro 终身版` |
| **Description (Chinese)** | `一次性购买，终身解锁全部功能。完整笔记编辑、无限AI对话、习惯管理、备份恢复。` |
| **Price** | **9.99 USD** |

6. Click **Save**

---

## Step 2: Get Service Credentials for RevenueCat

### 2.1 Create Service Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Left sidebar → **Setup** → **Service accounts** (under Developer tools)
3. Click **Create new service account**
4. It opens Google Cloud Console in a new tab

### 2.2 In Google Cloud Console

1. **Service account name:** `Blinking RevenueCat`
2. Click **Create and Continue**
3. Under **Role**, search and select: **Play Android Developer → Service Account**
4. Click **Done**

### 2.3 Generate Key

1. Back on the Service Accounts page, click the newly created service account
2. Go to **Keys** tab → **Add Key** → **Create new key**
3. Choose **JSON** → **Create**
4. A .json file downloads automatically — save it, you need this for RevenueCat

### 2.4 Grant Permissions in Play Console (IMPORTANT)

1. Go back to Play Console → **Setup** → **Service accounts**
2. The new service account should appear in the list
3. Click **Grant access** next to it
4. Under **App permissions**, add the Blinking app
5. Under **Account permissions**, check:
   - **View financial data**
   - **Manage orders and subscriptions**
6. Click **Invite user** / **Save**

---

## Step 3: Connect to RevenueCat

1. [RevenueCat Dashboard](https://app.revenuecat.com) → your project
2. Left sidebar → **Apps & Providers** → **+ New** → **Google Play**
3. Fill in:

| Field | Value |
|-------|-------|
| **App Name** | `Blinking Android` |
| **Package Name** | `com.blinking.blinking` |
| **Service Credentials** | Upload the .json file from Step 2.3 |

4. Click **Save**

---

## Step 4: Get Production Key & Test

1. RevenueCat → **Project Settings → API Keys** — you'll see `goog_...` appear
2. Import the product: RevenueCat → **Products** → **Import from Google Play** → select `blinking_pro`
3. Attach it to `pro_access` entitlement
4. Create a **license tester** in Play Console: **Setup → License testing** → add test Google accounts
5. Build and test:

```bash
flutter run --debug --dart-define=RC_API_KEY=goog_YOUR_KEY
```

---

## Quick Reference

| Item | Value |
|------|-------|
| App Package Name | `com.blinking.blinking` |
| IAP Product ID | `blinking_pro` |
| RevenueCat Key | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` |
