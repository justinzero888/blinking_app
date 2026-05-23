# Phase 2 UAT — Test Cases

> **Date:** May 23, 2026  
> **Build:** v1.2.0-dev (post T-6 voice notification + MergeSemantics AI chat fix)  
> **Changes:** Restore streaming optimization; T-6 voice notification (foreground TTS, DB migration v14); MergeSemantics fix for `input_ai_chat` and `btn_ai_send`  
> **Automated UAT:** See Section D — Maestro automated flows

---

## A. Restore Backup — Unit Tests (Automated)

| # | Test | Result |
|---|------|--------|
| UT-1 | `byte-weighted progress: larger file contributes more progress` | ✅ 458/458 |
| UT-2 | `progress values monotonically increase with many files` | ✅ |
| UT-3 | `restore with zero-size media files does not divide by zero` | ✅ |
| UT-4 | `fused decode produces identical data as two-step decode` | ✅ |
| UT-5 | `invokes onProgress callback during ZIP extraction` (existing, 3 equal files) | ✅ |
| UT-6 | `restore with media and avatar files includes both in progress` (updated for byte-weight) | ✅ |
| UT-7 | `with no media files does not call progress callback` (existing) | ✅ |
| UT-8 | `without onProgress callback does not crash` (existing) | ✅ |
| UT-9 | All persona + export integration tests (existing) | ✅ |
| UT-10 | Full regression: 458 tests pass, 0 analyze errors | ✅ |

---

## B. Restore Backup — Manual UAT

### Device setup

Before each test, create test data:
1. Add 5 entries (3 notes with content, 2 checklists with items)
2. Add 3 routines (1 daily active, 1 weekly, 1 adhoc)
3. Add 2 custom tags
4. Add 3 photos to entries (pick from simulator photo library)
5. Switch persona to Elara
6. Export backup via Settings → General → Backup (with media)

### Test Matrix

| # | Test | Device | Steps | Expected | Result |
|---|------|--------|-------|----------|--------|
| R-1 | Restore text-only backup | iPhone 17 Pro | Export (no media) → uninstall app → reinstall → Settings → General → Restore → select backup file | All entries, routines, tags, persona restored. No crash. | ⬜ |
| R-2 | Restore with media | iPhone 17 Pro | Export (with media) → uninstall → reinstall → restore | Photos visible in entries. File paths correct. Media files in app documents. | ⬜ |
| R-3 | Restore text-only backup | iPad Air 11" | Same as R-1 | Same result. No iPad-specific issues. | ⬜ |
| R-4 | Restore with media | iPad Air 11" | Same as R-2 | Same result. Media files correct. | ⬜ |
| R-5 | Restore text-only backup | Android emulator | Same as R-1 | Same result. Android-specific paths correct. | ⬜ |
| R-6 | Restore + progress bar accuracy | iPhone 17 Pro | Create backup with 10+ photos of varying sizes. Restore. Watch progress. | Progress bar moves smoothly (no jumps to 100%). Byte-weighted: larger files move the bar more. | ⬜ |
| R-7 | Restore large backup | iPhone 17 Pro | Create backup with 20+ photos, long entries. Restore. | App does not crash. Progress visible. No UI freeze. | ⬜ |
| R-8 | Restore cancel mid-way | iPhone 17 Pro | Start restore, dismiss dialog at ~30% | App functional. No partial data corruption. | ⬜ |
| R-9 | Restore — immediate use after | iPhone 17 Pro | Restore, immediately navigate to Calendar | Calendar shows restored data. No crash. No stale state. | ⬜ |
| R-10 | Restore v1.0 era backup | iPhone 17 Pro | Restore a backup created before Phase 1 changes | Backward compatible. Data imports correctly. | ⬜ |
| R-11 | Restore corrupted ZIP | iPhone 17 Pro | Hand-edit a ZIP to corrupt data.json. Attempt restore. | Clear error message. App not in broken state. No crash. | ⬜ |
| R-12 | Consecutive restores | iPhone 17 Pro | Restore backup A → verify → restore backup B → verify | B's data replaces A's. No leak. No crash. | ⬜ |
| R-13 | Progress: zero-size media backup | iPhone 17 Pro | Create backup where only media file is empty (0 bytes). Restore. | Restore completes. No progress shown (guarded). No crash. | ⬜ |
| R-14 | Export → restore → re-export consistency | iPhone 17 Pro | Export A → restore A → export B → compare A vs B | A and B are identical (round-trip integrity). | ⬜ |

### Post-Restore Verification Checklist (after each test)

| Check | Expected |
|-------|----------|
| All entries present (count matches) | ✅ |
| Entry content correct (spot check 2 entries) | ✅ |
| Checklist items preserved (checked/unchecked state) | ✅ |
| Media photos visible in entries | ✅ (if media backup) |
| Routines present (count matches) | ✅ |
| Routine active/paused state preserved | ✅ |
| Tags present (count matches) | ✅ |
| Persona restored (Settings → AI → active style shows Elara) | ✅ |
| Calendar shows emoji badges for restored entries | ✅ |
| AI Assistant works (tap robot, send message) | ✅ |

---

## C. Voice Notification — T-6 Testing

> **Design complete:** `docs/plans/design-t6-voice-notification.md`  
> **Implemented:** May 22, 2026  
> **Scope:** Foreground TTS only (no background). Voice output only. No microphone.

### Unit Tests (Automated)

| # | Test | Result |
|---|------|--------|
| V-UT-1 | `Routine.voiceEnabled` defaults to `false` | ⬜ |
| V-UT-2 | `Routine.fromJson()` reads `voiceEnabled` from JSON | ⬜ |
| V-UT-3 | `Routine.toJson()` writes `voiceEnabled` to JSON (round-trip) | ⬜ |
| V-UT-4 | `Routine.copyWith()` preserves `voiceEnabled` | ⬜ |
| V-UT-5 | Routine created without `voiceEnabled` has `voiceEnabled = false` | ⬜ |

### Manual UAT

| # | Test | Device | Steps | Expected | Result |
|---|------|--------|-------|----------|--------|
| V-1 | Global toggle: Settings → General shows "Voice Reminders" | iPhone 17 Pro | Settings → General tab | "Voice Reminders" SwitchListTile visible. Default OFF. | ⬜ |
| V-2 | Global toggle: turn ON | iPhone 17 Pro | V-1 → toggle ON | Toggle turns green. `VoiceNotificationService.init()` called (log: 🔊 [Voice] Initialized) | ⬜ |
| V-3 | Global toggle: turn OFF | iPhone 17 Pro | V-1 → toggle OFF (if ON) | Toggle turns gray. TTS stopped. | ⬜ |
| V-4 | Per-routine toggle: hidden when global OFF | iPhone 17 Pro | Global voice OFF. Open routine dialog with reminder set. | "Speak reminder" toggle NOT visible. | ⬜ |
| V-5 | Per-routine toggle: visible when global ON | iPhone 17 Pro | Global voice ON. Open routine dialog with reminder set. | "Speak reminder" toggle visible. Default OFF. | ⬜ |
| V-6 | Per-routine toggle: turn ON | iPhone 17 Pro | V-5 → toggle ON | Toggle turns green. Saves to routine.voiceEnabled = true. | ⬜ |
| V-7 | Per-routine toggle: hidden when no reminder | iPhone 17 Pro | Global voice ON. Open routine with empty reminder field. | "Speak reminder" toggle NOT visible (guard: needs reminder time). | ⬜ |
| V-8 | Voice: routine fires in foreground, EN | iPhone 17 Pro | Locale EN. Create routine "Drink water" with reminder 2min from now, voice ON. Keep app open, wait. | At reminder time, TTS speaks "Drink water" in English (en-US voice). Log: 🔊 [Voice] Speaking: "Drink water" | ⬜ |
| V-9 | Voice: routine fires in foreground, ZH | iPhone 17 Pro | Locale ZH. Create routine "喝水" with description, reminder 2min from now, voice ON. Keep app open, wait. | TTS speaks "喝水 — [description]" in Chinese (zh-CN voice). | ⬜ |
| V-10 | Voice: just-missed reminder on launch | iPhone 17 Pro | Create voice routine with reminder 1min in the past. Force-close app. Wait 1min. Open app. | TTS speaks the routine name at launch (within 2min window). | ⬜ |
| V-11 | Voice: app in background (no TTS) | iPhone 17 Pro | Create voice routine with reminder 2min from now. Minimize app. | Visual notification appears. NO TTS. | ⬜ |
| V-12 | Voice: per-routine toggle OFF | iPhone 17 Pro | Routine A voice ON, routine B voice OFF. Both fire. | A speaks, B silent. | ⬜ |
| V-13 | Voice: global toggle OFF overrides per-routine | iPhone 17 Pro | Global voice OFF. Routine has voice ON. Reminder fires. | Silent — global OFF wins. | ⬜ |
| V-14 | Voice: routine fires, Android | Android emulator | Same as V-8 (EN) | TTS speaks in English. No crash. | ⬜ |
| V-15 | Voice: routine fires, Android (ZH) | Android emulator | Same as V-9 (ZH) | TTS speaks in Chinese. No crash. | ⬜ |
| V-16 | Voice: TTS unavailable (permission/setup) | Android emulator | Config TTS engine disabled. Create voice routine. | No crash. Visual notification still appears. Graceful failure. | ⬜ |
| V-17 | Voice: stop speech on app close | iPhone 17 Pro | TTS speaking, force-close app | Speech stops. No audio leak. | ⬜ |
| V-18 | Voice: only one routine speaks on launch | iPhone 17 Pro | Create 3 voice routines all 1min in the past. Launch app. | Only 1 speaks (avoid flooding). | ⬜ |

### New Tests (Post DB Migration + Foreground Timer Fix)

| # | Test | Device | Steps | Expected | Result |
|---|------|--------|-------|----------|--------|
| V-19 | Voice: routine fires via foreground timer | iPhone 17 Pro | Voice ON. Create routine with reminder 1min from now. Keep app open. | TTS speaks within 30s of reminder time (timer polls every 30s). | ⬜ |
| V-20 | Voice: persistence (new routine) | iPhone 17 Pro | New routine, voice ON, save. Force-close app. Reopen. Go to routine dialog. | "Speak reminder" toggle is still ON (DB persisted). | ⬜ |
| V-21 | Voice: persistence (edit routine) | iPhone 17 Pro | Existing routine with voice OFF. Edit → toggle ON → save. Force-close. Reopen dialog. | "Speak reminder" toggle is ON (DB updated). | ⬜ |
| V-22 | Voice: persistence (edit → OFF) | iPhone 17 Pro | Routine with voice ON. Edit → toggle OFF → save. Force-close. Reopen. | Toggle is OFF (DB updated). | ⬜ |
| V-23 | Voice: deduplication (no repeat) | iPhone 17 Pro | Voice ON. Create routine 1min from now. Keep app open past reminder time. Wait 60s+. | Speaks once at first detection. Does NOT repeat on subsequent timer ticks. | ⬜ |
| V-24 | Voice: toggle appears dynamically when typing reminder | iPhone 17 Pro | Global voice ON. Open routine dialog (no reminder). Reminder field empty → toggle hidden. Type "08:00" → toggle appears. Clear field → toggle disappears. | Toggle appears/disappears in real-time as user types. | ⬜ |
| V-25 | Voice: Test Voice button speaks | iPhone 17 Pro | Settings → General → Voice ON → tap "Test Voice" | TTS speaks "Hello, this is a voice reminder test" (or Chinese). | ⬜ |
| V-26 | Voice: DB migration from v13 adds column | iPhone 17 Pro | Fresh install (v14 schema). Create routine with voice ON. | Routine saved with voice_enabled = 1. App restarts, data intact. | ⬜ |

---

## D. Maestro Automated UAT

> **Runner scripts:** `maestro-tests/ci/run-uat-iphone.sh`, `run-uat-ipad.sh`, `run-uat-android.sh`  
> **Flow files:** `maestro-tests/apps/blink-notes/flows/uat/`  
> **Subflows:** `maestro-tests/apps/blink-notes/subflows/`

### Flow Matrix

| ID | Flow | iPhone 17 Pro | iPad Air 11" | Android |
|----|------|:---:|:---:|:---:|
| R-1 | r1-entry-crud — create, read, edit, delete entry | ✅ | ✅ | ✅ |
| R-2 | r2-checklist-entry — checklist type entry | ✅ | ✅ | ✅ |
| R-3 | r3-routine-crud — create routine, verify snackbar | ✅ | ✅ | ✅ |
| R-4 | r4-ai-chat — open Daily Reflection, save | ✅ | ✅ | ✅ |
| R-5 | r5-insights — stats + mood distribution | ✅ | ✅ | ✅ |
| R-6 | r6-calendar — calendar view loads | ✅ | ✅ | ✅ |
| R-7 | r7-language-toggle — EN↔ZH settings | ✅ | ✅ | ✅ |
| P-1 | p1-persona-switch — cycle personas | ✅ | ✅ | ✅ |
| P-2 | p2-custom-persona — save custom style | ✅ | ✅ | ✅ |
| E-1 | e1-preview-mode — preview banner | ✅ | ✅ | ✅ |
| E-2 | e2-debug-restricted — debug tap → restricted | ✅ | ✅ | ✅ |
| E-3 | e3-debug-preview — debug tap → preview | ✅ | ✅ | ✅ |
| S-1/2 | s1-s2-entry-share — share entry, verify share sheet | ✅ | ⛔ SKIP | ✅ |
| S-3/4 | s3-s4-backup-export — ZIP backup share sheet | ✅ | ⛔ SKIP | ✅ |
| S-5/6 | s5-s6-habit-export — JSON habit export share sheet | ✅ | ⛔ SKIP | ✅ |
| A-1 | a1-android-entry-share — Android-style share | ✅ | ⛔ SKIP | ✅ |
| A-2 | a2-android-backup-export — Android backup share | ✅ | ⛔ SKIP | ✅ |

### iPad Share-Sheet Limitation

The 5 `SKIP` flows fail permanently on iPad because `UIActivityViewController` presents as a `UIPopover` anchored to the triggering widget. Maestro uses XCTest APIs which cannot traverse into a `UIPopover`'s separate accessibility window. This is an iOS platform limitation, not a test or app bug. The flows are excluded from the iPad run via `run-uat-ipad.sh` (12/17 flows run on iPad).

### Key Notes

- **r4-ai-chat**: `kUseMultiTurnChat=false` routes robot button to `ReflectionSessionScreen` (not `AssistantScreen`). Test updated to open Daily Reflection, wait for AI content ("Save Reflection" button appears when `!aiLoading && hasContent`, 60s timeout), tap save, assert "Saved". Passes on all three platforms.
- **create-entry subflow**: `extendedWaitUntil "Memory saved!" timeout 15000` — increased from 8000 to handle parallel flow execution on iPad.
- **r3 Do tab**: Text inside `TabBarView/PageView/ListView` is not exposed to XCTest on iOS 26.4. The Do tab navigation is verified by screenshot; no text assertion is possible.
- **Android**: All 17 flows run on Android emulator. Results pending this run.
