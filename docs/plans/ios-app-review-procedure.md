# iOS App Review — Submission Procedure

**Version:** 1.1.0+30 | **Date:** 2026-05-09

---

## Pre-flight Check

| Item | Status |
|------|--------|
| IPA uploaded to TestFlight | ✅ v30 processed, validated |
| IAP product `blinking_pro` ($19.99) | ✅ "Ready to Submit" |
| RevenueCat `pro_access` entitlement | ✅ Configured |
| Privacy Policy URL | ✅ In app |
| Terms of Service URL | ✅ In app |

---

## Step-by-Step

### Step 1 — Open App Store Connect
Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **Blinking Notes**

### Step 2 — Check the version
Look for version **1.1.0** under the iOS app. If it doesn't exist yet:
- Click **"+"** button next to iOS App → New Version
- Enter `1.1.0`

### Step 3 — Add IAP to the version
Scroll to **In-App Purchases** section:
1. Click the **"+"** button
2. Select `blinking_pro` from the list
3. Click **Done**

### Step 4 — Fill in version information
These fields are under the **App Store** tab:

| Field | Value |
|-------|-------|
| **Promotional Text** | Leave blank or: "AI-powered reflections now available. Redesigned with lens-based journaling." |
| **Description** | (Use existing from beta if available) |
| **Keywords** | journal, diary, memory, habit, reflection, mood, meditation |
| **Support URL** | (Your support page, or leave existing) |
| **Marketing URL** | (Optional) |

### Step 5 — App Review Information
Under **App Review Information** section:

| Field | Value |
|-------|-------|
| **Sign-in required** | ✅ **No** — app has no account system |
| **Contact Information** | `blinkingfeedback@gmail.com` |
| **Phone** | Your phone number |
| **Notes** | Copy the review notes below |

#### Review Notes (copy-paste)

```
APP REVIEW NOTES
================

App has no sign-in, no account, no social login. Works fully offline.

IAP Testing:
1. Install app → complete 3-screen onboarding (tap through)
2. Settings → About → tap version text "1.1.0" quickly 5 times
   → Debug snackbar: "Debug: Switched to restricted mode"
3. Tap the robot icon (bottom right) → Paywall screen opens
4. Tap "Get Pro" → native purchase dialog appears
5. Log in with sandbox tester:
   Email: blinking.tester@gmail.com
   Password: BlinkTest123!
6. Complete purchase → "Welcome to Pro!" banner
7. Verify: Settings banner shows "Pro — All features unlocked"

IAP Product: blinking_pro ($19.99, non-consumable)
Entitlement: pro_access

AI features: AI reflections use server-configured keys.
No content moderation required — all data stays on device.

Contact: blinkingfeedback@gmail.com
```

### Step 6 — Export Compliance
Under **App Store** tab → **Export Compliance**:
- App uses encryption? → **No**
- `ITSAppUsesNonExemptEncryption` is already set to `false` in Info.plist

### Step 7 — Content Rights
- Does your app contain, show, or access third-party content? → **No**

### Step 8 — Age Rating
- Generated from your responses in the Rating section
- Should already be set from previous submissions

### Step 9 — Review Screenshots (optional for update)
If the UI has changed significantly:
- Upload new screenshots for 6.7" and 6.5" displays
- Required sizes: 1290x2796 (iPhone 16 Pro Max) or 1284x2778 (iPhone 15 Pro Max)

### Step 10 — Version Release
At the top of the version page, under **Version Release**:
- Select: ✅ **"Manually release this version"** (not automatic)
- This lets you control when it goes live after approval

### Step 11 — Submit
1. Click **"Add for Review"** (top right) or **"Submit for Review"**
2. Answer any remaining compliance questions
3. Confirm submission

---

## After Submission

| Timeline | What |
|----------|------|
| 0-1 hour | Status changes to "In Review" (or "Waiting for Review") |
| 1-2 days | App Review decision (approval or rejection) |
| After approval | IAP `blinking_pro` becomes available on TestFlight (sandbox) |
| Manual release | You must manually release the version to make it live on App Store |

---

## If Rejected

Common reasons and fixes:

| Reason | Fix |
|--------|-----|
| IAP not found | Verify `blinking_pro` is added to the version (Step 3) |
| Paywall unclear | Add "Restore Purchases" note in review notes |
| Crash on launch | Rebuild, check crash logs in Xcode Organizer |
| Privacy policy missing | Verify Privacy Policy link works |
| AI content concerns | Add note: "AI features generate personal journal reflections only. No user-generated public content." |
