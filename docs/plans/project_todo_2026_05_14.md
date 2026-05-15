# Blinking — TODO May 14

**Version:** 1.1.0+36 | **Tests:** 164/164 | **Lint:** 0 errors

---

## Production Status

| Store | Status |
|-------|--------|
| **iOS App Store** | ✅ **Approved** — 1.1.0+36 ready |
| Google Play | Submitted for review |
| **Production builds** | ✅ AAB + IPA compiled |

---

## 0. Completed Today ✅

- [x] Default AI persona → Kael/楷迩
- [x] 31 seed routines (3 active, 28 paused)
- [x] 9 category PNG icons
- [x] Tags refresh (6 custom + 3 system)
- [x] Chinese locale + persona names
- [x] Private tag AI filter (5 entry points)
- [x] Notifications (one-shot, reschedule on launch)
- [x] Locale fixes (description, dialog, routine_item)
- [x] Reminder validation (HH:MM format)
- [x] Daily AI counter only on success
- [x] Code audit + CLAUDE.md updates
- [x] GitHub commit + push

---

## 0. Today's Priorities (P0)

- [ ] Clean up habit building list — language mixing in routine names/descriptions
- [ ] Default AI persona changed to Kael (楷迩) ✅

---

## 1. Habit Builder and Default

- [ ] Design default habit templates (starter pack for new users)
- [ ] Implement habit template builder UI
- [ ] Allow users to import/export habit templates (JSON)
- [ ] Seed default habit suggestions based on wellness categories

---

## 2. UAT — Final Validation on Sims

- [ ] UAT-A: Avatars — verify CN avatars switch with locale
- [ ] UAT-B: Welcome entry — verify no duplicate on force-kill
- [ ] UAT-C: Custom persona — full form flow, edit, delete, cancel
- [ ] UAT-D: Routine history — reflect tab + insights charts
- [ ] UAT-E: Restricted gates — all 17 gate checks
- [ ] UAT-F: Paywall — spinner, disable, cancel, store unavailable
- [ ] UAT-G: Annual Reflection — generate with seeded data, save-once
- [ ] UAT-H: Trial banner — 21-day preview text + robot menu

---

## 3. iOS App Icon + Android Icon

- [x] iOS icon updated on sim home screen
- [ ] Android icon — emulator unstable, documented. APK source files verified correct.

## 4. App Store Approval

| Store | Status |
|-------|--------|
| **iOS App Store** | ✅ **Approved** — ready for release (`Version 1.1.0 — Ready for Distribution`) |
| **Google Play** | Submitted for review |

---

## 4. Remaining from May 12–13

| # | Item | Priority |
|---|------|----------|
| D1 | #6 — Personas web page at `blinkingchorus.com/personas` | P2 |
| G2 | Hardcoded `'receipt': 'revenuecat_validated'` in server | P3 |
| G3 | `addCustomerInfoUpdateListener` in RevenueCat | P3 |

---

## 5. Prepare for App Review Response (if needed)

- [ ] Monitor Apple + Google review status
- [ ] Prepare responses if rejection comes back
- [ ] Have App Store Connect IAP screenshots ready

---

## Notes

- Build 35 (iOS) and AAB (Android) both submitted for production review
- Paid Apps Agreement active; IAP sandbox tested and passing
- Device identity deployed — no server key needed
- CN avatars and locale names deployed — auto-switch with language setting
- AI costs verified: ~$0.01/user for full 21-day trial (DeepSeek V3)

## Known Limitations

| Item | Detail |
|------|--------|
| **Custom persona images** | Files in app directory — lost on reinstall (container path changes). Text data (name, vibe, lenses) survives. Emoji fallback shown. |
| Notifications | Fire in background only. Reschedule on app launch for daily repeat. |
| Android notifications | Emulator incompatible (needs Play Services). Real device TBD. |
