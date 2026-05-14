# Prompt Engineering Test Plan

**Date:** 2026-05-10  
**Models:** DeepSeek (primary), Gemini (comparison)  
**Dimensions:** 6 entry sets × 2 models × 4 personas × 3 lens sets

---

## Entry Sets — English

### EN Set 1: Career Crossroads
| # | Mood | Content |
|---|------|---------|
| 1 | 😰 | "Third round interview tomorrow. Prepared but can't shake the feeling I'm not qualified. Spent all weekend practicing answers." |
| 2 | 😤 | "Current boss hinted my role might be eliminated in the restructuring. No timeline given. Hard to focus on anything else." |
| 3 | 😊 | "Got a surprise call from an old mentor. She reminded me I've navigated harder transitions before. Offered to review my resume." |
| 4 | 😐 | "Went for a walk at lunch to clear my head. Sometimes I forget that careers are marathons, not sprints." |
| 5 | 🤩 | "Signed up for a pottery class tonight — something completely unrelated to work. The clay doesn't care about my job title." |

### EN Set 2: Relationships & Boundaries
| # | Mood | Content |
|---|------|---------|
| 1 | 😤 | "My sister canceled on me again — third time this month. I rearranged my whole Saturday for her. Starting to feel like a backup plan." |
| 2 | 😌 | "Wrote her a calm message instead of reacting. 'I'm disappointed, but I understand things come up. Let me know when you're free.' Felt like growth." |
| 3 | 😰 | "Partner wants to move cities for their job. I just started feeling settled here. Not sure how to have this conversation without sounding unsupportive." |
| 4 | 😊 | "Met a new neighbor today. We talked for 45 minutes about gardening. Zero pretense. Reminded me friendship can be simple." |
| 5 | 🤩 | "Said no to a social event I didn't want to attend. Did NOT apologize. Did NOT explain. First time in years. Felt incredible." |

### EN Set 3: Creative Drought
| # | Mood | Content |
|---|------|---------|
| 1 | 😤 | "Day 14 of staring at a blank canvas. Everything I paint looks derivative. Maybe I peaked three years ago and this is just the long decline." |
| 2 | 😐 | "Watched a documentary about Agnes Martin. She didn't sell a painting until she was 46. Trying to remember that timelines are fiction." |
| 3 | 😢 | "Threw out three canvases today. Felt wasteful but also cathartic. Some work isn't meant to be finished." |
| 4 | 😌 | "Walked through the botanical garden without my phone. Noticed how leaves overlap in patterns I've never painted. Maybe inspiration needs silence." |
| 5 | 😊 | "Sketching with charcoal tonight — no goal, no audience. Just the sound of charcoal on paper. Rediscovered why I started making art." |

---

## Entry Sets — Chinese

### ZH Set 1: 职业十字路口
| # | Mood | Content |
|---|------|---------|
| 1 | 😰 | "明天的终轮面试，准备了一整个周末，还是觉得自己不够格。" |
| 2 | 😤 | "老板暗示我的岗位可能会在重组中被裁掉。没有给时间表，心里很乱。" |
| 3 | 😊 | "前导师打来电话，她说我经历过更难的过渡期。主动帮我改简历。" |
| 4 | 😐 | "午休时去散了步，提醒自己：职业生涯是马拉松，不是短跑。" |
| 5 | 🤩 | "晚上报了陶艺课，和职场完全无关。泥巴不在乎我的职位高低。" |

### ZH Set 2: 关系与边界
| # | Mood | Content |
|---|------|---------|
| 1 | 😤 | "妹妹又放我鸽子了，这个月第三次。我为了她推掉了整个周六的安排。开始觉得自己像个备胎。" |
| 2 | 😌 | "给她发了条冷静的信息：我很失望，但理解事情会有变动。等你方便的时候再约。感觉自己进步了。" |
| 3 | 😰 | "伴侣因为工作想搬到另一个城市，我才刚在这里安顿下来。不知道怎么开口讨论才不显得不支持。" |
| 4 | 😊 | "认识了新邻居。聊了45分钟园艺，毫无矫饰。原来友谊可以这么简单。" |
| 5 | 🤩 | "拒绝了一个不想去的社交活动，没道歉，没解释。有生以来第一次。太爽了。" |

### ZH Set 3: 创作枯竭期
| # | Mood | Content |
|---|------|---------|
| 1 | 😤 | "Day 14 盯着空白画布。画什么看起来都像抄袭。也许三年前就已经过了巅峰期，这就是漫长下坡路的开始。" |
| 2 | 😐 | "看了Agnes Martin的纪录片，她46岁才卖出第一幅画。提醒自己：时间线只是虚构。" |
| 3 | 😢 | "扔了三幅画。心疼但痛快。有些作品不是要完成的。" |
| 4 | 😌 | "没带手机逛了植物园。注意到叶子的重叠方式是我从未画过的图案。灵感也许需要沉默。" |
| 5 | 😊 | "晚上用炭笔画速写，没有目的，没有观众。只有笔触和纸张摩擦的声音。找回了最初做艺术的冲动。" |

---

## Personas

| # | Name | Personality String |
|---|------|-------------------|
| P1 | Warm & Grounded (default) | "Warm and grounded." |
| P2 | Blunt & Observant | "Cold humor. Dry and observant. Doesn't try to comfort." |
| P3 | Gentle & Poetic | "Gentle and poetic. Speaks in short images. No advice." |
| P4 | Meditative & Sparse | "Calm, slow, meditative. Minimal and factual. Short, rhythmic sentences. No praise." |

---

## Lens Sets

| Set | Lenses |
|-----|--------|
| Zengzi's Three | Have I been true to others? / Have I been trustworthy with friends? / Have I practiced what I learned? |
| Body·Mind·Heart | What is my body asking for? / What is my mind turning over? / What is my heart wanting? |
| Honest Weather | What was the sunlight today? / What was the rain today? / What might the weather be tomorrow? |

---

## Test Matrix (Priority Order)

| # | Entry Set | Model | Persona | Lens Set |
|---|-----------|-------|---------|----------|
| 1 | EN Career | DeepSeek | Warm | Zengzi |
| 2 | EN Career | DeepSeek | Blunt | Body·Mind·Heart |
| 3 | EN Career | DeepSeek | Poetic | Honest Weather |
| 4 | EN Career | Gemini | Warm | Zengzi |
| 5 | EN Career | Gemini | Blunt | Body·Mind·Heart |
| 6 | EN Career | Gemini | Poetic | Honest Weather |
| 7 | ZH Career | DeepSeek | Warm | Zengzi |
| 8 | ZH Relationships | DeepSeek | Blunt | Body·Mind·Heart |
| 9 | ZH Creative | DeepSeek | Poetic | Honest Weather |
| 10 | ZH Career | Gemini | Warm | Zengzi |
| 11 | ZH Relationships | Gemini | Blunt | Body·Mind·Heart |
| 12 | ZH Creative | Gemini | Poetic | Honest Weather |

**12 core tests** covering the most important combinations. Additional EN sets and lens sets can be tested after reviewing initial results.

---

## Success Criteria

- Response quality variation across personas
- Chinese vs English response quality
- Lens set impact on reflection depth
- Model-specific strengths/weaknesses
