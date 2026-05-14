# AI Model Evaluation — Blinking Notes

**Date:** 2026-05-10  
**Purpose:** Select primary and failover models for AI reflections  
**Method:** Same 5 test entries across 3 models, evaluated on cost, speed, and quality

---

## Cost Analysis (per user, per year)

Based on ~1,100 calls/year with ~2,000 input + 300 output tokens per call.

| Model | Cost/User/Year | 100 Users | 1,000 Users |
|-------|:---:|:---:|:---:|
| `google/gemini-2.0-flash-001` | ~$0.30 | $30 | $300 |
| `deepseek/deepseek-chat-v3-0324` | ~$2.20 | $220 | $2,200 |
| `anthropic/claude-3.5-haiku` | ~$3.00 | $300 | $3,000 |
| `meta-llama/llama-4-maverick` | $0 (free) | $0 | $0 |

---

## Speed Comparison

| Model | Mood Moment (200 token) | Daily Reflection (300 token) | Overall |
|-------|:---:|:---:|:---:|
| Gemini | 1-2s | 2-3s | ⚡ Fastest |
| DeepSeek | 3-4s | 4-5s | 🟡 Moderate |
| Claude Haiku | 5-6s | 8-9s | 🐌 Slowest |

---

## Quality Comparison — 5 Test Entries

Test entries cover 5 moods: 😊 Joyful, 😰 Anxious, 🤩 Excited, 😤 Frustrated, 😌 Calm.

### Stay Posture
| Model | Response |
|-------|----------|
| **Gemini** | "It sounds like you had a full day! Even though it was draining, you were able to work through a difficult conversation..." — Functional but generic, lists events rather than synthesizing. |
| **DeepSeek** | "The Courage to Be Disliked discussion sounds like it came at just the right time—that lightness you feel speaks volumes. Creative blocks can be so frustrating..." — **Best.** Weaves multiple entries together, finds connections, uses imagery ("eye of a storm"). |
| **Claude** | "It sounds like a day of nuanced emotions and meaningful moments. The book club discussion about self-acceptance seems to have sparked something profound..." — Good vocabulary but clinical, less personal. |

### Soften Posture
| Model | Response |
|-------|----------|
| **Gemini** | "It sounds like you had a full day, complete with highs and lows. Having those deep conversations at book club must have been nourishing..." — Generic, misses depth. |
| **DeepSeek** | "I love how this day held both ease and effort for you—running freely in the cool morning air, then wrestling with words and difficult conversations later..." — **Best.** Draws contrasts, validates emotions without being prescriptive. |
| **Claude** | "It sounds like you've had a really textured day—moving through creative blocks, personal growth conversations, physical achievement..." — Polished but reads like a summary, not a companion. |

### Notice Posture
| Model | Response |
|-------|----------|
| **Gemini** | "It sounds like you had a full day, with some really high highs and some challenging moments too. I'm glad you had a good book club and a great run!" — Too cheerful, feels performative. |
| **DeepSeek** | "It sounds like your day held both depth and lightness—those profound book club conversations have a way of lifting us while also stirring things up..." — **Best.** Notices subtleties, acknowledges struggle without fixing it. |
| **Claude** | "It sounds like today was a rich tapestry of moments—from the profound book club discussion about self-acceptance to the creative wrestling..." — Overwrought vocabulary, less grounded. |

### Daily Reflection (Zengzi's Three)
| Model | Response |
|-------|----------|
| **Gemini** | Functional observations, one sentence per lens. Flat. |
| **DeepSeek** | **Best.** Each lens gets specific, data-grounded observation. Direct references to entries. |
| **Claude** | Misaligned question-to-entry mapping. Swapped which entry goes with which lens. |

---

## Prompt Engineering — Multi-Dimensional Testing

12 tests across 3 EN + 3 ZH entry sets, 3 personas, 3 lens sets, 2 models.
Full results: `docs/plans/prompt-engineering-results.md`

### Persona Adherence

| Model | Warm | Blunt | Poetic |
|-------|------|-------|--------|
| **DeepSeek** | Supportive, grounded. "You showed vulnerability by sharing your interview doubts" | Actually blunt. "processed it privately first rather than spreading panic" | Actually poetic. "pooling in the hollow of your collarbone" |
| **Gemini** | Similar across personas. "Blunt" still sounds warm | Indistinguishable from Warm | Terse, incomplete. "Sunlight on leaves, a pattern unseen" |

### Chinese Quality

| Model | Quality | Example |
|-------|---------|---------|
| **DeepSeek** | Culturally nuanced, natural flow | "给自己发了条冷静的信息...感觉自己进步了" — feels native |
| **Gemini** | Literal, shorter, sometimes machine-translated | "你提醒自己，职业生涯是马拉松，不是短跑" — restates entry verbatim |

### Lens Alignment

| Model | Zengzi's Three | Body·Mind·Heart | Honest Weather |
|-------|---------------|-----------------|----------------|
| **DeepSeek** | Observations grounded in the ethical question asked | Clearly distinguishes physical/mental/emotional | Metaphors genuinely connected to weather imagery |
| **Gemini** | Restates entries with different wording | Flattens body/mind/heart into same observation | Generic nature references |

### Speed by Language

| Model | EN | ZH | Overall |
|-------|:---:|:---:|:---:|
| **DeepSeek** | 6.2-7.6s | 4.5-7.5s | 🟡 |
| **Gemini** | 1.3-1.5s | 1.0-1.5s | ⚡ |

---

## Final Recommendation (Confirmed)

DeepSeek is the clear winner on quality across all dimensions tested. The speed gap (4x slower) is acceptable for a journaling app where reflection is intentional, not real-time. Gemini remains an excellent failover for speed/reliability.

| Criteria | Gemini | DeepSeek | Claude |
|----------|:---:|:---:|:---:|
| Speed | (1) ⚡ | (2) 🟡 | (3) 🐌 |
| Cost | (1) $0.30/yr | (2) $2.20/yr | (3) $3.00/yr |
| Stay quality | 3rd | **1st** | 2nd |
| Soften quality | 3rd | **1st** | 2nd |
| Notice quality | 3rd | **1st** | 2nd |
| Reflection quality | 3rd | **1st** | 2nd |
| **Overall** | Faster, cheaper, generic | Best quality, moderate cost | Slow, expensive, clinical |

---

## Final Config (Deployed)

| Priority | Model | Role |
|----------|-------|------|
| 1 | `deepseek/deepseek-chat-v3-0324` | Primary — best quality |
| 2 | `google/gemini-2.0-flash-001` | Failover — speed + reliability |

Deployed to `https://blinkingchorus.com/api/config` for both trial and pro keys. Active on new installs immediately, existing clients within 24h (cache).

---

## Notes

- **Llama 4 Maverick** was not fully tested — failed with model name mismatch (`meta-llama/llama-4-maverick:free` vs `meta-llama/llama-4-maverick`). Worth revisiting for cost savings if quality proves adequate.
- **Claude 3.5 Haiku** is too slow for a journaling app — users expect reflection within 3-5 seconds, not 8-9.
- **Gemini** is an excellent failover: fast, cheap, acceptable quality. The gap between primary and failover ensures users never experience a broken AI.

## Related Documents

- `docs/plans/prompt-engineering-test-plan.md` — Test matrix with 6 entry sets, 4 personas, 3 lens sets
- `docs/plans/prompt-engineering-results.md` — Raw output from 12 automated tests
- `docs/plans/2026_05_08_Blinking-AI-Engineering-Plan.docx` — Original AI surfaces design
