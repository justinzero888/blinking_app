# Maestro UAT Automation — Master Regression Suite

> **Living document.** Add a row to the appropriate table every time a new feature or fix gets a Maestro flow.  
> **Flow root:** `maestro-tests/apps/blink-notes/`  
> **Run scripts:** `maestro-tests/ci/run-uat-iphone.sh` · `run-uat-ipad.sh` · `run-uat-android.sh`  
> **Last full pass:** 2026-05-23 — iPhone 17/17 ✅ · iPad 12/12 ✅ · Android 17/17 ✅

---

## How to run

```bash
# iPhone — all 17 flows
./ci/run-uat-iphone.sh --device E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA

# iPad — 12 flows (share-sheet flows excluded; see §iPad UIPopover below)
./ci/run-uat-ipad.sh --device 39B46CD1-C3B5-43C1-B527-A5BCFECEA773

# Android
./ci/run-uat-android.sh --device emulator-5554
```

---

## Currently Automated

### Core Regression (Phase 1: R, E, P)

| ID | Description | Flow file | iPhone | iPad | Android | Phase 1 ref |
|----|-------------|-----------|:------:|:----:|:-------:|-------------|
| r1 | Entry CRUD — create, edit, delete note | `flows/uat/r1-entry-crud.yaml` | ✅ | ✅ | ✅ | R-1 |
| r2 | Checklist entry — create, toggle items | `flows/uat/r2-checklist-entry.yaml` | ✅ | ✅ | ✅ | R-2 |
| r3 | Routine CRUD — create, verify snackbar, Do tab | `flows/uat/r3-routine-crud.yaml` | ✅ | ✅ | ✅ | R-3 |
| r4 | AI Daily Reflection — open, wait for content, save | `flows/uat/r4-ai-chat.yaml` | ✅ | ✅ | ✅ | R-4 |
| r5 | Insights — Writing Activity, Mood Distribution | `flows/uat/r5-insights.yaml` | ✅ | ✅ | ✅ | R-5 |
| r6 | Calendar — day navigation, emoji badges | `flows/uat/r6-calendar.yaml` | ✅ | ✅ | ✅ | R-6 |
| r7 | Language toggle — EN↔ZH round-trip | `flows/uat/r7-language-toggle.yaml` | ✅ | ✅ | ✅ | R-7 |
| e1 | Preview mode — banner visible, 21-day countdown | `flows/uat/e1-preview-mode.yaml` | ✅ | ✅ | ✅ | E-1 |
| e2 | Debug restricted — 7-tap → restricted mode | `flows/uat/e2-debug-restricted.yaml` | ✅ | ✅ | ✅ | E-2 |
| e3 | Debug preview — 7-tap → preview restored | `flows/uat/e3-debug-preview.yaml` | ✅ | ✅ | ✅ | E-3 |
| p1 | Persona switch — Kael→Elara→Rush→Marcus cycle | `flows/uat/p1-persona-switch.yaml` | ✅ | ✅ | ✅ | P-1 |
| p2 | Custom persona — create style, save, verify snackbar | `flows/uat/p2-custom-persona.yaml` | ✅ | ✅ | ✅ | P-2 |

### Share / Export (Phase 1: S, A)

> iPad share-sheet flows are excluded from `run-uat-ipad.sh`. See [iPad UIPopover](#ipad-uipopover) below.

| ID | Description | Flow file | iPhone | iPad | Android | Phase 1 ref |
|----|-------------|-----------|:------:|:----:|:-------:|-------------|
| s1-s2 | Entry share — share sheet opens | `flows/uat/s1-s2-entry-share.yaml` | ✅ | ⛔ | ✅ | S-1, S-2 |
| s3-s4 | Backup export — ZIP share sheet | `flows/uat/s3-s4-backup-export.yaml` | ✅ | ⛔ | ✅ | S-3, S-4 |
| s5-s6 | Habit export — JSON share sheet | `flows/uat/s5-s6-habit-export.yaml` | ✅ | ⛔ | ✅ | S-5, S-6 |
| a1 | Android entry share — share sheet opens | `flows/uat/a1-android-entry-share.yaml` | ✅ | ⛔ | ✅ | A-1 |
| a2 | Android backup export — ZIP share sheet | `flows/uat/a2-android-backup-export.yaml` | ✅ | ⛔ | ✅ | A-2 |

---

### Keepsake Cards (Phase 3: K)

> Full breakdown: [`keepsake-uat-catalog.md`](./keepsake-uat-catalog.md) — 20 automatable, 8 manual.

| ID | Description | Effort | Notes |
|----|-------------|--------|-------|
| k1-iphone | Create keepsake, badge visible, preview, share flow | Medium | Covers K-1, K-6, K-7, K-19 |
| k2-ipad | Same on iPad | Low | K-2, K-19 excluded for iPad |
| k3-templates-all | Browse all 8 templates, pick each | Medium | K-5 (flow only; visual fidelity manual) |
| k4-toggles | All toggle combinations ON/OFF | Medium | K-11 to K-17 |
| k5-locale | Template names EN↔ZH | Low | K-25, K-26 |
| k6-edit | Edit existing keepsake | Low | K-20 |
| k7-reflection | Create from AI reflection + Assistant | Medium | K-3, K-4 |
| k8-android | Full flow on Android | Low | K-24 |

---

## Future Automation Candidates

Cases from existing UAT documents that are **feasible to automate** but do not have a flow yet. Add them here as you implement them.

| ID | Description | Effort | Phase ref | Notes |
|----|-------------|--------|-----------|-------|
| v-settings | Voice Reminders global toggle ON/OFF in Settings | Low | P2 V-1, V-2, V-3 | Navigate to Settings → General, assert SwitchListTile visible/toggleable |
| v-per-routine | Per-routine "Speak reminder" toggle visibility rules | Medium | P2 V-4 to V-7 | Needs routine with/without reminder time set; assert toggle visible/hidden |
| v-persist | Voice voiceEnabled persists across relaunch | Medium | P2 V-20, V-21, V-22 | Use `stopApp` + `launchApp` (no clearState) to simulate relaunch |
| v-dynamic | Voice toggle appears live while typing reminder time | Low | P2 V-24 | Input "08:00" → assert toggle appears; clear → assert toggle gone |
| v-test-btn | "Test Voice" button in Settings is tappable | Low | P2 V-25 | Tap button, assert no crash/error state (audio output not verifiable) |
| p3-private | Private tag (#私密) entries excluded from AI context | Medium | P1 P-3 | Create tagged entry, open AI screen, assert entry text absent from context |
| s9-import | Habit import (JSON) — routines appear after import | Medium | P1 S-9 | Requires test fixture JSON file placed in simulator's shared storage |

---

## Manual-Only Cases

These **cannot be automated with Maestro** due to fundamental platform or test-design constraints.

### Backup restore (requires app reinstall)

Maestro's `launchApp: clearState: true` clears app data but cannot uninstall/reinstall the binary. Full restore UAT requires a real reinstall cycle.

| Phase ref | Description |
|-----------|-------------|
| P1 S-7 | Restore text-only backup — uninstall → reinstall → restore |
| P1 S-8 | Restore with media — uninstall → reinstall → restore + photo check |
| P2 R-1 to R-14 | All restore backup manual UAT (byte-weighted progress, cancel mid-restore, round-trip integrity, old v1.0 backups, corrupted ZIP, etc.) |

### In-app purchase

| Phase ref | Description |
|-----------|-------------|
| P1 A-3 | Android RevenueCat sandbox IAP — requires real purchase flow in sandbox |

### iPad UIPopover {#ipad-uipopover}

`UIActivityViewController` renders as a `UIPopover` on iPad — a separate accessibility window XCTest cannot traverse. Maestro cannot see share-sheet actions on iPad. This is a permanent iOS platform limitation.

| Phase ref | Description |
|-----------|-------------|
| P1 S-2, S-4, S-6 | Share/export flows on iPad Air 11" |

### Voice / TTS (requires real-time wait or audio verification)

Maestro cannot verify audio output or wait minutes for a timed reminder to fire.

| Phase ref | Description | Blocker |
|-----------|-------------|---------|
| P2 V-8, V-9 | TTS speaks at reminder time (EN/ZH) | Requires 2-min real-time wait + audio |
| P2 V-10 | Just-missed reminder on launch | Force-close + 1-min wait + audio |
| P2 V-11 | No TTS in background | Background state + audio |
| P2 V-12, V-13 | Per-routine toggle OFF; global OFF override | Timing + audio verification |
| P2 V-14, V-15 | Android TTS EN/ZH | Timing + audio |
| P2 V-16 | TTS unavailable graceful failure | Requires disabling TTS engine |
| P2 V-17 | Speech stops on force-close | Force-close + audio |
| P2 V-18 | Only 1 routine speaks on launch | Timing + audio |
| P2 V-19 | Foreground timer fires within 30s | Requires 30s+ real-time wait |
| P2 V-23 | Deduplication — speaks once only | Requires 60s+ real-time wait |
| P2 V-26 | DB migration from v13 | Requires installing a specific old build |

### Keepsake cards (Phase 3: K)

| Phase ref | Description |
|-----------|-------------|
| K-18 | Style override: font color visual verification — Maestro can tap color picker but cannot verify hex color output |
| K-27 | Dark mode visual consistency — Maestro can toggle theme but cannot verify visual output |
| K-19 (iPad) | Share keepsake on iPad — UIPopover limitation |
| K-22 | Restore keepsake survives re-render — requires uninstall → reinstall |
| K-23 | Backup size verification — requires external ZIP file size check |
| K-21 | AI Rewrite button — requires real LLM call with variable latency |
| K-5 (visual) | Decorative motif rendering fidelity (bamboo silhouette, seal stamp, mountain gradient, etc.) |

---

## Adding a new test case

1. Write the Maestro flow in `flows/uat/<id>-<feature>.yaml`
2. Add a row to the **Currently Automated** table above
3. If it applies to iPad, add it to the flow list in `ci/run-uat-ipad.sh`
4. Run all three simulators and confirm the new row passes before merging
5. Remove the case from **Future Automation Candidates** if it was listed there
