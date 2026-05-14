# Blinking — TODO May 12–13

**Version:** 1.1.0+36 | **Tests:** 164/164 | **Lint:** 0 errors

---

## Major Milestones

| Date | Milestone | Status |
|------|-----------|--------|
| 2026-05-12 | **Google Play production submission** | ✅ Submitted |
| 2026-05-12 | **IAP fix (RC_API_KEY + loading state)** | ✅ Fixed |
| 2026-05-12 | **All TODO items #1–5, #7–8** | ✅ Implemented |
| 2026-05-12 | **Device identity (preview abuse prevention)** | ✅ Implemented & deployed |
| 2026-05-13 | **Paid Apps Agreement activated** | ✅ Active |
| 2026-05-13 | **Sandbox IAP UAT on build 35** | ✅ Passed |
| 2026-05-13 | **iOS App Store resubmission (build 35)** | ✅ Submitted for review |
| 2026-05-13 | **Device identity deployed** | ✅ D1 + server + client |
| 2026-05-13 | **All UAT fixes applied** | ✅ Banner, avatar, feedback, save-once |
| 2026-05-13 | **Chinese locale + persona names** | ✅ 楷迩/依澜/如溯/墨克 + CN avatars |
| 2026-05-13 | **AI cost benchmark** | ✅ $0.01/user/trial, $10/1K users |

---

## 1. Test Annual Reflection ✅

- [x] Write 17 unit tests for `selectAnnualSamples`, `assembleAnnualReflectionPrompt`, `maxTokensForAnnual`
- [x] Verify 24 samples selected (2/month) — tested
- [x] Verify prompt structure (themes, seasons, growth arc)
- [ ] Generate with 30+ entries on Android + iOS (manual, needs seeded data)
- [ ] Test "Save to Journal" persistence on device

## 2. Create & Add Avatars ✅

- [x] Generate 4 avatar illustrations (user-provided, 256x256 PNGs)
- [x] Bundle as assets in `assets/avatars/`
- [x] Wire into `ReflectionStyle` model (`avatarAsset` field)
- [x] Update `AiPersonaProvider` to load asset avatar by style
- [x] Update Settings preview + Floating robot + Reflection AppBar to use style avatar

## 3. First-Launch Welcome Entry ✅

- [x] After onboarding complete → auto-create a welcome entry
- [x] Content: brief instructions on how to use the app
- [x] Tagged with new `tag_welcome`
- [x] Shows on My Day so user sees something immediately

## 4. Trial Duration: 21-Day vs 7-Day ✅

- [x] Research industry standards for journaling app trials
- [x] Evaluate current 21-day local preview — abuse vectors identified
- [x] RevenueCat trial config options reviewed
- [x] Decision: keep 21 days
- [x] Device identity abuse prevention design documented

## 5. Customer AI Persona (Settings) ✅

- [x] Add "Create Custom Style" option to Reflection Style picker
- [x] Full-screen form: name, vibe, emoji picker (32 options), image upload, personality (150 char), 3 lens questions
- [x] Save to SharedPreferences as `ai_custom_style`
- [x] Enable delete/remove for custom styles
- [x] Client-side validation: no empty lenses, name required
- [x] Preview card shows actual custom data (not hardcoded fallback)

## 6. Web Page: Personas & Routines Library

- [ ] Static page at `blinkingchorus.com/personas`
- [ ] Showcase all 4 built-in personas with descriptions + sample outputs
- [ ] Habit/Routine templates users can import
- [ ] JSON export format for routine import compatibility
- [ ] Add route to Cloudflare Worker

## 7. Fix Routine History Start Date ✅

- [x] Reflect tab: date range starts from earliest routine `createdAt` (not fixed 60 days)
- [x] `SummaryProvider._currentRange`: anchored to `_earliestDataDate()` (entries + routine creation + completions)
- [x] `_earliestDataDate()` scans entries, routine creation dates, and completion logs

## 8. Restricted Mode Feature Gates (Audit & Fix) ✅

- [x] Audit `EntitlementService` feature gates (`canAddHabit`, `canEditNote`, `canBackup`, `canExport`)
- [x] Fixed `canExport` (was hardcoded `true`, now `_state != restricted`)
- [x] Gates added: FAB add habit, Build tab edit/toggle, Manual Add, all export/backup/restore/habit items
- [x] Tags tab: locked in restricted mode
- [x] AI tab: locked in restricted mode (shows Pro banner)
- [x] Annual Reflection AI: gated behind `canUseAI`
- [x] Data portability: cancel no longer bypasses gate (always returns after re-engage)
- [x] UX: blocked features show paywall redirect, not crash or error
- [x] Data portability re-engage: subsequent taps go straight to paywall (no dead tap)

## 9. Device Identity (Preview Abuse Prevention) ✅

- [x] Server: D1 table `device_fingerprints` + fingerprint check in `/api/entitlement/init`
- [x] iOS native: `UIDevice.identifierForVendor` → sha256 via platform channel
- [x] Android native: `Settings.Secure.ANDROID_ID` → sha256 via platform channel
- [x] Client: `DeviceFingerprintService` sends fingerprint with init call
- [x] Logic: block reinstall preview only after 21-day expiry (not on first install)
- [x] Pro users: fingerprint check skipped — paid state restored
- [x] Factory reset: intentionally allows fresh preview (documented decision)

---

## Current Gaps

### Non-Blocking (P2/P3)

| # | Gap | Impact | Effort |
|---|-----|--------|--------|
| G2 | Production IPA sends `'receipt': 'revenuecat_validated'` to server | Server-side receipt validation never receives real receipts. Client-side purchase works via RevenueCat local validation. | Low |
| G3 | No `addCustomerInfoUpdateListener` in RevenueCat | Cross-device entitlement changes (refunds, multi-device) won't sync until next manual `refreshCustomerInfo()` | Low |
| G4 | Restore streaming OOM on large backups | Known limitation | Medium |
| G5 | Tag deletion protection: `_systemTagIds` includes welcome but gates are at tab level | Tags tab is locked in restricted mode, so system tags can't be deleted. Safe. | N/A |
| G6 | `_saveAiSettings` and `_pickAiAvatar` unused methods | Dead code from before AI tab lockdown | N/A |

### Deferred

| # | Item | Priority |
|---|------|----------|
| D1 | #6 — Personas web page at `blinkingchorus.com/personas` | P2 |
| D2 | DeviceCheck upgrade for iOS (replace IDFV for 100% persistence) | P3 |

### Open (Need Manual Testing)

| # | Item |
|---|------|
| M1 | Annual Reflection: generate with 30+ entries on real device, verify Save to Journal |
| M2 | Annual Reflection: test with < 30 entries (button disabled) |
