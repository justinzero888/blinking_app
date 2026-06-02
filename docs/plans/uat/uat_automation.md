# Maestro UAT Automation — Master Regression Suite

> **Living document.** Add a row to the appropriate table every time a new feature or fix gets a Maestro flow.  
> **Flow root:** `maestro-tests/apps/blink-notes/`  
> **Run scripts:** `maestro-tests/ci/run-uat-iphone.sh` · `run-uat-ipad.sh` · `run-uat-android.sh`  
> **Last full pass:** 2026-06-01 — iPhone 12/12 ✅ · iPad 12/12 ✅ · Android 12/12 ✅ (v1.2.0+47)
> **Phase 2 voice flows added:** 2026-05-23 — 5 new flows (v1–v4, s9); run scripts updated to 22 flows  
> **Phase 3 keepsake flows added:** 2026-05-23 — 10 new flows (k1–k10); run scripts updated to 32/26 flows  
> **v1.2.0+44 purchase/price flow added:** 2026-05-31 — 1 new flow (p1); run scripts now 33/27 flows

---

## How to run

```bash
# iPhone — all 32 flows
./ci/run-uat-iphone.sh --device E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA

# iPad — 26 flows (share-sheet flows + k3-android excluded; see §iPad UIPopover below)
./ci/run-uat-ipad.sh --device 39B46CD1-C3B5-43C1-B527-A5BCFECEA773

# Android — all 32 flows
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

### Voice Reminders + Import (Phase 2: V, S-9)

| ID | Description | Flow file | iPhone | iPad | Android | Phase 2 ref |
|----|-------------|-----------|:------:|:----:|:-------:|-------------|
| v1 | Voice global toggle ON/OFF + Test Voice button tappable | `flows/uat/v1-voice-settings.yaml` | ✅ | ✅ | ✅ | V-1, V-2, V-3, V-25 |
| v2 | Speak reminder visibility: no-reminder, global-off, global-on | `flows/uat/v2-voice-per-routine.yaml` | ✅ | ✅ | ✅ | V-4, V-5, V-6, V-7 |
| v3 | Voice global setting persists via stopApp+launchApp | `flows/uat/v3-voice-persist.yaml` | ✅ | ✅ | ✅ | V-20, V-21, V-22 (partial — see note) |
| v4 | Speak reminder toggle appears/disappears dynamically while typing | `flows/uat/v4-voice-dynamic.yaml` | ✅ | ✅ | ✅ | V-24 |
| s9 | Import Habits button opens document picker, dismisses cleanly | `flows/uat/s9-habit-import.yaml` | ✅ | ✅ | ✅ | S-9 (partial — picker-launch only) |

> **v3 note:** Per-routine `voiceEnabled` persistence (V-20 to V-22 full) requires tapping the routine's edit dialog after relaunch. The routine tile edit icon (`more_vert`) has no Semantics identifier and is not accessible to XCTest. The flow validates the SharedPreferences layer (global voice) and indirectly confirms the persistence infrastructure. Add `Semantics(identifier: 'btn_edit_routine')` to `_BuildRoutineTile`'s edit GestureDetector to unlock full coverage.  
> **s9 note:** Full import with data verification requires pre-seeding `fixtures/routines_test.json` into the app container AFTER `clearState` runs. See `ci/run-uat-iphone.sh` for the `xcrun simctl` seeding instructions.

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

> Semantics identifiers added 2026-05-23: `btn_save_keepsake`, `card_builder_content`, `template_tpl_*`, `toggle_show_mood/date/tags/footer`, `btn_card_save`, `badge_keepsake`, `btn_edit_card`, `btn_share_card`, `btn_reflection_save_keepsake`, `btn_assistant_save_keepsake`.  
> Visual fidelity (gradients, motifs, colors) is manual per MV-1, MV-2, MV-3, MV-4. See phase3_uat.md.

| ID | Description | Flow file | iPhone | iPad | Android | Phase 3 ref |
|----|-------------|-----------|:------:|:----:|:-------:|-------------|
| k1 | Create keepsake from entry, badge visible, preview shows Edit+Share | `flows/uat/k1-core-create.yaml` | 🔲 | ⛔ | ⛔ | MK-1, MK-6, MK-7 |
| k2 | Create keepsake on iPad (Moonlight template) | `flows/uat/k2-ipad-create.yaml` | ⛔ | 🔲 | ⛔ | MK-2 |
| k3 | Create keepsake on Android + share sheet opens | `flows/uat/k3-android-create.yaml` | ⛔ | ⛔ | 🔲 | MK-24 |
| k4 | Browse all 8 templates — tap each, no crash | `flows/uat/k4-template-browse.yaml` | ✅ | ✅ | ✅ | MK-5 |
| k5 | Toggle overlays ON/OFF (mood, date, tags, footer) — save both states | `flows/uat/k5-toggle-overlays.yaml` | ✅ | ✅ | ✅ | MK-13, MK-14, MK-16, MK-17 |
| k6 | Edit existing keepsake — change template, badge updates | `flows/uat/k6-edit-keepsake.yaml` | ✅ | ✅ | ✅ | MK-18 |
| k7 | Locale — EN/ZH builder labels and template names | `flows/uat/k7-locale.yaml` | ✅ | ✅ | ✅ | MK-20, MK-21, MK-22, MK-23 |
| k8 | AI reflection → Save as Keepsake | `flows/uat/k8-reflection-entry.yaml` | ✅ | ✅ | ✅ | MK-3 |
| k9 | Text-only entry → clean preview (no broken image) | `flows/uat/k9-photo-integration.yaml` | ✅ | ✅ | ✅ | MK-12 |
| k10 | Badge mapping: no-badge entry, correct template name, no system tag | `flows/uat/k10-badge-mapping.yaml` | ✅ | ✅ | ✅ | MK-8, MK-9, MK-15 |

> **k1 note:** iPhone only — Android/iPad have dedicated flows (k2, k3). k1 verifies the full entry→builder→badge→preview path.

### Purchase & Pricing (v1.2.0+44)

> **Changes:** Dynamic pricing from RevenueCat offerings, `_lastError` propagation on missing API key, crash guard in release builds.  
> **New flow added:** 2026-05-31 — p1 for purchase readiness validation.

| ID | Description | Flow file | iPhone | iPad | Android | Ref |
|----|-------------|-----------|:------:|:----:|:-------:|-----|
| p1 | Paywall loaded — RC initialized, price displayed, "Get Pro" enabled | `flows/uat/p1-paywall-ready.yaml` | ✅ | ✅ | ✅ | M-1, M-6 |
| p2 | Paywall CTA smoke — Restore round-trip, cancel recovery, no crash | `flows/uat/p2-paywall-cta-smoke.yaml` | ✅ | ✅ | ✅ | M-7 |

> **p2 note:** Simulator only — uses local StoreKit/Play test environment. Taps "Restore Purchases" instead of "Get Pro" to avoid native OS payment sheet that Maestro cannot traverse. Validates SDK round-trip + error recovery.

> **p1 note:** Requires debug toggle (5-tap version text) to enter restricted mode. The flow verifies RC store initialization by asserting "Get Pro" is enabled (no "Store unavailable" warning). Price text contains `$` but exact value depends on RC offerings sync.

---

## Future Automation Candidates

Cases from existing UAT documents that are **feasible to automate** but do not have a flow yet. Add them here as you implement them.

| ID | Description | Effort | Phase ref | Notes |
|----|-------------|--------|-----------|-------|
| v3-full | v3 per-routine voiceEnabled DB persistence (V-20 to V-22 complete) | Low | P2 V-20, V-21, V-22 | Add `Semantics(identifier: 'btn_edit_routine')` to `_BuildRoutineTile` edit icon, then extend v3 flow to re-open edit dialog and assert toggle state |
| s9-full | s9 full import — fixture seeded, picker navigated, snackbar asserted | Medium | P1 S-9 | Restructure run script to seed `fixtures/routines_test.json` post-clearState; s9 flow selects file and asserts "Import complete: 2 imported" |
| k8-assistant | MK-4: Create keepsake from Assistant chat | Low | P3 MK-4 | k8 covers MK-3 (ReflectionSession). MK-4 path requires `kUseMultiTurnChat=true` routing to AssistantScreen and `btn_assistant_save_keepsake` (identifier already added) |
| k9-photo-full | MK-10, MK-11: Photo as hero/inline background in keepsake | Medium | P3 MK-10, MK-11 | Seed a photo into the simulator camera roll pre-run; create entry with image_picker; open builder; verify image appears in preview |

---

## Manual-Only Cases

These **cannot be automated with Maestro** due to fundamental platform or test-design constraints.

### AI context exclusion (non-deterministic output)

| Phase ref | Description | Blocker |
|-----------|-------------|---------|
| P1 P-3 | Private tag (#私密) entries excluded from AI context | LLM output is non-deterministic — Maestro cannot assert "entry text absent" from a generated reflection. Verify via unit test on the prompt-construction layer (assert private entries are excluded from the context slice passed to the LLM). |

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
