# iOS IAP Setup — Master Guide (Clean Slate)

**Date:** 2026-05-08 | **Version:** 1.1.0-beta.8+27

This guide assumes you are starting fresh. All previous attempts documented separately.

---

## Architecture — How Everything Connects

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Apple Developer Account                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ App Store Connect                                            │  │
│  │  ├── Blinking App (com.blinking.blinking)                    │  │
│  │  ├── IAP: blinking_pro ($19.99, Non-Consumable)             │  │
│  │  └── Sandbox Tester: blinking.tester@gmail.com               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Users and Access → Keys                                       │  │
│  │  └── In-App Purchase Key (.p8 file)                          │  │
│  │      ├── Key ID: S7GU3FWWH5                                  │  │
│  │      ├── Issuer ID: 8525f01e-0925-49f8-9862-739031df8d50    │  │
│  │      └── .p8: SubscriptionKey_S7GU3FWWH5.p8                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ App Information                                              │  │
│  │  └── App-Specific Shared Secret                              │  │
│  │      └── cb7d69f2d98245de95e9eab7b4e0bbaf                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ (RevenueCat reads from App Store Connect)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          RevenueCat                                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Apps & Providers → App Store                                  │  │
│  │  ├── Bundle ID: com.blinking.blinking                        │  │
│  │  ├── Shared Secret: (from App Store Connect)                 │  │
│  │  ├── In-App Purchase Key ID + Issuer ID + .p8                │  │
│  │  └── App Store Connect API Key ID + Issuer ID + .p8          │  │
│  │     (Both sections use the SAME key ID, .p8, and issuer)     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Products                                                     │  │
│  │  └── blinking_pro (imported from App Store or created)       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Entitlements                                                 │  │
│  │  └── pro_access ← attached to blinking_pro                   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Offerings                                                    │  │
│  │  └── ofrng88832e4ac2 (Current)                               │  │
│  │      └── Package containing blinking_pro                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ API Keys                                                     │  │
│  │  ├── appl_vgTGaiNtCARgmdgOzpJcZyITNAT (production)          │  │
│  │  └── test_FFZAekOZQXGwwReuLkrvQLTjyOP (test store)          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: App Store Connect — Verify Prerequisites

### 1.1 App Exists
- Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- Apps → **Blinking** — must exist with Bundle ID `com.blinking.blinding`

### 1.2 IAP Product
- Blinking → **In-App Purchases** → `blinking_pro`
- Status: **Ready to Submit** (green)
- Type: Non-Consumable
- Price: $19.99
- Localizations: EN + ZH (Display Name + Description filled)
- Review Screenshot: uploaded (1024×1024 PNG, optional but recommended)

### 1.3 Shared Secret
- Blinking → **App Information** (left sidebar) → scroll down
- **App-Specific Shared Secret** → if none exists, click **Manage → Generate**
- Value: `cb7d69f2d98245de95e9eab7b4e0bbaf` (copy/save this)

---

## Step 2: App Store Connect — Create In-App Purchase Key

### 2.1 Generate Key
1. Go to https://appstoreconnect.apple.com/access/integrations/api
2. Under **Individual Keys**, click **+**
3. **Name:** `Blinking IAP`
4. **Access:** Select **In-App Purchase**
   - If "In-App Purchase" not in dropdown, use **App Manager**
   - Do NOT use "Admin" — RevenueCat In-App Purchase section needs specific key type
5. Click **Generate**

### 2.2 Download & Record
1. **Download** the .p8 file immediately (one chance only)
2. Note the **Key ID** shown in the table (e.g., `ABC1234567`)
3. **Issuer ID** is at the top of the Keys page: `8525f01e-0925-49f8-9862-739031df8d50`
4. Save the .p8 to `~/Downloads/` — keep Apple's original filename (DO NOT RENAME)

### 2.3 Verify the Key File
- Open in TextEdit — should start with `-----BEGIN PRIVATE KEY-----`
- Filename should be `SubscriptionKey_XXXX.p8` or `AuthKey_XXXX.p8`
- Keep both the file and the original download

---

## Step 3: RevenueCat — Delete Old iOS App Entry (If Exists)

### Only do this if you're starting fresh:
1. RevenueCat → **Apps & Providers** → find iOS entry
2. Click ⋮ → **Delete**
3. Confirm deletion
4. This removes the broken connection; data is preserved in App Store Connect

---

## Step 4: RevenueCat — Create iOS App Connection

### 4.1 Add New App Store Entry
1. RevenueCat → **Apps & Providers** → **+ New** → **App Store**
2. Fill in:

### 4.2 Credentials Table

| Section | Field | Value |
|---------|-------|-------|
| **App Info** | App Name | `Blinking iOS` |
| **App Info** | Bundle ID | `com.blinking.blinking` |
| **App Info** | Shared Secret | `cb7d69f2d98245de95e9eab7b4e0bbaf` |
| **In-App Purchase Key** | Key ID | NEW_KEY_ID_FROM_STEP_2 |
| **In-App Purchase Key** | Issuer ID | `8525f01e-0925-49f8-9862-739031df8d50` |
| **In-App Purchase Key** | .p8 file | Upload the .p8 from Step 2 (original filename) |
| **App Store Connect API** | Key ID | SAME as In-App Purchase Key ID |
| **App Store Connect API** | Issuer ID | `8525f01e-0925-49f8-9862-739031df8d50` |
| **App Store Connect API** | .p8 file | SAME .p8 file |

### 4.3 CRITICAL: Clicking Save
- After filling ALL fields, click **outside** the last field you edited (on blank page area)
- Wait 2-3 seconds for RevenueCat to validate
- **Save Change** button should change from blue to clickable
- If button stays blue after 10 seconds:
  - Refresh page (F5)
  - Re-enter ALL fields from scratch
  - Try Chrome incognito or Safari

### 4.4 Verify Connection
1. RevenueCat → **Project Settings → API Keys**
2. Verify `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` appears (same key, generated once)
3. If Save worked, RevenueCat should now be able to fetch products

---

## Step 5: RevenueCat — Product Setup

### 5.1 Import Product (or Create)
1. RevenueCat → **Products → Import from App Store**
2. If `blinking_pro` appears → select it → **Import** → skip to 5.2
3. If NOT found → **+ New → App Store** → create manually:
   - Product ID: `blinking_pro`
   - Type: Non-Consumable
   - Price: $19.99

### 5.2 Attach to Everything
1. **Entitlements → `pro_access`** → attach `blinking_pro`
2. **Offerings → `ofrng88832e4ac2`** → verify it contains `blinking_pro` → ensure **Set as Current** (green badge)

---

## Step 6: Verify the Full Chain

### 6.1 RevenueCat Internal Check
- **Products** → `blinking_pro` → should show "Store: App Store" and status "Ready to Submit"
- **Offerings** → `ofrng88832e4ac2` → green "Current" badge → package contains `blinking_pro`
- **Entitlements** → `pro_access` → shows `blinking_pro` attached

### 6.2 App Store Connect Check
- IAP `blinking_pro` → status "Ready to Submit"
- App → version page → IAP `blinking_pro` selected

### 6.3 Test via Simulator
```bash
flutter run -d "iPhone 17 Pro" --debug \
  --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=...
```
Then: debug toggle → restricted → paywall → Get Pro → sandbox purchase dialog should appear.

### 6.4 Test via TestFlight
1. Build IPA: `flutter build ipa --release --dart-define=RC_API_KEY=appl_...`
2. Upload via Transporter
3. Wait for processing (~20min)
4. Create sandbox tester: App Store Connect → Users and Access → Sandbox Testers
5. Sign into sandbox on device
6. Install from TestFlight → debug toggle → paywall → purchase

---

## All Credentials (Master)

| Category | Item | Value |
|----------|------|-------|
| **App** | Bundle ID | `com.blinking.blinking` |
| **App Store** | Shared Secret | `cb7d69f2d98245de95e9eab7b4e0bbaf` |
| **App Store** | Issuer ID | `8525f01e-0925-49f8-9862-739031df8d50` |
| **App Store** | IAP Product ID | `blinking_pro` |
| **App Store** | IAP Price | $19.99 USD |
| **RevenueCat** | iOS Production Key | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` |
| **RevenueCat** | Test Store Key | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` |
| **RevenueCat** | Entitlement | `pro_access` |
| **RevenueCat** | Offering (Current) | `ofrng88832e4ac2` |
| **RevenueCat** | Product | `blinking_pro` |
| **RevenueCat** | Current Key ID | `4UK6U499RC` (Admin access — may need regeneration) |
| **RevenueCat** | Old Key ID (revoked) | `S7GU3FWWH5` |
| **AI Key** | TRIAL_API_KEY | (see password manager) |
| **AI Key** | PRO_API_KEY | (see password manager) |

---

## Common Mistakes & Fixes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Wrong Key ID in In-App Purchase section | RevenueCat can't validate | Match Key ID to the .p8 you uploaded |
| .p8 file renamed | RevenueCat rejects upload | Use Apple's original filename |
| Admin key used instead of IAP key | RevenueCat .p8 rejected | Generate new key with "In-App Purchase" or "App Manager" access |
| Save button stays blue | Credentials never saved | Click outside field, wait, try different browser |
| Shared Secret wrong | Products not found | Re-copy from App Store Connect |
| Issuer ID wrong | Authentication fails | Always `8525f01e-0925-49f8-9862-739031df8d50` |
| Product not in offering | "blinking_pro not found" | Verify offering contains product and is set as Current |
| TestFlight purchase fails | No sandbox account | Create sandbox tester, sign in on device |
