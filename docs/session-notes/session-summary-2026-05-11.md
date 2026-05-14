# Session Summary — 2026-05-11

**App:** Blinking (记忆闪烁) v1.1.0+31  
**Tests:** 147/147 passing  
**Lint:** 0 errors  
**Scope:** AI model evaluation, curated personas, streaming, Settings redesign, reflection UX

---

## AI Model Evaluation

| Model | Speed | Quality | Cost/yr | Status |
|-------|:---:|:---:|:---:|--------|
| **DeepSeek** `deepseek-chat-v3-0324` | 3-7s | 🟢 Best | $0.40 | Primary |
| **Gemini** `gemini-2.0-flash-001` | 1-2s | 🟡 Acceptable | $0.10 | Failover |
| **Claude** `claude-3.5-haiku` | 5-9s | 🟡 Clinical | $3.00 | Not used |
| **Llama** `llama-4-maverick` | — | Not tested | $0 | Not used |

Server config deployed: DeepSeek primary → Gemini failover. Both trial + pro keys.

### Streaming Implementation
- Added `completeStream()` to LlmService — SSE-based token streaming
- **Perceived speed: 89% improvement** (0.6s first token vs 5.3s spinner)
- Zero cost impact, zero quality impact

## Curated Persona Presets

Replaced free-form AI personality input with 4 tested presets:

| Persona | Vibe | Voice |
|---------|------|-------|
| **Kael** 📝 | Factual Minimalist | Calm, grounded, no fluff |
| **Elara** 🌿 | Warm & Grounded | Gentle, encouraging, specific |
| **Rush** ⚡ | High-Volume Unfiltered | Fast, pressure-valve, urgent |
| **Marcus** ⚔️ | Stoic Examiner | Challenging, probing, clear |

Each preset bundles: name, emoji avatar, personality string, 3 lens questions. Tap to switch — instantly sets everything.

### Prompt Engineering Results
- 12 automated tests across 3 EN + 3 ZH entry sets
- Xiao Wu persona proved engineered personas are 10x better than generic "Warm and grounded."
- Cost: all personas cost $0.01-0.02/user/year extra — negligible
- Speed: persona text adds ~50ms — imperceptible

## Settings Redesign

AI Personalization tab replaced with style picker:
- Active style preview with gradient card + 3 lenses
- 4 preset cards, tap to activate
- Name, avatar, persona, and lenses all switch together
- "Your Three" lens config remains accessible for custom lens sets

## Reflection UX Improvements

1. **Context window**: "Auto" → "Today" (default). Options: Today / Last 7 days / This month / Last 3 months
2. **Smart progression**: if user generated Today's reflection, next tap auto-advances to Last 7 days (unless new entries added)
3. **Range indicator**: visible date range below lens set label
4. **No-entries handling**: today empty → falls back to Last 7 days with hint
5. **Generation counting**: counter now increments on each API call (not just saves). 3 generations/day hard limit
6. **Robot visibility**: hidden on Routine + Insights tabs. My Day: hidden if no entries today. Moments: hidden if zero entries total
7. **Robot behavior**: always opens Daily Reflection (consistent). Mood Moment stays on emoji jar "Ask AI"

## Bug Fixes

- **Model name**: `qwen/qwen3.5-flash` → `qwen/qwen3.5-flash-02-23` (production crash)
- **Lens set mapping**: style-specific lens sets now seeded on first launch. Switching style instantly switches lenses
- **Daily reflection counter**: moves from save-time to generation-time (prevents unlimited regeneration)
- **Production build**: switched from Xcode beta → Xcode 26.4.1 GM for App Review compliance

## Files Changed

| File | Change |
|------|--------|
| `lib/models/reflection_style.dart` | **New** — 4 persona presets with lenses |
| `lib/providers/ai_persona_provider.dart` | +`styleId`, +`setStyle()`, presets replace free-form |
| `lib/core/services/llm_service.dart` | +`completeStream()` — SSE streaming |
| `lib/core/services/config_service.dart` | Multi-key format support |
| `lib/core/services/prompt_assembler.dart` | +`today` and `last3months` context windows |
| `lib/core/services/storage_service.dart` | Style lens set seeding + migration |
| `lib/screens/settings/settings_screen.dart` | `_buildAITab` — style picker replaces form fields |
| `lib/screens/settings/lens_config_screen.dart` | **New** — lens set browser |
| `lib/screens/reflection/reflection_session_screen.dart` | Context window rename, smart progression, range indicator, generation counting |
| `lib/widgets/floating_robot.dart` | Content-aware visibility, tab restrictions |
| `lib/main.dart` | Production cleanup (removed AUTO_RESTORE, test key fallback) |
| `chorus/chorus-api/src/routes/ai-config.ts` | Multi-key server endpoint |
| `docs/plans/ai-model-evaluation.md` | **New** — comprehensive model comparison |
| `docs/plans/curated-personas-evaluation.md` | **New** — persona test results |
| `docs/plans/annual-reflection-feature-spec.md` | **New** — feature spec (not implemented) |
| `docs/plans/project_todo_2026_05_10.md` | Updated status |

## Pending

| Item | Priority | Status |
|------|----------|--------|
| Annual Reflection feature | P2 | Spec written |
| Marketing plan | P2 | Not started |
| App Review outcome | P1 | Waiting (1-2 days) |
| Google Play production promotion | P2 | Beta testing |
