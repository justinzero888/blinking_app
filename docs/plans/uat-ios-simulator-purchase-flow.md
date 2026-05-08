# iOS Simulator — Purchase Flow UAT

**Date:** 2026-05-08 | **Version:** 1.1.0-beta.8+28 | **Build:** flutter run --debug

---

## Setup

```bash
flutter run -d "iPhone 17 Pro" --debug \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=...
```

Uses Test Store key (default from main.dart). Purchase flow code is identical to production — only the product source differs.

---

## UAT-1: Onboarding → Preview → Robot Active

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 1.1 | App launches fresh | 3-page onboarding appears | |
| 1.2 | Swipe through all 3 pages | Page 1: philosophy, Page 2: features, Page 3: deal | |
| 1.3 | Tap "Get Started" on page 3 | Main app loads | |
| 1.4 | Check floating robot | Active (bobbing/pulsing animation) | |
| 1.5 | Robot long-press | Menu shows "Preview: X days left" | |
| 1.6 | Settings → AI section | Purple/blue "21-Day Preview" banner with countdown | |
| 1.7 | Countdown shows | "剩余 21 天" or "21 days left" | |
| 1.8 | Banner has buttons | "Get Blinking Pro" + "Bring your own key" visible | |
| 1.9 | Tap robot | AI assistant opens | |
| 1.10 | Type a message in AI | Should get a response (trial key) | |
| 1.11 | Save AI response as reflection | "Save Reflection" button works | |

## UAT-2: Debug Toggle → Restricted → Paywall

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 2.1 | Settings → scroll to About | See "Version 1.1.0-beta.8" text | |
| 2.2 | Tap version text 5x quickly | Snackbar: "Switched to restricted mode" | |
| 2.3 | Settings → AI section | Orange "Free Mode" banner appears | |
| 2.4 | Banner shows | "Get Blinking Pro" button visible | |
| 2.5 | Floating robot | Dormant (still visible, no bobbing) | |
| 2.6 | Tap robot | Paywall opens | |

## UAT-3: Paywall Display

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 3.1 | Paywall header | "Blinking Pro" title visible | |
| 3.2 | Price | "$19.99" displayed prominently | |
| 3.3 | Get Pro button | Blue/green "Get Pro — $19.99" button, clickable | |
| 3.4 | Restore button | "Restore Purchases" text button below | |
| 3.5 | Feature list | 5 features listed (notes, habits, AI, backup, Chorus) | |
| 3.6 | Free section | "Even without Pro" — notes + habits free | |
| 3.7 | Footer | "No subscription, one purchase, yours forever" | |
| 3.8 | Legal links | Privacy Policy + Terms links at bottom | |

## UAT-4: Purchase Flow (Test Store)

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 4.1 | Tap "Get Pro" | Test Store purchase dialog appears | |
| 4.2 | Dialog shows | 3 buttons: Test valid purchase / Test failed / Cancel | |
| 4.3 | Tap "Test valid purchase" | "Welcome to Pro!" green snackbar | |
| 4.4 | Paywall dismisses | Returns to previous screen | |
| 4.5 | Settings → AI | Green "💎 Blinking Pro — Lifetime" banner | |
| 4.6 | "Get Pro" button | Gone from banner | |
| 4.7 | "Bring your own key" | Still visible in paid banner | |
| 4.8 | Floating robot | Active (bobbing) | |
| 4.9 | Tap robot | AI assistant opens, works (pro key) | |

## UAT-5: Restore Purchases

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 5.1 | Debug toggle back to restricted | Orange banner | |
| 5.2 | Tap robot → paywall → Restore Purchases | "Pro restored." green snackbar | |
| 5.3 | Paywall dismisses | Returns to previous screen | |
| 5.4 | Settings → AI | Green Pro banner | |

## UAT-6: Cancel / Failed

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 6.1 | Toggle to restricted → paywall → Get Pro → Cancel | Returns to paywall, no error | |
| 6.2 | Get Pro → Test failed purchase | "Welcome to Pro!" appears (Test Store quirk) | |

## UAT-7: BYOK Link

| # | Step | Expected | ✅ |
|---|------|----------|----|
| 7.1 | Settings → AI → tap "Bring your own key" | BYOK setup screen opens | |
| 7.2 | 6 provider types listed | OpenRouter, OpenAI, Claude, Gemini, DeepSeek, Groq | |
| 7.3 | Add a key | Provider list updates | |
| 7.4 | Settings → AI banner | Green "Using your own key" appears | |
| 7.5 | Remove BYOK | Falls back to Pro/Trial key | |

---

## Quick Reference

| Action | How |
|--------|-----|
| Force restricted | Settings → About → tap version 5x |
| Force preview | Settings → About → tap version 5x again |
| Open paywall | Tap dormant robot in restricted mode |
| Toggle back to preview | Debug toggle again (5x tap) |
