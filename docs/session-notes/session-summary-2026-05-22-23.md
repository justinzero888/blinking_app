# Session Summary — May 22–23, 2026

**Version:** v1.2.0-dev | **Tests:** 458/458 | **Lint:** 0 errors  
**Completed:** Phase 1 + Phase 2 of v1.2.0 execution plan  
**Next:** Phase 3 (Card Revitalization) starts May 29

---

## Phase 1 — Quick Fixes + Audit (Complete)

### Share + API migration (B-1/2/3)
- Migrated `Share.share()` / `Share.shareXFiles()` → `SharePlus.instance.share(ShareParams(...))` (8 occurrences, 4 files)
- Migrated `Purchases.purchasePackage()` → `Purchases.purchase(PurchaseParams.package())` (1 occurrence)
- Result: 0 deprecation warnings

### Tech debt (T-2, T-3, T-5)
- T-2: Added `Purchases.addCustomerInfoUpdateListener` in `PurchasesService.init()`
- T-3: Replaced hardcoded `'revenuecat_validated'` → `null` with TODO comment
- T-5: Platform audit — Flutter 3.41.9, Xcode 26.4.1, Android SDK 36. Updated CLAUDE.md.

### Simulator playbook
- Created `docs/plans/uat/simulator-launch-playbook.md` — battle-tested with 10 error cases
- Root cause: `flutter build ios --debug --no-codesign` → device binary, not simulator. Must use `--simulator`.

---

## Phase 2 — Restore Stream + Voice Notification (Complete)

### T-1: Restore Streaming Optimization
- Investigation: `ZipDecoder().decodeStream()` uses lazy streams — not the memory bottleneck
- Actual bottleneck: `data.json` parsed with `utf8.decode()` + `json.decode()` separately, creating intermediate String copy
- Fix: `json.fuse(utf8).decode()` — eliminates String copy. `archive.removeFile()` after import to free memory
- Byte-weighted progress (not file-count). Event-loop yields every 10 files.
- 4 new unit tests. 458 total.

### T-6: Voice Notification for Routines
- **Design docs:** `competitive-analysis-voice-notification.md`, `voice-feature-evaluation.md`, `design-t6-voice-notification.md`
- Full feature evaluation: 8 voice features scored across 6 dimensions. TTS reminders ranked #1.
- **Principle:** Voice output only. No microphone. Ever.
- **Scope:** Foreground TTS + launch-time missed reminders. Background TTS deferred to v1.3.0.
- **Implementation:**
  - New `VoiceNotificationService` (flutter_tts, bilingual EN/ZH)
  - Global toggle in Settings → General → "Voice Reminders" + "Test Voice" button
  - Per-routine toggle in routine dialog (dynamic show/hide as user types)
  - Foreground timer: 30-second poll for recently-arrived reminders
  - Deduplication: Set prevents repeat speaking within same session
  - DB migration v14: `voice_enabled` column added to `routines` table
- **DB changes:** v13 → v14. `kSchemaVersion = 14`. `voice_enabled INTEGER NOT NULL DEFAULT 0` on routines.
- **Bug fix pipeline:** `voiceEnabled` was missing from `addRoutine()` → `RoutineProvider` → `RoutineRepository` → `StorageService.insert` chain. Added through all 4 layers.
- 26 UAT test cases (updated to 30 with post-fix tests).

### Maestro Testing Integration
- 3 code fixes already present in codebase (mood row MergeSemantics from earlier build)
- 4 YAML fixes documented for Maestro agent
- 5 iPad share sheet flows permanently untestable by automation (UIActivityViewController popover limitation)
- Workaround: Maestro uses coordinate taps to dismiss iPad share popovers

---

## Competitive Analysis

| Document | Topic | Verdict |
|----------|-------|---------|
| `competitive-analysis-card-creation.md` | Card/sharing in 5 apps | ✅ Proceed — unique differentiator |
| `competitive-analysis-cloud-sync.md` | Cloud sync in 6 apps | ⏸️ Deferred — privacy-first |
| `competitive-analysis-voice-notification.md` | Voice in 7 apps | ✅ Proceed — zero competition |
| `voice-feature-evaluation.md` | 8 voice features scored | ✅ TTS reminders only |

---

## Documents Created (this session)

| Document | Purpose |
|----------|---------|
| `execution-plan-v1.2.0.md` | 28-day phased plan |
| `simulator-launch-playbook.md` | Reliable 3-simulator launch |
| `phase1_uat.md` | Phase 1 test cases |
| `phase2_uat.md` | Phase 2 test cases (restore + voice) |
| `competitive-analysis-card-creation.md` | Card feature competitive analysis |
| `competitive-analysis-cloud-sync.md` | Cloud sync competitive analysis |
| `competitive-analysis-voice-notification.md` | Voice notification competitive analysis |
| `voice-feature-evaluation.md` | 8 voice features scored |
| `card-design-deep-dive.md` | Multi-page, images, styling |
| `card-system-design-v1.2.0.md` | Full card system design (updated) |
| `design-t1-restore-streaming.md` | T-1 design + test cases |
| `design-t6-voice-notification.md` | T-6 detailed design |
| `results-t1-restore-streaming.md` | T-1 optimization results |
| `design-card-technical.md` | Card technical design + templates |
| `implementation-plan-v1.2.0.md` | Updated master plan |
| `release-plan-v1.2.0.md` | Updated release tracking |

---

## Code Changes Summary

| File | Change |
|------|--------|
| `pubspec.yaml` | Added `flutter_tts` |
| `lib/models/routine.dart` | Added `voiceEnabled` field |
| `lib/core/services/database_service.dart` | DB v14 migration |
| `lib/core/services/storage_service.dart` | T-1: fused decode, byte progress, yields. T-6: voice_enabled read/write |
| `lib/core/services/voice_notification_service.dart` | **New** — TTS service |
| `lib/core/services/notification_service.dart` | Voice payload in notifications |
| `lib/core/services/purchases_service.dart` | Deprecated API migration, listener, receipt stub |
| `lib/core/services/export_service.dart` | share_plus migration |
| `lib/screens/settings/settings_screen.dart` | Voice toggle + test button |
| `lib/screens/routine/routine_screen.dart` | Voice toggle (dynamic) |
| `lib/screens/moment/entry_detail_screen.dart` | share_plus migration |
| `lib/widgets/entry_card.dart` | share_plus migration (×2) |
| `lib/providers/routine_provider.dart` | Voice pipeline + foreground timer |
| `lib/repositories/routine_repository.dart` | Voice-enabled create |
| `CLAUDE.md` | Updated versions, test count, pending items |
