# Blinking — Project Status — 2026-05-09

**Version:** 1.1.0+30 | **Tests:** 147/147 | **Lint:** 0 errors

---

## 🟢 Production Release: v1.1.0+30

First stable release (beta tag dropped). Full changelog at `docs/session-notes/session-summary-2026-05-09.md`.

### AI Refactor
- Multi-turn chat → single-turn lens-based reflections (Zengzi's Three)
- Mood Moment — 3-posture reactive AI via emoji jar "Ask AI"
- 3-per-day limits on both Daily Reflection saves and Mood Moments
- Lens configuration in Settings ("Your Three")
- All numeric quota language stripped
- BYOK surfaces hidden
- Insights tab AI branding removed

### Server Config
- `https://blinkingchorus.com/api/config` — live, serving correct model + keys
- Multi-key failover active
- Keys updatable without app deploy (24h cache)

---

## App Store Submission Status

| Platform | Status | Details |
|----------|--------|---------|
| **Google Play** | ✅ v30 uploaded | Closed beta testing |
| **iOS TestFlight** | ✅ v30 IPA validated | Passed Apple validation |
| **iOS App Review** | ⬜ Ready to submit | Submit for review with IAP `blinking_pro` |

### iOS App Review — Human Steps

1. App Store Connect → Blinking → **1.1.0** → Prepare for Submission
2. Add IAP `blinking_pro` ($19.99) to the version
3. Review Information:
   - **Sign-in:** Demo account not needed (app has no sign-in)
   - **Contact:** blinkingfeedback@gmail.com
   - **Notes:**
     - Sandbox tester: `blinking.tester@gmail.com` / `BlinkTest123!`
     - Debug toggle: Settings → About → tap version 5x → force restricted → tap robot → paywall
     - IAP product ID: `blinking_pro` ($19.99, non-consumable, entitlement `pro_access`)
4. Submit for App Review

---

## Server

| Item | Status |
|------|--------|
| `api/config` endpoint | ✅ Live — trial + pro keys, correct model |
| `api/entitlement` endpoints | ⬜ Secrets not set (JWT_SECRET, ENTITLEMENT_ENABLED) |
| D1 migrations | ⬜ Not run |
