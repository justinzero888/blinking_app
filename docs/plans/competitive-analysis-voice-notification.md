# T-6: Voice Notification — Competitive Analysis & Best Practices

> **Date:** May 22, 2026  
> **Status:** Design research — ahead of detailed design

---

## Market Landscape

### Direct Competitors (Habit/Routine Apps)

| App | TTS Voice? | Notification Style | Notes |
|-----|-----------|-------------------|-------|
| **Streaks** | ❌ | Silent banner only | Apple Design Award winner. Rich notifications but no spoken reminders. |
| **Habitica** | ❌ | Silent banner only | Gamified RPG habits. Notifications are text-only. |
| **Done** | ❌ | Silent banner only | Color-coded streaks. Standard iOS notifications. |
| **TickTick** | ⚠️ | Optional "Read aloud" | Generic TTS — reads title only. No customization. |
| **Due** | ❌ | Persistent nag (text) | Famous for auto-snoozing reminders. Still text-only. |
| **Productive** | ❌ | Silent banner + rich media | Beautiful UI, no voice. |
| **Any.do** | ⚠️ | Voice reminders for tasks | Task-oriented, not habit-oriented. Generic TTS. |

**Key finding:** Zero habit-tracking apps offer meaningful TTS spoken reminders. The space is empty.

### Adjacent Inspiration

| Product | Voice Feature | What Works |
|---------|--------------|------------|
| **Apple "Announce Notifications"** | Siri reads any notification aloud via AirPods/HomePod | Seamless, but reads raw notification text — generic, no personality |
| **Shortcuts / Siri Shortcuts** | Custom TTS scripts with chosen voice | Flexible but requires user setup. Power-user only. |
| **Headspace / Calm** | Guided meditation voice | Soothing tone, warm delivery. Not reminders — exercises. |
| **Google Assistant Routines** | Spoken morning briefings | Contextual: time, weather, calendar, reminders. Good UX precedent. |

**Key finding:** The only "voice habit reminder" options are platform-level (Siri/Assistant), which are generic and require user setup. No app-level solution exists.

---

## Best Practices

### Technical

| Practice | Rationale |
|----------|-----------|
| **Offline-first** | TTS must work without internet. `AVSpeechSynthesizer` (iOS) and `TextToSpeech` (Android) are offline by default. ✅ |
| **Respect silent mode** | Check audio session category. Don't interrupt meetings/sleep. |
| **Short utterances** | Keep reminders under 10 seconds. Long speeches are annoying. |
| **Opt-in only** | Voice reminders must be opt-in, never on by default. Privacy and social etiquette. |
| **Per-routine control** | Users want voice for some routines ("take vitamins") but not others ("floss"). |
| **Language-aware** | Speak in the user's current language. Blinking's EN/ZH switch must carry through. |
| **Pre-download voices** | Some TTS voices are >100MB. Pre-fetch or warn user. iOS handles this automatically; Android may need attention. |

### UX

| Practice | Rationale |
|----------|-----------|
| **Combine with visual notification** | Voice + banner. If voice fails, banner still works. Graceful degradation. |
| **Fire once, don't repeat** | Unlike Due's nag model, speak once. Repeated voice = intrusive. |
| **Time-of-day awareness** | Evening routines could use calmer speech rate. Morning = energetic. (Future enhancement) |
| **Accessibility** | VoiceOver users benefit doubly — TTS + screen reader. Should not conflict. |
| **Volume gradient** | Start quiet, ramp up. Don't blast at full volume. (Platform-dependent) |

### Privacy

| Practice | Rationale |
|----------|-----------|
| **No server** | All TTS processing on-device. Blinking's privacy promise intact. ✅ |
| **No recording** | Never record or store user's voice. TTS is output-only. ✅ |
| **No wake word** | No "Hey Siri" equivalent. Triggered only by scheduled notification. ✅ |

---

## Blinking's Differentiator

### What Makes This Unique

| Differentiator | Description | Competitive Edge |
|---------------|-------------|-----------------|
| **Bilingual voice** | Each routine has `name` (ZH) and `nameEn` (EN). TTS speaks in user's current locale automatically. "该喝水了" vs "Time to drink water" | No habit app does bilingual TTS. |
| **Description-aware** | Speaks routine name + description. "Stretch 5 minutes — releases tension built up from sitting" — adds context, not just command. | TickTick reads title only. Blinking reads the *why*. |
| **Persona-adaptive tone** | Kael (factual, faster speech rate) vs Elara (warm, slower, softer pitch). Each persona has a distinct TTS profile. | Literally no app does this. It's Blinking's core differentiator applied to audio. |
| **Mood-aware greeting** | If yesterday's mood was 😢, morning reminder could say "Yesterday was tough. Let's start fresh today." | Ties mood tracking to habit encouragement. Emotional intelligence. |
| **Privacy-first** | All on-device. No cloud. No recording. No accounts needed for voice. | Aligned with Blinking's core promise. |

### What We're NOT Doing

| Anti-feature | Why |
|-------------|-----|
| Voice input (microphone recording) | Privacy risk. Smartphones already have keyboard dictation. |
| "Hey Blinking" wake word | Requires always-on mic. Violates privacy model. |
| Conversational AI agent | Over-engineered for a reminder. Notifications + TTS is sufficient. |
| Alexa/Google Home integration | Requires cloud accounts. Privacy conflict. |

---

## Comparison Matrix

| Feature | Streaks | TickTick | Due | Apple Reminders | **Blinking (proposed)** |
|---------|---------|----------|-----|-----------------|--------------------------|
| Habit reminders | ✅ | ✅ | ✅ | ✅ | ✅ |
| Spoken reminders | ❌ | ⚠️ generic | ❌ | ⚠️ Siri | ✅ |
| Bilingual TTS | ❌ | ❌ | ❌ | ❌ | ✅ |
| Persona-aware tone | ❌ | ❌ | ❌ | ❌ | ✅ |
| Reads description (the *why*) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Mood-aware context | ❌ | ❌ | ❌ | ❌ | ✅ |
| Per-routine voice toggle | ❌ | ❌ | ❌ | ❌ | ✅ |
| Offline | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| Privacy (no server) | ✅ | ❌ | ✅ | N/A | ✅ |

---

## Recommendation

**Proceed with T-6.** The voice notification feature has zero direct competition in the habit-tracking space. Blinking's existing strengths (bilingual, persona-aware, privacy-first, mood tracking) transfer directly to audio, creating a feature that is uniquely Blinking and impossible for generic habit apps to replicate.
