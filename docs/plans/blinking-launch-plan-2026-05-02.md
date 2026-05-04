# Blinking Launch Plan — Android & iOS
**Created:** 2026-05-02
**Version:** 1.1.0 (target production)
**Status:** Pre-launch — Android ready, iOS submitted. One item remaining: Play Store production promotion.

---

## 1. Executive Summary

Blinking (记忆闪烁) is a bilingual (EN/ZH) personal memory journal and habit tracker with an AI assistant that reads your entries and holds reflective conversations. The app is built in Flutter and targets both Android and iOS.

**Current state:** Android is launch-ready (96/96 tests, 0 lint errors, AAB 52.3MB). iOS App Store submission is done. Both platforms use the same Flutter codebase.

**Launch window:** May 2026. Android first (week 3), iOS follows (week 4, dependent on App Review timelines).

---

## 2. Competitive Analysis

### 2.1 Market Landscape

The personal journaling + habit tracking market is crowded with established players. Blinking differentiates on three axes: **AI conversational reflection**, **bilingual first-class support**, and **unified journal + habits in one app** (most competitors do one or the other).

### 2.2 Direct Competitors

| App | Category | AI | Bilingual | Journal | Habits | Pricing |
|-----|----------|:--:|:---------:|:-------:|:------:|---------|
| **Daylio** | Mood + habits | No | No | Light | Yes | Freemium ($3–6/mo or $24/yr) |
| **Day One** | Journal | No | No | Rich | No | Premium ($35/yr) |
| **Reflectly** | AI journal | Basic | No | Light | No | $10/mo or $60/yr |
| **Streaks** | Habit tracker | No | No | No | Yes | $5 one-time |
| **格志 (Grid Diary)** | Journal (CN) | No | ZH only | Rich | No | Freemium |
| **吾记** | Diary (CN) | No | ZH only | Basic | No | Free (ads) |
| **Moodnotes** | CBT journal | No | No | Light | No | $5 one-time |
| **Blinking** | Journal + habits | **Yes** | **EN + ZH** | Yes | Yes | Free + bring-your-own-key |

### 2.3 Competitive Positioning

| Strength | Blinking Advantage |
|----------|-------------------|
| **AI assistant (unique)** | No competitor offers multi-turn reflective AI chat that reads your journal entries and habits. Reflectly has basic AI prompts but they are scripted, not conversational. The "Save Reflection" feature (auto-tag + save AI response as a journal entry) is unique. |
| **Bilingual first-class (unique)** | Every string, every label, every feature works in both English and Chinese. Chinese journal apps are Chinese-only; English journal apps are English-only. Blinking serves both audiences natively — a strong advantage for bilingual users and cross-cultural families. |
| **Journal + Habits unified (rare)** | Daylio does both but journaling is extremely lightweight (emoji + one-liner). Blinking has rich text, images, daily checklists, AND habit tracking. Users don't need two apps. |
| **Local-first + privacy** | All data stored locally (SQLite). No account required. AI Secrets tag excludes private entries from AI context. Export/import (ZIP + JSON) for data portability. |
| **Bring-your-own-API-key model** | Users control their AI costs. The 7-day free trial removes onboarding friction for non-technical users. No ongoing subscription burden for the developer. |

### 2.4 Weaknesses / Gaps vs Competitors

| Gap | Severity | Plan |
|-----|----------|------|
| No cloud sync | High | Firebase deps exist but not yet implemented. Users switching phones must manually export/import. Competitors all have sync. |
| No push notifications | Medium | `flutter_local_notifications` was previously integrated but removed. Competitors use reminders for habit adherence. |
| No rich media (video/audio) | Low | Removed in v1.1.0. Day One supports audio. Blinking is text + images only. |
| No Apple Health / Google Fit integration | Low | Daylio syncs with Health. For habits, this is a future advantage. |
| New brand, no reviews | High (marketing) | All competitors have years of reviews, ratings, and SEO. |

---

## 3. Pricing Analysis

### 3.1 Current Model: 100% Free + BYOK (Bring Your Own API Key)

| Feature | Status | Cost to User | Cost to Developer |
|---------|--------|:-----------:|:-----------------:|
| Journal entries (unlimited) | Free | $0 | $0 (local SQLite) |
| Habits/routines (unlimited) | Free | $0 | $0 (local) |
| Image attachments | Free | $0 | $0 (local files) |
| Emotion tracking | Free | $0 | $0 (local compute) |
| Daily checklists | Free | $0 | $0 (local) |
| Insights charts | Free | $0 | $0 (local compute) |
| Export/import (ZIP + JSON) | Free | $0 | $0 (local) |
| AI assistant (own key) | Free | ~$0.50–5/mo (OpenRouter) | $0 |
| 7-day AI trial | Free | $0 | ~$0.05–0.20/user |

**Reality check:** Everything costs $0 to provide. Blinking has no servers, no sync infrastructure, no cloud storage. The only component with real marginal cost is the AI trial (Cloudflare Worker + OpenRouter proxy). This is both a strength (no cost pressure to monetize) and a challenge (no natural feature to charge for).

### 3.2 The "What Do We Actually Sell?" Problem

Most apps gate features behind a paywall. Blinking can't easily do this because:

| Common Pro Feature | Does Blinking Have It? | Viable to Charge For? |
|--------------------|:----------------------:|:---------------------:|
| Unlimited entries | Yes — already free | ❌ Removing it would cripple the app |
| Unlimited habits | Yes — already free, user-created | ❌ "Pay for more habits you make yourself" makes no sense |
| Cloud sync | No — local only with export/restore | ❌ Doesn't exist |
| Advanced analytics | Basic — 4 chart types | 🟡 Could expand to trends, predictions |
| Themes/customization | Minimal | 🟡 Cosmetic only — see §3.3 |
| AI assistant | Yes — BYOK or trial | ✅ Only feature with real cost |
| Data export | Yes — already free | ❌ Removing it would be anti-user |
| Priority support | No | 🟡 Low-value add-on |

**The honest conclusion:** The only thing Blinking can legitimately charge for is the AI assistant. Everything else is local, already free, and costs nothing to provide. Charging for habits, entries, or export would be extractive and alienate users. Charging for non-existent features (cloud sync) would be dishonest.

This is actually a **strong position** — it means the free tier is genuinely complete, and the paid tier solves one clear problem: "I want AI but don't want to manage API keys."

### 3.3 Theme Willingness-to-Pay Analysis

Themes are often floated as a monetization lever. Here's the data on whether users actually pay for them:

#### Market Data

| App Category | Theme/Skin Revenue | Evidence |
|-------------|:------------------:|----------|
| Games (Fortnite, Honor of Kings) | **Very high** — billions in skin revenue | Skins express identity in social/multiplayer contexts |
| Social apps (QQ, WeChat) | **Moderate** — sticker/theme stores exist, low individual prices | China market: QQ Show, WeChat Sticker Gallery. Small revenue per user, large volume. |
| Productivity apps (Notion, Todoist) | **Low** — themes bundled with premium, never sold standalone | Notion: themes in free tier. Todoist: themes in Premium ($4/mo) but not the reason users upgrade. |
| **Journal apps (Day One, Daylio)** | **Very low** — always bundled, never the purchase driver | Daylio's Premium reviews never mention themes. Day One bundles everything. Zero journal apps sell standalone themes. |
| Utility apps (白描, 钱迹) | **Near zero** | These apps sell on function, not form. |

#### Why Themes Don't Sell in Journal Apps

1. **Journals are private.** Unlike games or social apps, nobody sees your journal theme. There's no social signaling value.
2. **The default theme is "good enough."** A clean, dark/light, readable interface is what journalers want. Ornate themes feel gimmicky.
3. **Themes don't solve a problem.** Users pay to remove pain (ads, limits, friction). Themes add pleasure — a weaker motivator.
4. **Custom backgrounds are free.** Users can already attach images to entries. A custom card background isn't meaningfully different.

#### What DOES Work: Customization as Retention, Not Revenue

Users who personalize an app are more likely to stay. Custom accent colors, font choices, and layout options increase stickiness — but as **free features**, not paid ones. Day One lets you change journal covers for free. Notion lets you change page icons for free.

**Recommendation:** Offer 2–3 free themes (light, dark, sepia/paper). If Pro tier exists, add 6 more as a bonus — but never position themes as the reason to pay. They're garnish, not the meal.

#### Competitor Pricing Reference

| App | Free Tier | Premium (Monthly) | Premium (Annual) | Lifetime |
|-----|-----------|:-----------------:|:----------------:|:--------:|
| Daylio | Basic mood + 1 habit | $3–6 | $24 | — |
| Day One | Limited entries | — | $35 | — |
| Reflectly | Limited prompts | $10 | $60 | — |
| Streaks | — | — | — | $5 |
| Moodnotes | — | — | — | $5 |
| 白描 (CN OCR) | — | — | — | ¥30 |
| 钱迹 (CN finance) | — | — | — | ¥128 |
| 墨墨背单词 | Word limit | ¥12 | ¥88 | ¥168 |
| **Blinking** | Full app (no AI) | — | — | — |

### 3.4 Recommended Strategy: AI as the Only Paid Feature

This is the simplest, most honest model. The full app is free forever. The AI assistant is paid.

#### Phase 1 — Launch (May 2026): 100% Free
No paywall. No Pro tier. No locked features.

| Tier | What You Get | Cost |
|------|-------------|:----:|
| **Free** | Everything — journal, habits, checklists, insights, export, themes | $0 |
| **AI (BYOK)** | Full AI assistant using your own OpenRouter/OpenAI key | ~$0.50–5/mo |
| **AI (Trial)** | 7 days of hosted AI, 20 requests/day | $0 |

**Why:** Launch is about installs, reviews, and word of mouth. A paywall at launch kills growth. The app's competitive advantage is being fully free when every competitor charges.

#### Phase 2 — Post-Launch (v1.2, 3–6 months in): AI Subscription

Once users have experienced the AI assistant via trial and some have set up their own keys, offer a hosted option:

| Tier | Price | What You Get |
|------|:-----:|-------------|
| **Free** | $0 | Everything (journal, habits, insights, export, themes) + BYOK AI |
| **AI Pass** | **$1.99/mo** | Hosted AI (no key needed), unlimited requests, 7-day free trial for new users |

**Why this price:** At $1.99/mo, it's the cheapest AI journal on the market. Reflectly charges $10/mo for scripted (not conversational) AI. At 1,000 subscribers, that's ~$1,990/mo revenue against ~$300–600 in API costs — profitable at any scale. Users who prefer BYOK pay nothing. No one is forced into a subscription.

#### Phase 3 — Optional: Lifetime AI Pass

For the buy-once market (strong in China):

| Tier | Price | What You Get |
|------|:-----:|-------------|
| **AI Pass (Monthly)** | $1.99/mo | Hosted AI, unlimited |
| **AI Pass (Lifetime)** | **$39.99** | Hosted AI, unlimited, capped at 2,000 requests/month (BYOK always unlimited) |

**Why $39.99:** At 2,000 requests/month and ~$0.002/request average cost, the developer's lifetime cost per user is ~$5. Margin is healthy. Price compares favorably to Daylio Premium ($24/yr) — it's 1.6 years of Daylio for a lifetime of AI. In China, ¥198 matches the 墨墨背单词 lifetime price tier.

**Why the cap:** Prevents abuse. A user making 10,000 AI requests/month would cost ~$20/month. The cap protects against unlimited-lifetime being exploited. Power users should use BYOK (or the monthly plan where costs are covered).

#### Revenue Comparison: AI-Only Model

| Scenario | Users | Monthly Revenue | Monthly AI Cost | Net |
|----------|------:|:--------------:|:--------------:|:---:|
| 100 AI subscribers | 100 | $199 | $30–60 | +$139–169 |
| 500 AI subscribers | 500 | $995 | $150–300 | +$695–845 |
| 50 lifetime AI / month | 600/yr | $24,000/yr | ~$3,000/yr | +$21,000/yr |
| 1,000 AI subscribers | 1,000 | $1,990 | $300–600 | +$1,390–1,690 |

### 3.5 What About "Pro Features" Later?

If the app eventually needs more revenue or users ask for premium features, here's what's actually viable — ordered by user value, not developer convenience:

| Feature | User Pain Solved | Dev Cost | Viability |
|---------|:---------------:|:--------:|:---------:|
| **Cloud backup (iCloud/Google Drive)** | "I switched phones and lost data" | Medium (platform APIs) | 🔴 High — #1 request in every journal app review |
| **PDF journal export** | "I want to print/share my journal" | Low | 🟡 Medium — nice-to-have, not urgent |
| **Advanced insights (year-over-year trends)** | "Am I happier this year?" | Medium | 🟡 Medium — data nerds love it |
| **Custom emotion emojis** | "The default emotions don't fit me" | Low | 🟢 Low — cosmetic |
| **Journal templates/prompts** | "I don't know what to write" | Low | 🟡 Medium — helps new users |
| **Passcode/Face ID lock** | "My journal is private" | Low | 🔴 High — privacy is a real concern |

**Recommendation:** If a Pro tier is introduced later, bundle cloud backup + advanced insights + app lock. Keep journaling, habits, export, and BYOK AI free. Don't charge for things users create themselves (habits, entries, checklists).

### 3.6 The Marketing Power of "Everything Free"

The strongest competitive position is the simplest one:

> *"Blinking is completely free. Journal entries, habits, insights, checklists — everything. The only thing that costs money is the AI assistant, and even that's free if you bring your own key."*

This message is:
1. **True** — no gimmicks, no artificial limits
2. **Differentiated** — every competitor has a paywall somewhere
3. **Trust-building** — users are suspicious of "free" apps; being explicit about the model builds credibility
4. **Shareable** — "it's actually free" is the best word-of-mouth marketing

---

## 4. Marketing Strategy

### 4.1 Target Audiences

| Segment | Size | Channel | Message |
|---------|:----:|---------|---------|
| **Bilingual Chinese diaspora** | Large | Xiaohongshu, WeChat, Twitter/X | "A journal that understands both your languages" |
| **Journaling enthusiasts** | Medium | Product Hunt, Reddit (r/journaling, r/digitaljournaling) | "The only journal with AI that reads your entries" |
| **Habit tracker users** | Medium | Reddit (r/habitica, r/productivity), App Store | "Habits + journal in one app, no subscription needed" |
| **AI-curious non-technical users** | Large | TikTok, Instagram Reels | "An AI journal that actually talks to you about your life" |
| **Privacy-conscious users** | Niche | Hacker News, privacy forums | "Local-first journal with AI — your data never leaves your phone unless you choose" |

### 4.2 Launch Channels

#### Pre-Launch (May 1–14)

| Action | Channel | Effort | Status |
|--------|---------|:------:|--------|
| **App Store listings** | Google Play + App Store Connect | ~3h | Android ✅ (needs review), iOS ⏳ |
| **Screenshots (EN + ZH)** | Both stores | ~2h | ⏳ |
| **Feature graphic** | Google Play (1024×500) | ~1h | ⏳ |
| **Privacy Policy page** | GitHub Pages or blinkingchorus.com | ~1h | ⏳ (content exists in docs/) |
| **Press kit** | blinkingchorus.com/press | ~1h | ⏳ |
| **Beta community** | Discord or Telegram group | ~30min | ⏳ |

#### Launch Week (May 15–21)

| Action | Channel | Effort |
|--------|---------|:------:|
| **Product Hunt launch** | producthunt.com | ~3h prep + launch day |
| **Reddit post** | r/androidapps, r/iosapps, r/productivity | ~30min each |
| **Xiaohongshu post** | 小红书 — 2 posts (EN/ZH) | ~1h |
| **Twitter/X thread** | Developer account, #buildinpublic | ~1h |
| **Personal network** | WeChat moments, WhatsApp, email | ~30min |

#### Post-Launch (May 22+)

| Action | Channel | Cadence |
|--------|---------|---------|
| **Feature updates** | All social channels | Per-release |
| **User testimonials** | App Store reviews → repost on social | Weekly |
| **ASO iteration** | Keywords, description, screenshots | Monthly |
| **Content marketing** | Blog/Medium — "How I use AI to reflect on my day" | Bi-weekly |
| **Community engagement** | Reddit, Discord, GitHub | Ongoing |

### 4.3 App Store Optimization (ASO)

#### Keywords (EN)
`journal, diary, habit tracker, mood tracker, AI journal, daily journal, memory, routine, personal diary, reflective journal, gratitude journal, habit builder, self-care, mental health`

#### Keywords (ZH)
`日记, 习惯打卡, 心情记录, AI日记, 记忆, 每日记录, 生活记录, 情绪追踪, 习惯养成, 自我反思, 日记本, 记事本, 每日习惯`

#### App Title
- **EN:** Blinking — AI Memory & Habit Journal
- **ZH:** 记忆闪烁 — AI 记忆与习惯日记

#### Short Description (Google Play, 80 chars)
- **EN:** Capture memories, track habits, and reflect with AI. Bilingual journal app.
- **ZH:** 记录记忆，追踪习惯，与AI对话反思。双语日记应用。

#### Full Description (draft)
> Blinking is a personal journal and habit tracker with a unique twist: an AI assistant that reads your entries and holds real conversations about your life. Write in English or Chinese — the AI understands both.
>
> **Capture your day:** Text notes, daily checklists, images, mood tracking with emoji. **Build habits:** Track daily, weekly, or scheduled routines with completion streaks. **Reflect with AI:** The AI assistant reads your journal and helps you reflect, discover patterns, and gain insights. **Your privacy:** All data stays on your phone. Mark private entries with the "Secrets" tag and the AI won't see them. Export/import your data anytime — no lock-in.
>
> No account required. No subscription. Bring your own AI key or try the 7-day free trial.

### 4.4 Content Marketing Ideas

| Topic | Format | Platform |
|-------|--------|----------|
| "I built an AI that reads my journal — here's what happened" | Blog post | Medium, Substack |
| "5 ways AI reflection changed my journaling habit" | Thread | Twitter/X |
| "Why I made a bilingual journal app" (personal story) | Blog post | Xiaohongshu, Medium |
| App walkthrough video (EN + ZH versions) | Video (2–3 min) | YouTube, Bilibili, TikTok |
| "Local-first vs cloud: Why your journal data should stay on your phone" | Blog post | Hacker News, Medium |

### 4.5 Community Building

| Channel | Purpose | Target |
|---------|---------|--------|
| **Discord server** | Feature requests, bug reports, beta community | 50+ members by month 3 |
| **GitHub** | Open-source roadmap, issue tracker | Public repo (current) |
| **Reddit** | r/blinkingapp or engage in r/journaling, r/productivity | Ongoing |
| **Email list** | Release notes, feature announcements | blinkingfeedback@gmail.com |

### 4.6 Success Metrics (90-Day Post-Launch)

| Metric | Target | Measurement |
|--------|:------:|-------------|
| Total installs (Android) | 500+ | Google Play Console |
| Total installs (iOS) | 300+ | App Store Connect |
| Active installs (month 3) | 200+ (40% retention) | Play Console / ASC |
| App Store rating | 4.5+ | Both stores |
| Number of reviews | 20+ (combined) | Both stores |
| Trial activations | 100+ | Cloudflare Worker analytics |
| Users who add own API key | 20+ | Inferred from trial expiry behaviour |

---

## 5. Pre-Launch Checklist

### 5.1 Android — Pre-Launch (Week 3: May 15–21)

| # | Item | Effort | Status |
|---|------|:------:|--------|
| A1 | Carry-forward simplified: past entries now view-only (no toggle, no edit save) | Done | ✅ Done |
| A2 | Pre-launch smoke tests (15 test cases from launch readiness plan) | ~30min | ⬜ Pending |
| A3 | Review Play Store listing: title, description, screenshots | ~30min | ⬜ Pending |
| A4 | Create feature graphic (1024×500) | ~1h | ⬜ Pending |
| A5 | Generate phone screenshots (EN + ZH, phone + tablet) | ~1h | ⬜ Pending |
| A6 | Set up privacy policy URL (GitHub Pages) | ~30min | ⬜ Pending |
| A7 | Version bump: `1.1.0-beta.6` → `1.1.0` (production) | ~15min | ⬜ Pending |
| A8 | Build & sign production AAB | ~10min | ⬜ Pending |
| A9 | Upload to Play Console → Production | ~10min | ⬜ Pending |
| A10 | Set staged rollout to 10–20% | ~5min | ⬜ Pending |
| A11 | Submit for review | ~5min | ⬜ Pending |

### 5.2 iOS — Pre-Launch (Week 4: May 22–30)

| # | Item | Effort | Status |
|---|------|:------:|--------|
| I1 | Execute 22 TestFlight smoke test cases | ~1h | ✅ Done |
| I2 | Obtain tester feedback (Justin, Jessica, Audrey) | N/A | ✅ Done |
| I3 | Fix any TestFlight issues found | Variable | ✅ Done |
| I4 | Prepare App Store metadata: description (EN+ZH), keywords, subtitle | ~1h | ✅ Done |
| I5 | Generate iOS screenshots (6.9" + 6.5" displays, EN + ZH) | ~1.5h | ✅ Done |
| I6 | Set up App Privacy questionnaire (no data collected) | ~15min | ✅ Done |
| I7 | Set pricing: Free, all territories | ~10min | ✅ Done |
| I8 | Set age rating: 4+ | ~5min | ✅ Done |
| I9 | Build & upload production IPA | ~15min | ✅ Done |
| I10 | Submit for App Review | ~10min | ✅ Done |

### 5.3 Shared — Pre-Launch (Both Platforms)

| # | Item | Effort | Status |
|---|------|:------:|--------|
| S1 | Privacy Policy page live (GitHub Pages or blinkingchorus.com) | ~30min | ⬜ Pending |
| S2 | Terms of Service page live | ~15min | ⬜ Pending |
| S3 | Press kit page (logo, screenshots, description, contact) | ~1h | ⬜ Pending |
| S4 | Product Hunt listing prepared (draft saved) | ~1h | ⬜ Pending |
| S5 | Discord/Telegram community setup | ~30min | ⬜ Pending |

---

## 6. Post-Launch Plan

### 6.1 Week 1–2 Post-Launch (Monitoring)

| # | Item | Priority |
|---|------|----------|
| P1 | Monitor Play Console crash reports + ANRs daily | P0 |
| P2 | Monitor App Store Connect crash reports daily (once iOS live) | P0 |
| P3 | Respond to all App Store / Play Store reviews within 24h | P1 |
| P4 | Monitor trial API key usage (Cloudflare Worker analytics) | P1 |
| P5 | Expand Android staged rollout: 20% → 50% → 100% (if stable) | P0 |
| P6 | Fix any P0 crash bugs within 24h | P0 |

### 6.2 Month 1 Post-Launch (Polish + Feedback)

| # | Item | Priority | Effort |
|---|------|:--------:|:------:|
| Q1 | Calendar list badge indicator (bug-reports #7) | P3 | ~1.5h |
| Q2 | Robot trial/error state clarity (bug-reports #8) | P2 | ~1h |
| Q3 | One-list-per-day transition UX (bug-reports #9) | P3 | ~45min |
| Q4 | Carry-forward banner timing (bug-reports #10) | P3 | ~30min |
| Q5 | List checkbox UX consistency (bug-reports #11) | P3 | ~1h |
| Q6 | Settings trial banner dismiss (bug-reports #12) | P3 | ~45min |
| Q7 | ASO iteration: analyze keyword performance, update | P2 | ~2h |
| Q8 | First content marketing piece published | P2 | ~3h |

### 6.3 Month 2–3 Post-Launch (Growth)

| # | Item | Effort | Depends On |
|---|------|:------:|------------|
| R1 | Build v1.2 roadmap from user feedback | ~1h | User feedback |
| R2 | Firebase / cloud sync implementation | Large (~30–40h) | v1.2 scope decision |
| R3 | Push notification reminders for habits | ~8h | Cloud sync or local |
| R4 | Premium tier implementation (if pursuing paid model) | ~15h | Cloud sync |
| R5 | Apple Watch companion app | Large | iOS traction |

---

## 7. Risk Register

| Risk | Platform | L | I | Mitigation |
|------|----------|---|---|------------|
| Google Play review rejects app | Android | L | H | Nothing in app violates Play policies (no user-generated content store, no deceptive behavior) |
| App Store review rejects (metadata) | iOS | M | M | Prepare privacy policy URL, screenshots, and questionnaire before submission. First submissions often rejected for metadata issues — budget 1–2 rejection cycles. |
| App Store review rejects (Xcode 26 build) | iOS | M | H | Xcode 26.5 beta 3 used for build. If Apple requires GM release, wait for Xcode 26.5 final or downgrade. System-upgrade plan covers this. |
| Crash on specific device/OS versions | Both | L | H | Staged rollout (Android 10–20%) catches this before wide distribution. Fix within 24h. |
| AI trial cost spike | Backend | M | M | Rate limiting (20 req/day/user), kill switch via Workers secret. If costs exceed $100/mo, throttle or disable trial. |
| Low initial installs | Both | H | H | Marketing execution is critical. Product Hunt + Reddit + Xiaohongshu are low-cost high-reach channels. ASO requires iteration. |
| Negative reviews from non-AI users | Both | M | M | AI prominently described in listing. Free tier is fully functional without AI. Make this clear in description. |
| Data loss from export/import bug | Both | L | H | Thoroughly tested (96 tests). Manual smoke test includes export/import round-trip. |
| iOS 26 SDK breaking change in final release | iOS | L | H | Xcode 26.5 beta 3 already validated. Monitor Flutter team-ios issues for new breakages before submission. |
| App Store Connect processing delays | iOS | M | L | TestFlight processing takes 30min–2h. App Review takes 24–48h typical, up to 14 days for first submission. |

L = Likelihood, I = Impact (H/M/L)

---

## 8. Timeline

```
May 2026
├── Week 1 (May 1–7)   ✅ COMPLETED
│   ├── PROP-6, PROP-9, PROP-8, Issues #1, #4, #7, #13, #14
│   ├── 9 UX issues resolved
│   └── iOS TestFlight build uploaded, testers added
│
├── Week 2 (May 2–4)   ✅ COMPLETED
│   ├── Carry-forward redesign (user-prompted flow + "Yesterday" flag)
│   ├── iOS App Store submission
│   ├── Insights tab crash fix
│   ├── Moment tab icon differentiation
│   └── Past-date entries view-only lock
│
├── Week 3 (May 15–21)   📱 ANDROID LAUNCH
│   ├── A1–A11: Android pre-launch checklist
│   ├── Android 1.1.0 released to Production (staged 10–20%)
│   ├── Product Hunt launch
│   ├── Social media launch posts
│   └── Monitor crash rate, reviews
│
├── Week 4 (May 22–30)   📊 POST-LAUNCH
│   ├── Expand Android rollout to 100% (if stable)
│   ├── Monitor iOS App Review + app store status
│   ├── Post-launch polish (Q1–Q6, ~4.5h)
│   └── Content marketing + ASO iteration
│
└── June 2026+
    ├── Post-launch polish (Q1–Q6, ~4.5h)
    ├── ASO iteration
    ├── Content marketing
    ├── v1.2 planning (cloud sync, premium tier)
    └── iOS App Review iterations (if rejected)
```

---

## 9. Open Decisions

| # | Decision | Options | Recommendation |
|---|----------|---------|----------------|
| D1 | Android rollout percentage | 10% / 20% / 50% | **20%** — provides early warning with enough users to surface crashes, without risking negative reviews at scale. |
| D2 | Production version number | `1.1.0` / `1.1.0+22` | **1.1.0** — drop beta suffix, increment build number. Update pubspec.yaml, constants.dart, and settings_screen.dart. |
| D3 | Privacy Policy hosting | GitHub Pages / blinkingchorus.com / Notion | **GitHub Pages** — fastest to set up, free, content already in docs/Blinking_Notes_Privacy_Policy.md. |
| D4 | iOS App Store Connect CFBundleShortVersionString | `1.1.0.6` (Flutter default) / `1.1.0` | **1.1.0** — already fixed in the TestFlight build. Apple requires max 3 integers. |
| D5 | Community platform | Discord / Telegram / Slack | **Discord** — better discovery, topic channels, bot integrations. Easier to grow organically. |
| D6 | First content marketing topic | "How I use AI to reflect on my day" / "Why I built a bilingual journal app" | **Personal story** — "Why I built a bilingual journal app" has stronger emotional pull and differentiation. Good for Xiaohongshu + Medium. |

---

## 10. Document References

| Document | Path | Purpose |
|----------|------|---------|
| Master plan | `../system-upgrade/master_plan.md` | iOS toolchain upgrade plan |
| Session summary (iOS) | `../system-upgrade/session-summary-2026-0502.md` | iOS signing + TestFlight upload |
| TestFlight smoke tests | `../system-upgrade/testflight-smoke-tests.md` | 22 iOS test cases |
| Bug reports | `docs/uxbugs/bug-reports.md` | 14 UX issues (9 resolved, 6 pending) |
| Launch readiness | `docs/plans/launch_readiness_2026-05-01.md` | Pre-launch + post-launch polish plan |
| CLAUDE.md | `CLAUDE.md` | Developer context + architecture |
| Project plan | `PROJECT_PLAN.md` | Feature status + development history |
| Privacy Policy | `docs/Blinking_Notes_Privacy_Policy.md` | To be hosted on GitHub Pages |
| Terms of Service | `docs/Blinking_Notes_Terms_of_Service.md` | To be hosted on GitHub Pages |

---

## Revision Log

| Date | Author | Change |
|------|--------|--------|
| 2026-05-02 | Justin / AI | Initial comprehensive launch plan — merged Android + iOS, added competitive analysis, pricing strategy, marketing plan |
