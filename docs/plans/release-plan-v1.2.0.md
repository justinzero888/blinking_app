# Blinking v1.2.0 — Release Planning (Audited May 20)

**Date:** 2026-05-20 | **Current Version:** 1.1.0+40 (live on both stores) | **Target:** 1.1.1 or 1.2.0

---

## Production Status (Confirmed)

| Platform | Version | Status |
|----------|---------|--------|
| iOS App Store | 1.1.0+40 | ✅ Live |
| Google Play | 1.1.0+40 | ✅ Live |
| Server (blinkingchorus.com) | — | ✅ Deployed May 16 |

---

## 🐛 Defects

### P0 — iPad Share Sheet (Fixed in Code, Needs Release)

| ID | Description | Status |
|----|-------------|--------|
| B-1 | iPad: `Share.shareXFiles()` unresponsive — missing `sharePositionOrigin` on iPad `UIActivityViewController` popover | ✅ Fixed (`128af6e`) |
| B-2 | Affects: `export_service.dart:shareFile()`, `settings_screen.dart:_handleExportHabits()` | ✅ Fixed |
| B-3 | Added `Rect.fromLTWH(0, 0, 1, 1)` to all `Share.shareXFiles()` calls | ✅ Fixed |
| — | **Needs new build to ship to users** | ⬜ Pending |

### P0 — Server Infrastructure (Resolved)

| ID | Description | Status |
|----|-------------|--------|
| B-4 | AI model KV secrets misconfigured — trial used Llama, pro had wrong failover order | ✅ Fixed (May 16) |
| B-5 | Server AI config endpoint + legal pages not deployed | ✅ Fixed (May 16) |
| B-6 | Device fingerprinting migration (0012) — local entitlement sufficient | ⬜ Deferred |

---

## ✨ New Features

### ✅ Done (in v40 Production)

| ID | Description |
|----|-------------|
| F-1 | Google Play — promoted to Production |
| F-2 | Google Play — v40 AAB live |
| F-3 | Habit starter pack — 31 seed routines (3 active, 28 paused, 9 categories) on first install |
| F-6 | Language audit — all seed routines have dual-locale fields, no mixing |

### P1 — v1.2.0

| ID | Description | Status |
|----|-------------|--------|
| F-9 | Keepsake cards — 8 RedNotes-style templates (墨韵–山水, Chinese aesthetic). Single-page, single-entry, photo+text integration. Save as Keepsake from entries, AI reflections, or Assistant chat. Entry detail badge for revisit. Metadata-only backup (re-render on restore, ~2KB/card). AI Rewrite for content polish. No competitor combines AI + mood + tags on visual cards — unique differentiator. | ⬜ Design locked (D1–D14), ~11 days (May 29 – Jun 8) |

### P2 — Remaining

| ID | Description | Status |
|----|-------------|--------|
| F-4 | Habit template browse/import UI (separate from full backup/restore) | ⬜ |
| F-5 | Habit template export as standalone JSON bundle | ⬜ |
| F-7 | Personas web page at `blinkingchorus.com/personas` | ⬜ |
| F-8 | Marketing plan — launch strategy, positioning, ASO | ⬜ Not started |

### P3 — Technical Debt

| ID | Description | Effort |
|----|-------------|--------|
| T-1 | Restore streaming refactor | ✅ Done — `json.fuse(utf8).decode`, byte-weighted progress, event-loop yields | ~2h |
| T-2 | `addCustomerInfoUpdateListener` in RevenueCat | ✅ Done — listener registered in `init()` | ~15min |
| T-3 | Hardcoded `'receipt': 'revenuecat_validated'` in server | ✅ Done — replaced with `null` + TODO | ~30min |
| T-4 | DeviceCheck upgrade for iOS | **Deferred** — low ROI for $19.99 |
| T-5 | Platform version audit | ✅ Done — Flutter 3.41.9, Xcode 26.4.1, SDK 36 | ~1h |
| T-6 | Voice notification for routines | ✅ Done — `flutter_tts`, global + per-routine toggle, foreground timer, DB v14 | ~2h |

### Deferred / Canceled

| ID | Description | Reason |
|----|-------------|--------|
| D-1 | Server entitlement — receipt validation + cross-device sync | Local entitlement + RevenueCat sufficient for $19.99 app |
| D-2 | M4 Top-ups ($4.99/500 AI) | Canceled |
| D-3 | BYOK setup surface | Hidden — AI managed server-side |
| D-4 | Device fingerprinting server-side (block reinstall abuse) | Requires full server entitlement enabled |
| D-5 | DeviceCheck upgrade for iOS | Low ROI for $19.99 |
| D-6 | Firebase / Cloud Sync | **Data privacy is Blinking's highest priority.** Server-side data storage conflicts with the local-first privacy guarantee ("no accounts, just you and your memories"). E2E encryption is table stakes but 10x implementation cost. Backup/restore covers current data safety needs. See [`competitive-analysis-cloud-sync.md`](./competitive-analysis-cloud-sync.md) for full analysis. |

---

## 📋 UAT (Pending on Real Devices)

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
| UAT-I | iPad share sheet — verify share works on real iPad (fix in `128af6e`) | ⬜ |

---

## 📊 Test Status

| Suite | Tests | Status |
|-------|-------|--------|
| Client (blinking_app) | 454 | ✅ All passing |
| Server (chorus-api) | 370 | ✅ All passing |
| AI Persona Response | 16/16 | ✅ All passing |
| AI Failover Chain | 5/5 | ✅ DeepSeek→Gemini verified |

---

## 🔗 Known Limitations (from 1.1.0)

| Item | Detail |
|------|--------|
| iPad share button | Unresponsive in v40 production. Fix in `128af6e`, needs release. |
| Custom persona images | Lost on reinstall (container path changes). Emoji fallback shown. |
| iPad backup | Static dialog (no progress bar) — known limitation on iPad simulator |
| Notifications | Fire in background only. Reschedule on app launch for daily repeat. |
| Android notifications | Emulator incompatible (needs Play Services). Real device TBD. |
| Restore streaming OOM | Large backups (>100MB) crash on restore. Streaming refactor planned (~2h). |

---

## 📝 Lessons Learned This Release

1. **Session summaries ≠ ground truth** — verify with `curl` against production endpoints
2. **Compile-time fallbacks mask deployment gaps** — add logging when fallback activates
3. **KV secrets drift silently** — add post-deploy validation script
4. **Feature gates can block unrelated features** — use specific gates, not umbrella toggles
5. **`git status` is free** — check it before claiming "deployed"
6. **No staging environment** — testing against production with silent fallbacks proves nothing
7. **iPad always needs `sharePositionOrigin`** — test on real iPad before shipping
8. **Documentation drifts** — re-audit project status docs after every release to catch stale items

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
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY \
  --dart-define=PRO_API_KEY=$PRO_API_KEY

# Tests
flutter test && flutter analyze --no-pub
cd ../chorus/chorus-api && npm test
```
