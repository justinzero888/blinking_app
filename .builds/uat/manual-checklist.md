# Manual UAT — Phase 3 Keepsake Cards

> **Build:** _fill commit hash_ | **Devices:** iPhone (real), iPad (real)  
> **Instructions:** Complete each case. Check the box. Add notes for any issues.

---

## Visual Rendering Fidelity

### MV-1: All 8 templates visual QA
- [ ] 墨韵 — ink wash gradient visible, cinnabar line present, text readable
- [ ] 素笺 — rice paper texture, red accent bar, left aligned text
- [ ] 竹影 — celadon gradient, bamboo leaf silhouette visible
- [ ] 月色 — navy gradient, crescent moon, white text readable
- [ ] 青花 — porcelain blue borders, vine motif, centered text
- [ ] 茶语 — amber gradient, steam wave curves visible
- [ ] 朱砂 — rice paper bg, red seal stamp centered below text
- [ ] 山水 — mountain silhouettes, mist gradient, text overlay readable

### MV-2: Decorative motifs
- [ ] 竹影 template — bamboo leaf visible in corner
- [ ] 朱砂 template — red seal stamp visible
- [ ] 山水 template — mountain silhouettes in gradient
- [ ] 月色 template — crescent moon in background
- [ ] 茶语 template — steam curves visible
- [ ] 青花 template — porcelain borders at top

### MV-3: Style override
- [ ] Change font color to red → render → verify color is correct red
- [ ] Change text backdrop opacity → verify readability

### MV-4: Dark mode
- [ ] Switch to dark theme
- [ ] Create keepsake with 月色 template → still readable
- [ ] Check all 8 templates → no washed-out or invisible text

## Device-Specific

### MV-5: iPad share keepsake
- [ ] Create keepsake on iPad
- [ ] Badge → Preview → tap share
- [ ] Share sheet opens, file attached

### MV-6: Restore — keepsake survives
- [ ] Create 3 keepsakes with different templates
- [ ] Export backup
- [ ] Uninstall app → reinstall → restore backup
- [ ] Open entries → badges visible → tap → card re-renders correctly

### MV-7: Backup size
- [ ] Create 5 keepsakes
- [ ] Export backup
- [ ] Check ZIP size → < 200KB larger than without keepsakes

## AI-Dependent

### MV-8: AI Rewrite
- [ ] Entry → Save as Keepsake → Builder → tap "AI 润色"
- [ ] Content changes to AI-rewritten version
- [ ] Loading spinner displays during call
- [ ] Error handling if AI unavailable

---

## Results

| Case | iPhone | iPad | Notes |
|------|:------:|:----:|-------|
| MV-1 | ⬜ | ⬜ | |
| MV-2 | ⬜ | ⬜ | |
| MV-3 | ⬜ | ⬜ | |
| MV-4 | ⬜ | ⬜ | |
| MV-5 | ⬜ | ⬜ | |
| MV-6 | ⬜ | ⬜ | |
| MV-7 | ⬜ | ⬜ | |
| MV-8 | ⬜ | ⬜ | |

**Tester:** _fill name_  
**Date:** _fill date_
