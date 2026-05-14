# Annual Reflection — Feature Spec

**Status:** Proposed | **API Calls:** 13 | **Cost/year:** ~$0.0025 | **UX:** 1 button, 1 result

---

## UX Flow

```
Insights tab → end of page → "Annual Reflection" button
                                                │
                                    ┌───────────┴───────────┐
                                    │ Generating... 1/12 Jan │
                                    │ (takes 15-20s total)   │
                                    └───────────┬───────────┘
                                                │
                                    ┌───────────┴───────────┐
                                    │ Annual Reflection     │
                                    │                      │
                                    │ Theme: Growth through │
                                    │   uncertainty         │
                                    │                      │
                                    │ Journey: How your     │
                                    │ moods shifted across  │
                                    │ seasons...            │
                                    │                      │
                                    │ [Save to Journal]     │
                                    └───────────────────────┘
```

## Architecture: Rolling Summary

```
Step 1: Divide year into 12 monthly chunks
  Jan entries → AI monthly summary (200 tokens)
  Feb entries → AI monthly summary (200 tokens)
  ...
  Dec entries → AI monthly summary (200 tokens)

Step 2: Feed all 12 monthly summaries to final AI call
  12 summaries → Annual Reflection (500 tokens)
```

### Why this works

| Concern | Solution |
|---------|----------|
| Token cap (3000) | Each monthly call only has 1 month of entries |
| Context quality | Monthly AI summaries capture patterns before final synthesis |
| Speed | 12 × ~3s + 1 × ~5s = ~40s total (streaming shows progress) |
| Cost | 13 calls × $0.00017 avg = **$0.0022/year/user** |

## Cost Projection

| | Per user/year | 100 users | 1,000 users | 10,000 users |
|---|:---:|:---:|:---:|:---:|
| Annual Reflection | $0.0022 | $0.22 | $2.20 | $22 |
| + Daily usage (max) | $0.40 | $40 | $400 | $4,000 |
| **Total** | **$0.40** | **$40** | **$402** | **$4,022** |

Annual feature adds 0.5% to total cost.

## Implementation

### Prompt Assembler additions

```dart
String assembleMonthlySummary(List<Entry> monthEntries, String persona, bool isZh)
String assembleAnnualReflection(List<String> monthlySummaries, String persona, bool isZh)
```

### Monthly summary prompt

```
SYSTEM: You are a journaling companion. Summarize this month's entries in 3-5 sentences.
Focus on: emotional arc, recurring themes, key moments, and one pattern the user may not see.
Voice: "{persona}"
Entries: [list of this month's entries]
```

### Annual reflection prompt

```
SYSTEM: You are a journaling companion. You have 12 monthly summaries from the past year.
Write an annual reflection that:
1. Identifies 2-3 themes that span multiple months
2. Notes emotional shifts across seasons
3. Highlights one personal growth arc
4. Ends with a forward-looking reflection
Voice: "{persona}"
Monthly summaries: [12 summaries]
```

### UI

```
Insights tab → bottom section
┌──────────────────────────────┐
│ 📊 Annual Reflection          │
│                              │
│ One comprehensive review     │
│ of your year.                │
│                              │
│ [Generate Annual Reflection] │
│ (13 AI calls ~ 30s)          │
│                              │
│ Previously generated:        │
│ ┌────────────────────────┐   │
│ │ 2025 Annual Reflection │   │
│ └────────────────────────┘   │
└──────────────────────────────┘
```

## Alternative: Representative Sampling

Lighter version if rolling summary is too heavy:

```
Select 24 entries (2 per month: highest-emotion + longest entry)
Single API call with those 24 entries as context
Prompt: "Write an annual reflection based on these moments from the past year..."

Cost: 1 call × $0.00020 = $0.00020/year/user
Quality: Good snapshots, misses gradual patterns
```

## Recommendation

Ship **representative sampling** first (1 call, fast, cheap). Add rolling summary if users request deeper quality. The sampling version still delivers 80% of the value at 10% of the cost.
