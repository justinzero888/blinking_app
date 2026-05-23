# Voice Features — Full Feature Evaluation & Scoring

> **Date:** May 22, 2026  
> **Purpose:** Evaluate all possible voice-related features before committing to T-6 scope. Score each across 6 dimensions to explain every design decision.

---

## Feature Candidates

| ID | Feature | What It Does |
|----|---------|-------------|
| **F1** | Voice reminders (TTS output) | Speak routine name + description when notification fires |
| **F2** | Voice input / dictation | User speaks to dictate journal entries instead of typing |
| **F3** | Voice commands | User says "complete routine 1" or "add entry" via microphone |
| **F4** | Audio journal entries | Record voice notes as standalone entries (like voice memos) |
| **F5** | Conversational AI voice | Talk to AI assistant by voice instead of typing (two-way) |
| **F6** | Wake word ("Hey Blinking") | Always-listening hotword to trigger assistant hands-free |
| **F7** | Voice summaries | Reads daily/weekly insights aloud ("This week you wrote 23 entries...") |
| **F8** | Affirmation / audio content | Plays pre-written affirmations, sleep stories, or motivational audio |

---

## Scoring Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **User value** | 5 | How many users want this? How often would they use it? Does it solve a real problem? |
| **Implementation** | 4 | Effort to build (1 = days, 5 = months). Technical risk. Platform compatibility. |
| **Privacy risk** | 5 | Does it compromise Blinking's "no accounts, just you" promise? Data exposure? |
| **Maintenance** | 3 | Ongoing work to keep it working. Depends on platform APIs that change? |
| **Differentiation** | 4 | How unique is this vs. competitors? Does it leverage Blinking's existing strengths? |
| **Identity fit** | 5 | Does it reinforce "private personal journal with personality" or dilute it? |

**Scoring:** 1 (worst) to 5 (best). Weighted total = sum(score × weight).

---

## Feature-by-Feature Analysis

### F1: Voice Reminders (TTS Output)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 4 | Habit reminders are a core routine feature. Voice makes them actionable hands-free (cooking, driving). Not every user wants it, but those who do love it. |
| Implementation | 5 | `flutter_tts` wraps native APIs. Both platforms have offline TTS built in. ~2h effort. No server needed. |
| Privacy risk | 5 | Fully on-device. No microphone. No recording. No data leaves the phone. |
| Maintenance | 5 | Native TTS APIs are stable (iOS since 2013, Android since 2010). `flutter_tts` is mature. |
| Differentiation | 4 | Zero habit apps do bilingual + persona-aware TTS. Unique, but a nice-to-have, not a game-changer. |
| Identity fit | 5 | Reinforces "app with personality." Persona-aware voice = Kael vs Elara audio identity. |

**Weighted: 4×5 + 5×4 + 5×5 + 5×3 + 4×4 + 5×5 = 20+20+25+15+16+25 = 121 / 130**

---

### F2: Voice Input / Dictation

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 3 | Journaling by voice is faster for some. But both iOS and Android already have system-level dictation (microphone key on keyboard). Redundant. |
| Implementation | 4 | `speech_to_text` package. Needs microphone permission. Works offline on iOS, needs internet on Android. ~4h effort. |
| Privacy risk | 2 | Requires microphone permission. Users are rightfully suspicious of apps asking for mic access. Even if we don't store, the permission request itself erodes trust. |
| Maintenance | 4 | Speech recognition APIs are stable. But Android's offline model is device-dependent. |
| Differentiation | 2 | System dictation already exists. Day One offers this. Not unique. |
| Identity fit | 2 | A journaling app asking for microphone access contradicts the privacy promise. "No accounts, just you... and we're listening." |

**Weighted: 3×5 + 4×4 + 2×5 + 4×3 + 2×4 + 2×5 = 15+16+10+12+8+10 = 71 / 130**

---

### F3: Voice Commands

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 2 | "Complete routine 1" saves one tap. But finding the phone, unlocking, opening the app, and holding a button to speak is MORE work than just tapping the checkbox. |
| Implementation | 2 | Requires always-on mic or button-hold-to-speak. Intent parsing ("complete", "add", "skip") adds NLP complexity. ~2 weeks. |
| Privacy risk | 1 | Requires constant or frequent microphone access. Worse than F2 because it implies always listening. |
| Maintenance | 2 | Speech intent parsing needs tuning per language (EN + ZH). Model drift over time. |
| Differentiation | 3 | Siri/Assistant already do this at OS level for Reminders. App-level voice commands are novel but not clearly better. |
| Identity fit | 1 | Voice commands make the app feel like a utility/tool, not a warm personal journal. |

**Weighted: 2×5 + 2×4 + 1×5 + 2×3 + 3×4 + 1×5 = 10+8+5+6+12+5 = 46 / 130**

---

### F4: Audio Journal Entries (Voice Memos)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 3 | Some people prefer speaking to writing. "Dear diary" style. But audio is unsearchable, hard to skim, and takes up significant storage. |
| Implementation | 3 | `record` package. Needs microphone permission + file storage. Playback UI. ~1 week. |
| Privacy risk | 2 | Requires microphone permission. Audio files stored on device (OK) but large and potentially sensitive. |
| Maintenance | 4 | Recording/playback is stable. But audio codec, compression, storage management add ongoing work. |
| Differentiation | 3 | Day One offers audio entries. Not unique, but not common in Chinese market apps. |
| Identity fit | 3 | Audio feels cinematic and personal. But it's a different product category — voice memos, not journaling. |

**Weighted: 3×5 + 3×4 + 2×5 + 4×3 + 3×4 + 3×5 = 15+12+10+12+12+15 = 76 / 130**

---

### F5: Conversational AI Voice (Two-way)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 4 | Talking to Kael by voice would be magical. "How was my week?" → AI speaks summary. But the text interface already exists — voice is a modality upgrade, not a new capability. |
| Implementation | 1 | Requires: STT (speech to text) → LLM API call → TTS (text to speech). Pipeline latency 3-5 seconds per turn. Server dependency for LLM. ~1 month. |
| Privacy risk | 1 | Requires microphone + LLM server. Journal content sent to server for AI processing. Conflicts with privacy-first positioning. |
| Maintenance | 1 | LLM API changes, TTS voice quality, STT accuracy across languages. High ongoing cost. |
| Differentiation | 5 | No journaling app has conversational AI by voice. Would be genuinely groundbreaking. |
| Identity fit | 4 | Talking to your AI persona is the ultimate expression of "app with personality." But privacy cost is high. |

**Weighted: 4×5 + 1×4 + 1×5 + 1×3 + 5×4 + 4×5 = 20+4+5+3+20+20 = 72 / 130**

---

### F6: Wake Word ("Hey Blinking")

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 3 | Hands-free is appealing. "Hey Blinking, how am I doing today?" But wake words are notoriously frustrating when they misfire. |
| Implementation | 1 | Requires always-on microphone + on-device wake word model. Porcupine/ Snowboy packages exist but are battery-draining and finicky. ~3 weeks. |
| Privacy risk | 1 | Always-on microphone. Even if "processed on device," the perception of surveillance is toxic for a journaling app. Users would flee. |
| Maintenance | 1 | Wake word models need tuning per device, OS version, accent. Ongoing frustration. |
| Differentiation | 4 | Very few apps have custom wake words. But the novelty isn't worth the privacy cost. |
| Identity fit | 1 | "Always listening" is the opposite of Blinking's identity. |

**Weighted: 3×5 + 1×4 + 1×5 + 1×3 + 4×4 + 1×5 = 15+4+5+3+16+5 = 48 / 130**

---

### F7: Voice Summaries (Read Insights Aloud)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 3 | "This week you wrote 23 entries, mood averaged 4.2, top tag was #gratitude." Nice, but insights are visual — charts and numbers don't work well in audio. |
| Implementation | 4 | Same TTS pipeline as F1. Just different content. ~1h to add. |
| Privacy risk | 5 | On-device TTS. No new data exposure. |
| Maintenance | 5 | Same as F1. |
| Differentiation | 3 | Novel, but not clearly useful. Who listens to analytics? |
| Identity fit | 4 | Fits the "app talks to you" persona experience. But analytics are inherently visual. |

**Weighted: 3×5 + 4×4 + 5×5 + 5×3 + 3×4 + 4×5 = 15+16+25+15+12+20 = 103 / 130**

---

### F8: Affirmation / Audio Content

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| User value | 3 | Pre-written morning affirmations or motivational audio. Some users love this. But it's content creation, not a feature — needs writers. |
| Implementation | 4 | TTS reading pre-written scripts. Or pre-recorded audio assets. ~3h for scripts + playback. |
| Privacy risk | 5 | On-device playback. No microphone. |
| Maintenance | 3 | Content needs updates. Translations. Voice variety. Becomes a content business. |
| Differentiation | 3 | Headspace/Calm dominate this space. Competing on content is expensive. |
| Identity fit | 3 | "Warm" fits Elara. "Martial" fits Marcus. But it's a different product category. |

**Weighted: 3×5 + 4×4 + 5×5 + 3×3 + 3×4 + 3×5 = 15+16+25+9+12+15 = 92 / 130**

---

## Final Ranking

| Rank | Feature | Score | Verdict |
|------|---------|-------|---------|
| **1** | **F1: Voice reminders (TTS)** | **121** | ✅ **Build in v1.2.0** — highest score, lowest risk, fastest build |
| 2 | F7: Voice summaries | 103 | ⏸️ Defer — interesting but not urgent |
| 3 | F8: Affirmation / audio content | 92 | ⏸️ Defer — content business, not our lane |
| 4 | F4: Audio journal entries | 76 | ⏸️ Defer — Day One feature, not our differentiator |
| 5 | F5: Conversational AI voice | 72 | ⏸️ Defer — groundbreaking but privacy costs are too high |
| 6 | F2: Voice input / dictation | 71 | ❌ Skip — redundant with system keyboard dictation |
| 7 | F6: Wake word | 48 | ❌ Skip — antithetical to privacy promise |
| 8 | F3: Voice commands | 46 | ❌ Skip — more work than tapping, privacy risk |

---

## Decision Record

| Decision | Rationale |
|----------|-----------|
| **Build F1 now** | Highest user value relative to implementation cost. Privacy-safe. Unique in market. Aligned with persona system. |
| **Defer F4, F5, F7, F8** | Interesting but not urgent. F5 (conversational AI) has high wow-factor but privacy cost is unacceptable at this stage. Revisit when on-device LLMs are viable. |
| **Reject F2, F3, F6** | Microphone access is a privacy non-starter for a journaling app. System dictation already exists for F2. Wake words violate trust. |

### Design Principle

> **Voice output only. No microphone. Ever.**

This is the line. Blinking speaks to you — it never listens. This preserves the privacy promise while adding meaningful value through TTS reminders.
