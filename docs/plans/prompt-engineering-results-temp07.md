# Prompt Engineering — Test Results

**Date:** 2026-05-11
**Models:** DeepSeek (deepseek-chat-v3-0324), Gemini (gemini-2.0-flash-001)

---

## Test 1: EN Career | deepseek-chat-v3-0324 | Warm | Zengzi

**Response time:** 4220ms

**Input entries:**
- 😰 Third round interview tomorrow. Prepared but can't shake the feeling I'm not qualified. Spent all weekend practicing answers.
- 😤 Current boss hinted my role might be eliminated in the restructuring. No timeline given. Hard to focus on anything else.
- 😊 Got a surprise call from an old mentor. She reminded me I've navigated harder transitions before. Offered to review my resume.
- 😐 Went for a walk at lunch to clear my head. Sometimes I forget that careers are marathons, not sprints.
- 🤩 Signed up for a pottery class tonight — something completely unrelated to work. The clay doesn't care about my job title.

**Lenses:** Zengzi

**Response:**

```json
[
  { "lens": 1, "card": "You showed vulnerability by admitting fears to your mentor, which deepened your connection.", "sparse": false },
  { "lens": 2, "card": "Your commitment to preparing for interviews demonstrates reliability, even when doubting yourself.", "sparse": false },
  { "lens": 3, "card": "Choosing pottery class proves you're applying the lesson that identity isn't tied to work.", "sparse": false }
]
```

---

## Test 2: EN Career | deepseek-chat-v3-0324 | Blunt | BodyMindHeart

**Response time:** 9566ms

**Input entries:**
- 😰 Third round interview tomorrow. Prepared but can't shake the feeling I'm not qualified. Spent all weekend practicing answers.
- 😤 Current boss hinted my role might be eliminated in the restructuring. No timeline given. Hard to focus on anything else.
- 😊 Got a surprise call from an old mentor. She reminded me I've navigated harder transitions before. Offered to review my resume.
- 😐 Went for a walk at lunch to clear my head. Sometimes I forget that careers are marathons, not sprints.
- 🤩 Signed up for a pottery class tonight — something completely unrelated to work. The clay doesn't care about my job title.

**Lenses:** BodyMindHeart

**Response:**

```json
[
  { "lens": 1, "card": "Your shoulders are practically fused to your ears—maybe try that pottery class grip on your own tension.", "sparse": false },
  { "lens": 2, "card": "You're mentally rehearsing disaster scenarios like they're Shakespearean monologues.", "sparse": false },
  { "lens": 3, "card": "Your heart wants to be the lump of clay—shapeless, unjudged, and blissfully indifferent to restructuring.", "sparse": false }
]
```

---

## Test 3: EN Career | deepseek-chat-v3-0324 | Poetic | Honest Weather

**Response time:** 8847ms

**Input entries:**
- 😰 Third round interview tomorrow. Prepared but can't shake the feeling I'm not qualified. Spent all weekend practicing answers.
- 😤 Current boss hinted my role might be eliminated in the restructuring. No timeline given. Hard to focus on anything else.
- 😊 Got a surprise call from an old mentor. She reminded me I've navigated harder transitions before. Offered to review my resume.
- 😐 Went for a walk at lunch to clear my head. Sometimes I forget that careers are marathons, not sprints.
- 🤩 Signed up for a pottery class tonight — something completely unrelated to work. The clay doesn't care about my job title.

**Lenses:** Honest Weather

**Response:**

[
  { "lens": 1, "card": "The sunlight was your mentor's voice, warm and unexpected, reminding you of roots deeper than this moment.", "sparse": false },
  { "lens": 2, "card": "The rain was the weight of your boss's words, pooling in your chest, making every step feel heavier.", "sparse": false },
  { "lens": 3, "card": "Tomorrow's weather might be the smell of wet clay — neither success nor failure, just your hands shaping what comes.", "sparse": false }
]

---

## Test 4: ZH Career | deepseek-chat-v3-0324 | Warm | Zengzi

**Response time:** 4952ms

**Input entries:**
- 😰 明天的终轮面试，准备了一整个周末，还是觉得自己不够格。
- 😤 老板暗示我的岗位可能会在重组中被裁掉。没有给时间表，心里很乱。
- 😊 前导师打来电话，她说我经历过更难的过渡期。主动帮我改简历。
- 😐 午休时去散了步，提醒自己：职业生涯是马拉松，不是短跑。
- 🤩 晚上报了陶艺课，和职场完全无关。泥巴不在乎我的职位高低。

**Lenses:** Zengzi

**Response:**

```json
[
  { "lens": 1, "card": "Even when anxious about layoffs, you still prepared thoroughly for others' interview process.", "sparse": false },
  { "lens": 2, "card": "Your mentor's unexpected call revealed trust built over time - now she actively advocates for you.", "sparse": false },
  { "lens": 3, "card": "Choosing pottery class demonstrates applying the lesson that worth exists outside career validation.", "sparse": false }
]
```

---

## Test 5: ZH Relationships | deepseek-chat-v3-0324 | Blunt | BodyMindHeart

**Response time:** 4904ms

**Input entries:**
- 😤 妹妹又放我鸽子了，这个月第三次。我为了她推掉了整个周六的安排。开始觉得自己像个备胎。
- 😌 给她发了条冷静的信息：我很失望，但理解事情会有变动。等你方便的时候再约。感觉自己进步了。
- 😰 伴侣因为工作想搬到另一个城市，我才刚在这里安顿下来。不知道怎么开口讨论才不显得不支持。
- 😊 认识了新邻居。聊了45分钟园艺，毫无矫饰。原来友谊可以这么简单。
- 🤩 拒绝了一个不想去的社交活动，没道歉，没解释。有生以来第一次。太爽了。

**Lenses:** BodyMindHeart

**Response:**

```json
[
  { "lens": 1, "card": "Your shoulders remember how they squared up when you sent that text without groveling.", "sparse": false },
  { "lens": 2, "card": "You're mentally unpacking two suitcases at once: hers for the move, yours full of unspoken 'what ifs'.", "sparse": false },
  { "lens": 3, "card": "Your heart wants to plant something - maybe those geraniums the neighbor mentioned, maybe roots of your own.", "sparse": false }
]
```

---

## Test 6: ZH Creative | deepseek-chat-v3-0324 | Poetic | Honest Weather

**Response time:** 3266ms

**Input entries:**
- 😤 Day 14 盯着空白画布。画什么看起来都像抄袭。也许三年前就已经过了巅峰期，这就是漫长下坡路的开始。
- 😐 看了Agnes Martin的纪录片，她46岁才卖出第一幅画。提醒自己：时间线只是虚构。
- 😢 扔了三幅画。心疼但痛快。有些作品不是要完成的。
- 😌 没带手机逛了植物园。注意到叶子的重叠方式是我从未画过的图案。灵感也许需要沉默。
- 🤩 晚上用炭笔画速写，没有目的，没有观众。只有笔触和纸张摩擦的声音。找回了最初做艺术的冲动。

**Lenses:** Honest Weather

**Response:**

[
  { "lens": 1, "card": "炭笔在纸上沙沙作响，像夜风吹过枯叶", "sparse": false },
  { "lens": 2, "card": "揉皱的画布里藏着未说出的自我批评", "sparse": false },
  { "lens": 3, "card": "明天的调色盘上会有植物园叶影的淡彩", "sparse": false }
]

