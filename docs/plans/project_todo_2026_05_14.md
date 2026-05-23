# Blinking — Post-Launch Status (Audited May 20)

**Version:** 1.1.0+40 | **Tests:** 454/454 | **Lint:** 0 errors

---

## Production Status

| Store | Version | Status |
|-------|---------|--------|
| **iOS App Store** | 1.1.0+40 | ✅ Live |
| **Google Play** | 1.1.0+40 | ✅ Live |
| **Server** | — | ✅ AI config + legal pages deployed, KV secrets aligned |

---

## ✅ Completed (in v40 Production)

- [x] 31 seed routines (3 active, 28 paused across 9 categories) — this is the habit starter pack
- [x] Language audit — all seed routines have dual-locale `name`/`nameEn` + `description`/`descriptionEn`
- [x] Default AI persona → Kael/楷迩
- [x] 9 category PNG icons with locale-aware names
- [x] Tags refresh (6 custom + 3 system)
- [x] Private tag AI filter (5 entry points)
- [x] Notifications (one-shot, reschedule on launch)
- [x] Reminder validation (HH:MM format)
- [x] Daily AI counter only on success
- [x] Multi-custom persona support
- [x] Persona-specific lens mapping
- [x] CN avatars auto-switch with locale
- [x] Persona backup/restore fix
- [x] iPad backup black screen fix (yield event loop before export)
- [x] Image compression (1920px, q85) + media-exclude toggle
- [x] Code audit + CLAUDE.md updates

---

## 🔧 Fixed in Code (Not Yet Released)

| Item | Commit | Detail |
|------|--------|--------|
| iPad share sheet | `128af6e` | Added `sharePositionOrigin` to all `Share.shareXFiles()` calls. iPad share button unresponsive in v40 production. |

---

## 📋 Remaining Post-Launch Items

### P1 — Next Build

| # | Item | Effort |
|---|------|--------|
| 1 | Ship iPad share fix in new release (v1.1.1 or v1.2.0) | ~1h |
| 2 | UAT on real devices — 9 test sections pending (avatars, welcome entry, custom persona, routine history, restricted gates, paywall, annual reflection, trial banner, iPad share) | ~2h |

### P2 — Polish & Marketing

| # | Item | Effort |
|---|------|--------|
| 3 | Personas web page at `blinkingchorus.com/personas` | ~2h |
| 4 | Marketing plan — launch strategy, positioning, ASO | TBD |
| 5 | Routine import/export template browsing (separate from full backup) | ~2h |

### P3 — Technical Debt

| # | Item | Detail | Effort |
|---|------|--------|--------|
| 6 | Restore streaming refactor | `ZipDecoder().decodeStream()` loads entire archive into RAM at `storage_service.dart:664`. Process entries incrementally instead. Peak RAM: backup size → largest single file. | ~2h |
| 7 | `addCustomerInfoUpdateListener` | RevenueCat listener for out-of-app events (refunds, cross-device purchases). Without it, `isPro` only updates on cold launch. Low impact for $19.99 non-consumable. | ~15min |
| 8 | Hardcoded `'receipt': 'revenuecat_validated'` in server | Stub value — no production impact since server entitlement is deferred | ~30min |
| 9 | Firebase / Cloud Sync | Large — all deps currently commented out | Large |

---

## Known Limitations

| Item | Detail |
|------|--------|
| iPad share button | Unresponsive in v40 production. Fix in `128af6e`, needs release. |
| Custom persona images | Lost on reinstall (container path changes). Emoji fallback shown. |
| iPad backup | Static dialog (no progress bar) — known limitation on iPad simulator |
| Notifications | Fire in background only. Reschedule on app launch for daily repeat. |
| Android notifications | Emulator incompatible (needs Play Services). Real device TBD. |
| Restore OOM | Large backups (>100MB) crash on restore. Streaming refactor planned. |
