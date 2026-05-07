# Blinking — Trial → Restricted → Pro UAT

**Date:** 2026-05-06 | **Version:** 1.1.0 (Phase 2 complete)  
**Testers:** Human validation on iOS & Android simulators

---

## Test Data

- Backup: `blinking_backup_1778100016832.zip` (327 entries, 15 routines, 327 completions)
- Trial key: passed via `--dart-define=TRIAL_API_KEY=...`
- Pro key: passed via `--dart-define=PRO_API_KEY=...`
- Auto-restore enabled

---

## UAT-1: Fresh Install → Onboarding → Preview

**Prerequisite:** Erase simulator (Device → Erase All Content and Settings)

| # | Step | Expected Result | iOS | Android |
|---|------|----------------|-----|---------|
| 1.1 | Launch app | 3-page onboarding appears | | |
| 1.2 | Swipe through page 1 | Philosophy / welcome text | | |
| 1.3 | Swipe to page 2 | Features overview | | |
| 1.4 | Swipe to page 3 → tap "Get Started" | Onboarding dismisses, main app loads | | |
| 1.5 | After onboarding | "21-Day Preview" banner visible in Settings → AI section | | |
| 1.6 | Day countdown | Shows "剩余 X 天" / "X days left" (not 0) | | |
| 1.7 | Floating robot | Active (bobbing animation), not dormant | | |
| 1.8 | Tap robot → AI assistant opens | Can type message and get AI response | | |
| 1.9 | AI response | Returns meaningful reply (not "network error" or "no API key") | | |
| 1.10 | Settings → AI section | One blue/purple preview banner, no duplication | | |
| 1.11 | Settings → AI → BYOK section | SINGLE "Use my own key" entry, not duplicated | | |
| 1.12 | Robot long-press | Menu shows "Preview: X days left" | | |

## UAT-2: Preview → Restricted Transition

**Prerequisite:** Use debug toggle (5-tap version in Settings → About) to force restricted mode

| # | Step | Expected Result | iOS | Android |
|---|------|----------------|-----|---------|
| 2.1 | Toggle to restricted | Orange banner: "Free Mode — AI: 3/month" | | |
| 2.2 | AI quota message | No "X remaining" count visible to user | | |
| 2.3 | Floating robot | Active (3/month quota available) | | |
| 2.4 | Tap robot → AI assistant | AI works (uses pro key for 3/month credit) | | |
| 2.5 | After 3 AI requests | Robot becomes dormant | | |
| 2.6 | Tap dormant robot | Opens paywall (not a snackbar) | | |
| 2.7 | Settings → AI section | Orange banner with "Get Blinking Pro" button | | |
| 2.8 | Features blocked in restricted | Cannot edit habits, tags, backup (verify below) | | |

## UAT-3: Purchase Flow (Test Store)

**Prerequisite:** In restricted mode (from UAT-2)

| # | Step | Expected Result | iOS | Android |
|---|------|----------------|-----|---------|
| 3.1 | Tap robot → paywall → Get Pro | Native purchase dialog appears | | |
| 3.2 | Click "Test valid purchase" | "Welcome to Pro!" snackbar | | |
| 3.3 | Paywall dismisses | Returns to previous screen | | |
| 3.4 | Settings → AI section | "💎 Blinking Pro — Lifetime" green banner | | |
| 3.5 | "Get Blinking Pro" button | Gone / replaced by green banner | | |
| 3.6 | Floating robot | Active (bobbing) | | |
| 3.7 | Tap robot → AI works | Uses pro key | | |
| 3.8 | Restore Purchases | Shows "Pro restored." on subsequent launches | | |

## UAT-4: BYOK (Bring Your Own Key)

**Prerequisite:** In any entitlement state

| # | Step | Expected Result | iOS | Android |
|---|------|----------------|-----|---------|
| 4.1 | Settings → AI → "Use my own key" | Opens BYOK setup screen | | |
| 4.2 | Configure a valid API key | Provider list shows ONE entry per provider type | | |
| 4.3 | No duplicate providers | OpenRouter, OpenAI, Claude, Gemini — each appears once | | |
| 4.4 | Settings banner changes | Shows "Using your own key" (green) | | |
| 4.5 | BYOK overrides trial/pro key | AI uses user's key, not built-in | | |
| 4.6 | Remove BYOK | Falls back to trial/pro key based on state | | |

## UAT-5: Feature Gates — Restricted Mode

**Prerequisite:** In restricted mode (from UAT-2)

| # | Feature | Expected (Restricted) | iOS | Android |
|---|---------|----------------------|-----|---------|
| 5.1 | Add note/checklist | ✅ Works | | |
| 5.2 | Check habit | ✅ Works | | |
| 5.3 | View history/calendar | ✅ Works | | |
| 5.4 | AI assistant | ✅ Works (3/month) | | |
| 5.5 | Edit existing note | ❌ Blocked or hidden | | |
| 5.6 | Delete note | ❌ Blocked or hidden | | |
| 5.7 | Add new habit | ❌ Blocked or hidden | | |
| 5.8 | Edit habit | ❌ Blocked or hidden | | |
| 5.9 | Delete habit | ❌ Blocked or hidden | | |
| 5.10 | Edit tag | ❌ Blocked or hidden | | |
| 5.11 | Delete tag | ❌ Blocked or hidden | | |
| 5.12 | Backup | ❌ Blocked or hidden | | |
| 5.13 | Restore | ❌ Blocked or hidden | | |
| 5.14 | Share to Chorus | ❌ Blocked or hidden | | |

## UAT-6: Feature Gates — Pro Mode

**Prerequisite:** After purchase (from UAT-3)

| # | Feature | Expected (Pro) | iOS | Android |
|---|---------|---------------|-----|---------|
| 6.1 | All features | ✅ Everything unlocked | | |
| 6.2 | AI quota | 1,200/year | | |
| 6.3 | Robot | Always active | | |
| 6.4 | Settings banner | Green "Lifetime" | | |

---

## Known Issues to Validate

| Issue | Description | Status |
|-------|-------------|--------|
| BYOK-1 | Two BYOK links shown in Settings (duplication) | ⬜ Open |
| PREVIEW-1 | After onboarding, trial countdown shows correctly | ⬜ Open |
| PREVIEW-2 | Robot active immediately after onboarding | ⬜ Open |
| UI-1 | Old UI elements (orange restricted banner) shown incorrectly after fresh install | ⬜ Open |

---

## Quick Commands

```bash
# Build iOS with trial + pro keys + auto-restore
flutter run -d "iPhone 17 Pro" --debug \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=... \
  --dart-define=AUTO_RESTORE=/path/to/auto_restore.zip

# Build Android
flutter run -d emulator-5554 --debug \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=... \
  --dart-define=AUTO_RESTORE=/data/local/tmp/auto_restore.zip

# Debug toggle: Settings → About → tap version 5x → cycle preview/restricted
```
