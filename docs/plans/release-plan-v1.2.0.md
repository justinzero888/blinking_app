# Blinking v1.2.0 — Planning

**Date:** 2026-05-17 | **Current Version:** 1.1.0+40 | **Target:** 1.2.0

---

## 🐛 Defect Fixes

### P0 — iPad Share Sheet Crash

| ID | Description | Status |
|----|-------------|--------|
| B-1 | iPad: Share.share() crashes — missing `sharePositionOrigin` on iPad `UIActivityViewController` popover | ⬜ To fix |
| B-2 | Affects: `entry_detail_screen.dart:78` (Share button) and `entry_card.dart:106` (share icon) | ⬜ To fix |
| B-3 | Add `sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1)` to both calls | ⬜ To fix |

### P1 — Server Infrastructure

| ID | Description | Status |
|----|-------------|--------|
| B-4 | AI model KV secrets misconfigured — trial used Llama, pro had wrong failover order | ✅ Fixed (May 16) |
| B-5 | Server AI config endpoint + legal pages not deployed (ai-config.ts, legal.ts) | ✅ Fixed (May 16) |
| B-6 | Device fingerprinting migration (0012) deferred — local entitlement sufficient | ⬜ Deferred |

---

## ✨ New Features

### P1 — Platform Launch

| ID | Description | Status |
|----|-------------|--------|
| F-1 | Google Play — promote from Internal Testing to Production | ⬜ Pending review |
| F-2 | Google Play — submit v40 AAB for production | ⬜ Pending |

### P2 — App Polish

| ID | Description | Status |
|----|-------------|--------|
| F-3 | Habit templates — starter pack for new users | ⬜ |
| F-4 | Habit template builder UI | ⬜ |
| F-5 | Habit import/export templates (JSON) | ⬜ |
| F-6 | Clean up habit building list — language mixing in routine names/descriptions | ⬜ |
| F-7 | Personas web page at `blinkingchorus.com/personas` (D1) | ⬜ |
| F-8 | Marketing plan — launch strategy, positioning, ASO | ⬜ Not started |

### P3 — Technical Debt

| ID | Description | Status |
|----|-------------|--------|
| T-1 | Restore streaming refactor — OOM on large backups | ⬜ ~2h |
| T-2 | `addCustomerInfoUpdateListener` in RevenueCat (G3) | ⬜ |
| T-3 | Hardcoded `'receipt': 'revenuecat_validated'` in server (G2) | ⬜ |
| T-4 | DeviceCheck upgrade for iOS (replace IDFV for 100% persistence) (D2) | ⬜ |
| T-5 | Firebase / Cloud Sync | ⬜ Large |

### Deferred / Canceled

| ID | Description | Reason |
|----|-------------|--------|
| D-1 | Server entitlement — receipt validation + cross-device sync | Local entitlement + RevenueCat sufficient for $19.99 app |
| D-2 | M4 Top-ups ($4.99/500 AI) | Canceled |
| D-3 | BYOK setup surface | Hidden — AI managed server-side |
| D-4 | Device fingerprinting server-side (block reinstall abuse) | Requires full server entitlement enabled |

---

## 📋 UAT (Pending)

| ID | Test | Status |
|----|------|--------|
| UAT-A | Avatars — verify CN avatars switch with locale | ⬜ |
| UAT-B | Welcome entry — verify no duplicate on force-kill | ⬜ |
| UAT-C | Custom persona — full form flow, edit, delete, cancel | ⬜ |
| UAT-D | Routine history — reflect tab + insights charts | ⬜ |
| UAT-E | Restricted gates — all 17 gate checks | ⬜ |
| UAT-F | Paywall — spinner, disable, cancel, store unavailable | ⬜ |
| UAT-G | Annual Reflection — generate with seeded data, save-once | ⬜ |
| UAT-H | Trial banner — 21-day preview text + robot menu | ⬜ |
| UAT-I | iPad share sheet — verify share works on real iPad | ⬜ |

---

## 📊 Test Status

| Suite | Tests | Status |
|-------|-------|--------|
| Client (blinking_app) | 454 | ✅ All passing |
| Server (chorus-api) | 370 | ✅ All passing |
| AI Persona Response | 16/16 | ✅ All passing |
| AI Failover Chain | 5/5 | ✅ DeepSeek→Gemini verified |
| iPad Share Sheet | — | ❌ Not tested |

---

## 🔗 Known Limitations (from 1.1.0)

| Item | Detail |
|------|--------|
| Custom persona images | Lost on reinstall (container path changes). Emoji fallback shown. |
| iPad backup | Black screen on iPad simulator during backup (mem pressure). Real devices unaffected. |
| Notifications | Fire in background only. Reschedule on app launch for daily repeat. |
| Android notifications | Emulator incompatible (needs Play Services). Real device TBD. |
| Restore streaming OOM | Large backups (>100MB) crash on restore. Streaming refactor planned. |

---

## 📝 Lessons Learned This Release

1. **Session summaries ≠ ground truth** — verify with `curl` against production endpoints
2. **Compile-time fallbacks mask deployment gaps** — add logging when fallback activates
3. **KV secrets drift silently** — add post-deploy validation script
4. **Feature gates can block unrelated features** — use specific gates, not umbrella toggles
5. **`git status` is free** — check it before claiming "deployed"
6. **No staging environment** — testing against production with silent fallbacks proves nothing
7. **iPad always needs `sharePositionOrigin`** — test on real iPad before shipping

---

## Build Commands

```bash
# iOS (production)
flutter build ipa --release \
  --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT \
  --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY \
  --dart-define=PRO_API_KEY=$PRO_API_KEY

# Android (production)
flutter build appbundle --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioitim \
  --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY \
  --dart-define=PRO_API_KEY=$PRO_API_KEY

# Tests
flutter test && flutter analyze --no-pub
cd ../chorus/chorus-api && npm test
```
