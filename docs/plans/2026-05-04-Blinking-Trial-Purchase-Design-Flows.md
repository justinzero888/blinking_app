# Blinking — Detailed Design Flows v1

**Companion to:** `Blinking-Launch-Plan.md` v1.2
**Scope:** Three flows — (1) preview & Pro purchase, (2) simplified BYOK setup, (3) top-up purchase
**Date:** May 3, 2026
**Owner:** Justin

---

## 0. Conventions used throughout

- **Server is the authority for entitlement state.** The client mirrors with a 7-day offline cache for PREVIEW and an indefinite cache for PAID. Never let the client unilaterally decide a tier transition.
- **All copy in [brackets] is suggested wording**, edit freely. The copy is part of the design — terse, calm, no exclamation points, no urgency theatre.
- **All times are user-local** (the device's clock), not UTC, for state transitions. Server rounds to UTC midnight ± 12h tolerance to avoid timezone-shift exploits.
- **IAP stack assumption:** notes are written to be middleware-agnostic, with a slight lean toward RevenueCat for the indie-launch case (path of least resistance). Replace `[entitlement]`, `[offering]`, `[customer]` references with whatever your stack uses.
- **BYOK providers:** the flow below uses Anthropic + OpenAI as the example pair. **Swap in whatever set your current flow supports** at the points marked `[providers]`.

---

## 1. Preview & Pro purchase flow

This is the highest-leverage flow in the entire app. Get it right and the launch math works; get it wrong and 21-day preview ends silently with no purchases. Detail matters.

### 1.1 First-launch onboarding

Fires once, on first app open, before any UI is shown. Three screens, each skippable from screen 2 onward (not from screen 1 — the philosophy hook needs to land).

**Screen 1 — The philosophy.**
Full-bleed Tessera fragment animation. Two lines of text:
> [Your life is fragments of time, randomly assembled.]
> [Blinking is a quiet place to assemble them.]

CTA: [Continue] — no skip button.

**Screen 2 — What's inside.**
Three icons + one line each:
> [Notes — capture moments, edit them anytime]
> [Habits — small daily check-ins]
> [Reflection — an AI assistant that helps you see patterns]

CTA: [Continue]    ⌐    [Skip]

**Screen 3 — The deal, stated plainly.**
> [The first 21 days are on us — full app, 9 AI reflections per day.]
> [After that, you can keep adding notes and checking your habits forever, free. To keep AI, habits, and backup, Pro is a one-time purchase. No subscription, ever.]

CTA: [Start your 21 days]    ⌐    [Already have Pro? Restore]

**Server side at first launch:**
1. Generate a stable user ID (Apple sign-in identifier or Google Play Services ID).
2. Create a server entitlement record: `{ userId, state: 'PREVIEW', preview_started_at: now() }`.
3. Server returns a signed entitlement token (JWT) with state + expiry. Client stores it.

**Don't:** force account creation. The Apple/Google identifier is enough. Asking for email at first launch is a measurable conversion-killer (~30% drop-off in onboarding studies).

### 1.2 During preview (Days 1–17)

**No mention of the preview, ever.** This is counterintuitive but important: the moment you put a "trial countdown" in the UI, you're framing the relationship as transactional. The user feels watched. The 21-day window is a *gift*, not a test.

The entire app behaves identically to PAID in this window. AI calls work. Habits work. Backup works.

The only place the preview surfaces is a discreet line at the bottom of Settings → About:
> [Preview — 17 days remaining]

That's it. Nothing modal, nothing pushy, nothing in the main UI.

### 1.3 Soft purchase prompts (Days 18–20)

This is the conversion window. Three days, three different prompts, each tied to a *moment of value*, not a calendar event. The trick: don't show on time of day or app open — show after the user just *did something good* (created their 7th habit check-in, finished an AI reflection, kept a 14-day streak).

**Day 18 prompt — celebration framing.**
Trigger: any positive moment.
> [It's been three weeks. You've kept [N] notes and [M] habit check-ins.]
> [The preview has 3 days left. Want to keep going?]
> CTA: [See Pro] ┃ [Maybe later]

**Day 19 prompt — value framing.**
Trigger: AI reflection completed.
> [You used your AI reflections [K] times this week.]
> [Pro is $9.99 once, and your reflections keep coming.]
> CTA: [Get Pro] ┃ [Maybe later]

**Day 20 prompt — last-call framing.**
Trigger: habit check-in or note save.
> [Tomorrow your preview ends. After that you'll keep your notes and existing habits — but new habits, AI, and backup pause until you go Pro.]
> CTA: [Go Pro now] ┃ [I'll decide tomorrow]

**State after each prompt is dismissed:** dismissal counter increments. After 1 dismissal in a 24h window, no further prompts that day. This avoids the "every-time-I-open-the-app" hostility.

**State if user taps "Get Pro" on any prompt:** open the paywall (§1.5).

### 1.4 Day 21 transition

At the moment `now() >= preview_started_at + 21 days`:

1. Server marks the entitlement `state: 'RESTRICTED'` and pushes a fresh JWT to the client on next sync.
2. On next app open, client detects the state change and shows a one-time **transition screen**:
   > [Your 21 days are complete.]
   >
   > [What stays: ✓ all your notes, with new entries any time. ✓ your habits, checked in daily.]
   >
   > [What pauses without Pro: + new habits and edits. + the AI assistant. + backup & restore across devices.]
   >
   > CTA: [Get Pro — $9.99] ┃ [Continue free]
3. Whichever button the user taps, dismiss the screen. **Never show this transition screen twice** — annoying.

Important UX detail: don't *change the app's appearance* on Day 22. The user should still see all their notes, all their habits, and a friendly app. The lock manifests only when they try to do something locked (see §1.6).

### 1.5 Paywall screen anatomy

The paywall is the single screen most people will see when they decide. Spend design time here.

**Above the fold (no scroll required):**

```
┌────────────────────────────────────────────┐
│                                            │
│        ✨  [Tessera + crystal star]         │
│                                            │
│              Blinking Pro                  │
│         A one-time purchase that           │
│         unlocks the app for life.          │
│                                            │
│                  $9.99                     │
│           [Get Pro — $9.99]   ◀ Primary    │
│                                            │
│         [Restore Purchases]   ◀ Required   │
│                                            │
└────────────────────────────────────────────┘
```

**Below the fold (scroll for detail):**

What you get with Pro, all checkmarked:
- Notes: full editing + delete
- Habits: add, edit, delete, check-in
- AI assistant: 1,200 reflections per year of ownership
- Backup & restore across devices
- Share to Chorus

What stays free even without Pro:
- Read all your notes, add new ones
- Check existing habits

Toward the bottom, in smaller copy:
> [No subscription, no recurring billing. One purchase, yours forever.]
> [If you outgrow the included AI: bring your own API key, free; or top up at $4.99 / 500.]
> [Family Sharing supported.]
> [Privacy policy ┃ Terms]

### 1.6 Purchase from RESTRICTED state — the re-engagement triggers

Most of your long-tail purchase volume will come from RESTRICTED users hitting a *moment of friction* — they want to do something, they hit the lock. Each lock = a purchase opportunity. Design each one to be calm but useful.

| Trigger | Suggested copy | CTA |
|---|---|---|
| User taps "+ New habit" | [Adding new habits is part of Pro. Want to unlock?] | [Get Pro — $9.99] / [Not now] |
| User taps the AI button | [The AI assistant is part of Pro. You have [3 - used] reflections left this month, then it pauses.] | [Get Pro — $9.99] / [Not now] |
| User opens Settings → Backup | [Backup is part of Pro. Your notes are still safe locally.] | [Get Pro — $9.99] / [Not now] |
| User edits an existing note | [Edits to existing notes are part of Pro. You can still add new notes.] | [Get Pro — $9.99] / [Not now] |
| User installs on a new device, no backup | (Detected via no-cloud-data + new device) | [Move your notes from your other device with Pro Backup.] / [Get Pro — $9.99] |

**Frequency cap:** any single trigger fires its prompt at most once per 7 days per user. Don't let the user feel pestered.

### 1.7 Restore Purchases

Required by App Store guideline 3.1.1; also a real UX need (users buy on phone, install on tablet).

**Where it lives:**
- Visible button on the paywall (always)
- Settings → Account → "Restore Purchases"

**Flow:**
1. User taps Restore Purchases.
2. Client calls `[StoreKit / Play Billing / RevenueCat] restorePurchases()`.
3. Server cross-references the returned receipts against the user's entitlement record.
4. If a valid Pro receipt is found: state → PAID, push new JWT, show toast `[Welcome back. Pro is active.]`
5. If no valid receipt: show alert `[No previous Pro purchase found for this account.]` with a `[Get Pro]` CTA.

**Edge case:** user is in PREVIEW and taps Restore. Same flow; if they have a valid past Pro purchase, they jump straight to PAID and the preview is irrelevant.

### 1.8 State machine summary

```
            first launch
                ▼
            ┌────────┐
            │PREVIEW │  21-day window. No countdown shown
            │        │  in main UI. AI = 9/day.
            └───┬────┘
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
   purchase  21d elapsed  restore w/ existing receipt
       │        │              │
       │        ▼              │
       │   ┌──────────┐        │
       │   │RESTRICTED│        │
       │   │          │        │
       │   │AI=3/mo   │        │
       │   │+notes,   │        │
       │   │check-ins │        │
       │   └────┬─────┘        │
       │        │              │
       │        ▼  purchase    │
       │   (or restore)        │
       ▼        ▼              ▼
            ┌────────┐
            │  PAID  │  Permanent. AI = 1,200/year.
            │        │  No expiry, no renewal.
            └────────┘
```

---

## 2. Floating AI button — state & message lifecycle

The floating AI button is the most-seen surface in the app. Today it has two states (active / grey) tied to a single condition: "do you have an API key?" Under the new entitlement model, that condition is wrong for almost every user — most people will never need to enter a key, because managed AI is included.

This section replaces that single condition with a state-and-message matrix that mirrors §1's entitlement state machine plus AI-quota and BYOK substates.

### 2.1 What's wrong with the current behaviour

Today:
- Button greys out when no API key is configured.
- Tap (or hover/long-press) shows: *"Add your API key in Settings → AI providers to use the assistant"*

Under the new flow, this is correct in **exactly one** narrow case (PAID user has explicitly enabled BYOK and their key has become invalid). For every other user — the entire PREVIEW cohort, the entire RESTRICTED cohort, and the ~85% of PAID users who never touch BYOK — that message is misleading. A first-time user opening the app sees a greyed-out AI button and a "bring your own API key" message — exactly the wrong first impression for an app whose pitch is "AI included with one purchase."

### 2.2 Two visual states (with one warn variant)

| State | Visual | Animation |
|---|---|---|
| **ACTIVE** | Full Tessera-fragment colors (teal palette) + crystal-star sparkle | Subtle breath cycle, 4s period, ±5% scale |
| **DORMANT** | Greyscale (~30% saturation), reduced opacity ~60% | None |
| **DORMANT-WARN** | Greyscale + small amber dot in upper-right | None (the dot is the signal) |

DORMANT-WARN is reserved exclusively for "your BYOK key is broken" because that's the only state where the user has *taken an action* and the action has *quietly stopped working*. Every other DORMANT state is a known, expected condition (out of quota, network error, etc.).

The button **does not disappear** in any state — it stays in its position. Hiding the button when AI is unavailable creates a "did the AI feature go away?" anxiety that is worse than the temporary grey state.

### 2.3 The state decision matrix

This is the master table. Every cell maps an entitlement+AI substate to (1) what the button looks like, (2) what tapping it does, (3) what message — if any — surfaces.

| Entitlement | AI substate | Button | Tap action | Message |
|---|---|---|---|---|
| **PREVIEW** | quota remaining (<9 used today) | ACTIVE | Open AI assistant | — |
| **PREVIEW** | daily quota exhausted (9 used today) | DORMANT | Toast | *[You've used today's 9 reflections. They refresh tomorrow.]* |
| **RESTRICTED** | monthly quota remaining (<3 this month) | ACTIVE | Open AI assistant | (Optional countdown badge: e.g., "2 left this month") |
| **RESTRICTED** | monthly quota exhausted (3 this month) | DORMANT | Open paywall | *[Pro brings the AI assistant back — 1,200 reflections per year, one-time purchase.]* |
| **PAID — managed** | annual quota remaining OR top-up credits remaining | ACTIVE | Open AI assistant | — |
| **PAID — managed** | annual = 0 AND top-ups = 0 | DORMANT | Open denial-moment sheet (§4.2 A) | *[All reflections used. Top up, bring your own key, or wait until [date].]* |
| **PAID — BYOK enabled** | key valid | ACTIVE | Open AI assistant | — |
| **PAID — BYOK enabled** | key invalid (401/403) | DORMANT-WARN | Open BYOK setup screen | *[Your API key needs attention. Tap to update.]* |
| Any | active AI call in flight | ACTIVE + pulse | (button disabled during call) | — |
| Any | network unreachable | DORMANT (transient, 60s) | Toast + retry | *[Couldn't reach the AI service. Tap to retry.]* |
| Any | provider down (5xx) | DORMANT (transient, 5min) | Toast | *[[Provider] is having issues. Try again in a few minutes.]* |
| Any | onboarding screens 1–3 visible | hidden | n/a | — |
| Any | modal screens (paywall, BYOK setup) visible | hidden | n/a | — |

The matrix is the source of truth. When something feels off in QA, walk through it row-by-row.

### 2.4 Long-press for status

A long-press on the floating button (any state) opens a small status overlay anchored above it:

```
┌─────────────────────────────────────┐
│  AI assistant                        │
│                                     │
│  ◯ Source:  Included quota          │
│  ◯ This year:  734 of 1,200 left    │
│  ◯ Top-ups:  500 (added Apr 2)      │
│  ◯ Refills:  Apr 12, 2027           │
│                                     │
│        [Use my own key]             │
└─────────────────────────────────────┘
```

In RESTRICTED:
```
│  ◯ Source:  Included taste          │
│  ◯ This month:  2 of 3 left         │
│  ◯ Refills:  June 1                 │
│        [Get Pro]                     │
```

In BYOK mode:
```
│  ◯ Source:  Your Anthropic key      │
│  ◯ Quota:  Yours, no count          │
│        [Switch to included quota]   │
```

This solves "where am I?" anxiety in one gesture. Without it, users will keep checking Settings to recompute their state.

### 2.5 Tap behaviour, in detail

The "tap → context-aware action" rule from the matrix needs care. A few principles:

- **The DORMANT tap should never be a dead end.** If the button is grey, tapping it must lead somewhere productive — a path to make AI available, or at minimum a clear explanation of when it returns.
- **Don't open the paywall from a PREVIEW DORMANT state.** A PREVIEW user who's hit their daily 9 should *not* be paywalled — they're still in their preview. Show the toast and let them come back tomorrow. Paywalling here is hostile and hurts later conversion.
- **Single-tap resolves; long-press informs.** A single tap on a DORMANT button takes the user to the action; long-press shows the status overlay regardless of state.
- **Animation feedback is enough; don't add spinners on top.** When an AI call is in flight, the button's pulse animation is the loading indicator. Don't stack a separate spinner — looks busy.

### 2.6 Animation lifecycle

| Moment | Animation |
|---|---|
| App open (button enters view) | Fade-in 300ms, settle into resting state |
| Resting (ACTIVE) | Breath: scale 1.0 → 1.05 → 1.0 over 4s, opacity steady |
| Resting (DORMANT) | None |
| Tap (ACTIVE) | Quick scale-bounce (1.0 → 0.92 → 1.0 in 180ms) |
| AI call in flight | Pulse: scale 1.0 ↔ 1.04, 600ms cycle |
| Call success | Return to resting breath |
| Call fails (network/provider) | Brief shake (±3px, 250ms) → DORMANT |
| State transition (e.g., last call exhausted quota) | 200ms cross-fade from ACTIVE to DORMANT |
| Long-press | Status overlay slides up from button position, 200ms |

The overall feeling should be that the button is *alive but quiet*. No bouncing, no constant motion — the breath cycle is meant to be barely perceptible.

### 2.7 Lifecycle across the user journey

A composite view of how the button changes from first launch through Day 30+:

| Moment | State | Why |
|---|---|---|
| First launch, onboarding screens 1–3 | hidden | Don't compete with the philosophy hook |
| Just after "Start your 21 days" tap | ACTIVE (fade-in) | The user enters the app for the first time |
| Day 1, after their first AI call | ACTIVE | quota remaining |
| Day 1, after 9th AI call | DORMANT (transition) | daily quota hit |
| Day 2, app open | ACTIVE | quota replenished |
| Days 2–17 | ACTIVE / DORMANT cycle daily | Normal use |
| Days 18–20 | ACTIVE / DORMANT cycle daily | Soft purchase prompts fire from §1.3, button itself doesn't escalate |
| Day 21 transition screen | hidden | Modal screen |
| Day 22 (RESTRICTED, no purchase) | ACTIVE if any of 3 monthly calls remain | RESTRICTED has 3/month |
| Day 22 (RESTRICTED, monthly used) | DORMANT, tap → paywall | Conversion trigger |
| Day 22 (PAID, just purchased) | ACTIVE | annual quota live |
| Months later, PAID user enables BYOK | ACTIVE (with "your key" badge in long-press overlay) | BYOK mode |
| Year later, BYOK key revoked | DORMANT-WARN, tap → BYOK setup | The narrow case where the original "fix your key" message is correct |

### 2.8 Migration notes (replacing the current behaviour)

When implementing this:

1. **Remove the single-condition logic.** Find every place in the codebase that asks "is there an API key?" and replace with "what is the current entitlement+AI state?"
2. **Centralise the state computation.** The button's visual state should be derived from one observable (e.g., a single `AIButtonState` enum with 9 cases matching the rows of §2.3). Avoid scattering the logic across the view layer.
3. **Replace the message string with a localised lookup table.** One key per row of §2.3, not one message hardcoded in the view.
4. **The Settings entry-point name** referenced in your current message ("Settings → AI providers") should be reconsidered. Under the new flow, the section name "AI" is more honest because it covers managed quota, BYOK, and top-ups in one place. Suggested renaming: **Settings → AI** with sub-rows for "Annual quota," "Top-up credits," "Use my own key," and an advanced "Provider settings" deep-link.
5. **QA path:** walk through every row of the §2.3 matrix in a fresh test account. The flaky cases historically are: PREVIEW → RESTRICTED transition at midnight; BYOK key validity drift (key revoked between sessions); offline → online quota reconciliation.

### 2.9 Copy summary — every message that the button can produce

For ease of localisation and review, the complete set of strings:

| Trigger | Copy |
|---|---|
| PREVIEW daily quota hit | *[You've used today's 9 reflections. They refresh tomorrow.]* |
| RESTRICTED monthly quota hit | *[Pro brings the AI assistant back — 1,200 reflections per year, one-time purchase.]* |
| PAID quota + top-ups exhausted | *[All reflections used. Top up, bring your own key, or wait until [date].]* |
| BYOK key invalid | *[Your API key needs attention. Tap to update.]* |
| Network unreachable | *[Couldn't reach the AI service. Tap to retry.]* |
| Provider down (5xx) | *[[Provider] is having issues. Try again in a few minutes.]* |
| Long-press status (managed) | *[Source: included quota. [N] of 1,200 left this year. Refills [date].]* |
| Long-press status (BYOK) | *[Source: your [provider] key. Quota: yours, no count.]* |
| Long-press status (RESTRICTED) | *[Source: included taste. [N] of 3 left this month. Refills [date].]* |

Eight strings cover every state. The current single-message implementation can be confidently retired.

---

## 3. BYOK setup flow (simplified)

The current flow is too complex (per your note). Here's a 3-step replacement that respects the "*your data goes straight to the model provider*" privacy story without forcing the user through a wizard.

### 3.1 Design principles

1. **Minimum viable input.** One provider choice + one key. Nothing else.
2. **No model selection.** App picks the best Haiku-class default per provider. Power users who want to override get a single advanced setting buried under "Show advanced."
3. **Validate immediately.** Test the key with a one-token "ping" call before saving. If it fails, show why in plain English, not the raw API error.
4. **Switching is reversible.** A toggle, not a one-way migration.
5. **Privacy is the headline, not a footnote.** The setup screen leads with the privacy benefit, not the cost benefit.

### 3.2 Three-step setup (Pro only)

**Settings → AI → Use my own key**

Tapping this row opens a single screen (not a multi-screen wizard):

```
┌────────────────────────────────────────────┐
│  ←  Use my own key                          │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Your data goes straight to the      │  │
│  │  model provider. Blinking never      │  │
│  │  sees it.                            │  │
│  │  [Why?]                               │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Provider                                  │
│  ( ) Anthropic    (•) OpenAI    (...)      │  ◀ [providers]
│                                            │
│  API Key                                   │
│  ┌──────────────────────────────────────┐  │
│  │ sk-ant-...                          ⓘ │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  [Where do I get a key?]                    │
│                                            │
│         [Test and save]    ◀ Primary       │
│         [Cancel]                            │
│                                            │
│  ▼ Show advanced (model override)           │
└────────────────────────────────────────────┘
```

That's the whole screen. Three controls: provider radio, key text field, "Test and save."

### 3.3 Validation contract

When user taps "Test and save":

1. Client validates basic key format (length, prefix matches provider).
2. Client makes one call to the provider with a fixed test prompt:
   - Anthropic: `messages.create({ model: <default>, messages: [{role:'user', content:'OK'}], max_tokens: 1 })`
   - OpenAI: `chat.completions.create({ model: <default>, messages: [{role:'user', content:'OK'}], max_tokens: 1 })`
3. **Outcomes:**

| Result | What user sees |
|---|---|
| 200 OK | [Connected. Your AI now uses your own key.] (toast) → screen closes |
| 401/403 | [That key wasn't accepted. Double-check it's correct and hasn't been revoked.] |
| 429 | [Your provider account is rate-limited. Try again in a minute.] |
| 402 (payment required) | [Your provider account doesn't have credits. Add billing on the [provider] dashboard.] |
| Network error | [Couldn't reach [provider]. Check your connection.] |
| Other error | [Something went wrong. Code: [XXX]. [Copy details]] |

**Never store an unvalidated key.** No "save anyway" option. If validation fails, the user is bounced back to the form with the field still populated (so they can fix a typo).

### 3.4 Toggling between managed and BYOK

Once a key is saved, the AI section in Settings shows:

```
AI source: Your own key  ◀ tap to change
└─ Provider: [Anthropic]
└─ Key: sk-ant-•••••••••••dEf  [Replace] [Remove]
└─ [Switch back to included quota]
```

"Switch back to included quota" is one tap, no confirmation. The key stays saved (so the next toggle is also one tap). To fully *remove* the key, separate "Remove" button with a confirmation.

**Visual indicator in the AI UI:** a small badge next to the AI button or in the reflection UI:
- Managed mode: `[1,200 left]` (count of remaining annual quota)
- BYOK mode: `[your key]` (no count, since it's their bill)

This prevents the "wait, did my key turn off?" confusion that's the #1 BYOK support ticket pattern.

### 3.5 Privacy disclosure — "Why?"

Tapping the [Why?] link in the privacy banner opens a sheet:

> **Where your AI requests go.**
>
> When you use your own key, every AI request goes from your phone directly to [provider] and the response comes back to your phone. Blinking never sees the request, the response, or your key.
>
> When you use the included AI, requests go through Blinking's server (so we can manage your annual quota) before being forwarded to [provider]. We don't store the content; we count the call.
>
> Either way, [provider] processes the content under their own privacy policy: [link to provider's policy].

### 3.6 Key storage

- iOS: Keychain, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Android: EncryptedSharedPreferences with `MasterKey.Builder().setKeyScheme(AES256_GCM)`
- Never sync the key via cloud backup. Even iCloud/Google Drive backups should be opted out for this entry.
- On device wipe / app uninstall: key is gone, user re-enters on next install. This is correct behaviour.

### 3.7 Error states the simplified flow handles

| State | Behaviour |
|---|---|
| Key works, then revoked later | Next AI call fails → toast: [Your saved key was rejected. Tap to update.] → opens settings |
| Key valid, but provider down | Single AI call fails → user sees [provider] is having issues, retry in a few minutes. App doesn't fall back to managed (would silently spend their quota). |
| User wants to use managed today, BYOK tomorrow | Toggle freely; both states preserved. |
| Family Sharing member adds their own BYOK | Their key, their settings, their reflection — independent of the buyer. Server tracks per-family-member separately. |

### 3.8 What was removed vs. a "current" complex flow

If your current BYOK has any of these, drop them in v1:

- ✗ Custom API endpoint field (only sophisticated users need this; ship as advanced setting later if requested)
- ✗ Model dropdown with 5+ choices (pick one default per provider; "advanced" override exists but is hidden)
- ✗ Temperature / max tokens / top-p sliders (defaults work for journaling-app prompts)
- ✗ Multi-step wizard with progress dots (single screen, two states: not-set, set)
- ✗ Pre-validation manual "test" button before save (auto-validate on save)
- ✗ Required name/label for the key (auto-derived from provider)

---

## 4. Top-up purchase flow

### 4.1 Yes — top-ups are in-app purchases (consumable)

To answer the literal question: top-ups are **consumable IAPs**, distinct from the Pro one-time non-consumable IAP.

| | Pro unlock | Top-up pack |
|---|---|---|
| IAP type | Non-consumable | **Consumable** |
| Restoreable | Yes (Restore Purchases works) | No (Apple/Google policy) |
| Refundable | Standard refund window | Standard refund window |
| Family Sharing | Yes | No |
| Receipt validation | Server (one-time, then trusted) | Server (per purchase, credits added) |

Both go through the same store flow (StoreKit / Play Billing). Only Pro shows up in "Restore Purchases."

### 4.2 Trigger points

Top-ups can be purchased from two places:

**A. The denial moment** (highest-conversion trigger). When a Pro user attempts an AI call and is out of quota:

```
┌────────────────────────────────────────────┐
│                                            │
│         You've used all 1,200 of           │
│         your AI reflections this year.     │
│                                            │
│  Your quota refills on April 12, 2027.     │
│                                            │
│         Three ways to keep going:          │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Get more AI reflections             │  │
│  │  500 reflections — never expire      │  │
│  │           [$4.99]                    │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Use your own key                    │  │
│  │  Free, unlimited, your data stays    │  │
│  │  with the provider.                  │  │
│  │           [Set up]                   │  │
│  └──────────────────────────────────────┘  │
│                                            │
│         [Wait until refill]                 │
│                                            │
└────────────────────────────────────────────┘
```

**B. Pre-emptive** (lower volume but helpful). Settings → AI → Get more reflections.

### 4.3 Purchase screen anatomy

If the user taps `[$4.99]`:

1. **No intermediate confirmation in your app.** Apple/Google's native sheet handles confirmation (Face ID / fingerprint / password). Adding your own confirmation step on top is friction theatre and reduces conversion by ~10%.
2. **Native sheet appears** with the IAP `[providerSku: blinking_topup_500]` showing $4.99 and the user's stored payment method.
3. User confirms with biometric / passcode.

### 4.4 Post-purchase flow

```
1. Store completes purchase, returns receipt to client.
2. Client uploads receipt to your server.
3. Server verifies receipt with Apple/Google verify endpoints.
4. Server credits user's account: { topup_credits: existing + 500 }.
5. Server returns success + new credit total.
6. Client shows toast: [Added 500 reflections. You have 500 available.]
7. Client immediately makes the AI call the user originally tried (the one that hit zero quota).
```

The last step is the magic moment — the user pays, *and the thing they were trying to do happens*. Don't make them re-tap the AI button.

### 4.5 Server-side credit accounting

```
user_account {
  user_id: ...
  state: PAID
  pro_purchased_at: ...
  annual_quota_remaining: 0       # 0–1,200 for current year
  annual_quota_resets_at: ...     # purchase anniversary
  topup_credits: 500              # never expire, separate ledger
  ...
}
```

**Order of consumption when an AI call fires:**
1. Decrement `annual_quota_remaining` if > 0.
2. Otherwise decrement `topup_credits` if > 0.
3. Otherwise reject the call with "out of AI" denial UX.

**Never let credits go negative.** Race-condition-safe: a single SQL transaction with `WHERE annual_quota_remaining > 0 OR topup_credits > 0` and a deny-with-retry path on contention.

### 4.6 Edge cases

| Case | Handling |
|---|---|
| User buys top-up, then provider charges fail later | Server rolls back the credit grant. User sees `[Your purchase didn't complete. No charge was made.]` |
| User buys top-up, then refunds via Apple | Webhook from Apple → server decrements `topup_credits` by 500 (or to zero, whichever larger). If they've already used some, the balance can go negative — track it and don't grant new packs until cleared. |
| User uninstalls and reinstalls — top-up credits restored? | **Yes**, server-side ledger persists and is keyed to Apple/Google account, not device. They sign in, server returns their balance. |
| User buys 5 packs at once | Stacking works: 5 × 500 = 2,500 top-up credits, plus their annual quota. |
| Family member tries to use buyer's top-ups | **No** — top-ups are consumable, scoped to the purchasing account. Family members get their own annual quota (Pro is shared via Family Sharing) but must buy their own top-ups. |
| User in PREVIEW or RESTRICTED tries to buy a top-up | Block: `[Top-ups are for Pro users. Get Pro to unlock the AI assistant.]` → CTA to paywall. Don't allow consumable purchases without entitlement; they don't help and complicate accounting. |

### 4.7 Display in app

The top-up balance is visible in three places:

1. **Settings → AI** (always):
   > [Annual quota: 247 of 1,200 remaining.]
   > [Top-up credits: 500.]
   > [Total available: 747.]

2. **AI button badge** (when low quota): the badge shows the *combined total* of annual + top-ups. The user shouldn't have to reason about which bucket gets used first.

3. **After every AI call** (subtle): a brief flash on the count, no toast. The badge just decrements.

---

## 5. Cross-flow notes

### 5.1 Server-side data model

Single source of truth. The client mirrors a subset.

```
user_account {
  user_id                            # Apple sign-in / Google Play Services ID
  state                              # PREVIEW | RESTRICTED | PAID
  preview_started_at
  pro_purchased_at                   # null until PAID
  annual_quota_remaining             # 0–1,200, server-managed
  annual_quota_resets_at             # = pro_purchased_at + N years
  topup_credits                      # never expire, separately tracked
  byok {
    enabled: bool                    # toggle without removing key
    provider: 'anthropic' | 'openai' | ...
    key_encrypted: bytes             # encrypted at rest, never logged
    last_validated_at: timestamp
  }
  family_sharing_role                # 'buyer' | 'member' | null
}
```

### 5.2 What you need before launch (BL-04 sub-tasks)

In rough build order:
1. Server: entitlement state machine + JWT minting + receipt validation endpoints (Apple + Google).
2. Server: AI quota counter with concurrency-safe decrement (annual + top-up ledger).
3. Client: state-aware feature gates wired to JWT (every AI/habit/backup call asks "what's my state?").
4. **Client: floating AI button state machine (§2.3) — replaces the current single-condition grey/active behaviour.** This is foundational; almost every other flow surfaces through this button.
5. Client: paywall screen (§1.5).
6. Client: BYOK setup screen (§3.2).
7. Client: top-up purchase + denial-moment screen (§4.2 A).
8. Client: re-engagement triggers in RESTRICTED (§1.6).
9. Client: Restore Purchases.
10. Onboarding (§1.1).
11. Soft purchase prompts (§1.3) — these can ship in v1.0.1 if Day 18+ logic isn't ready by launch.

### 5.3 What can wait until v1.1

- Family Sharing edge cases (§4.6 last row) — most users won't hit it for weeks
- Provider override / custom endpoint in BYOK
- Top-up volume packs (e.g., $9.99 / 1,250 with a small "discount" framing)
- A "How much have I used?" stats screen — interesting but not blocking

---

*End of design flows v1. Re-cut after first 100 paying users surface real edge cases.*
