# Keepsake Cards UAT — Results

> **Date:** ________  
> **Tester:** ________  
> **Build:** v1.2.0-dev (clean build, simulators)

---

## Automated Results (Maestro)

| Flow | Description | iPhone | iPad | Android | Notes |
|------|------------|:------:|:----:|:-------:|-------|
| K1 | Core keepsake creation | ⬜ | ⬜ | ⬜ | |
| K2 | All 8 templates cycle | ⬜ | ⬜ | ⬜ | |
| K3 | Toggle elements on/off | ⬜ | ⬜ | ⬜ | |
| K4 | AI Rewrite button | ⬜ | ⬜ | ⬜ | |
| K5 | Empty content validation | ⬜ | ⬜ | ⬜ | |
| K6 | Badge → preview → back | ⬜ | ⬜ | ⬜ | |
| K7 | Photo keepsake | ⬜ | ⬜ | ⬜ | |
| K8 | ZH locale Chinese UI | ⬜ | ⬜ | ⬜ | |
| K9 | Edit existing keepsake | ⬜ | ⬜ | ⬜ | |
| K10 | Three entry points | ⬜ | ⬜ | ⬜ | |
| **Totals** | | __/10 | __/10 | __/10 | |

---

## Manual Visual QA

### iPhone 17 Pro

| Template | BG Image | Text Position | Overlay Size | No Yellow | Zoom | Back Nav | Result |
|----------|:--------:|:------------:|:------------:|:---------:|:----:|:--------:|--------|
| 🖋️ 墨韵 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 📃 素笺 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🎋 竹影 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🌙 月色 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🏺 青花 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🍵 茶语 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🔴 朱砂 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🏔️ 山水 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |

### iPad Air 11" (M4)

| Template | BG Image | Text Position | Overlay Size | No Yellow | Zoom | Back Nav | Result |
|----------|:--------:|:------------:|:------------:|:---------:|:----:|:--------:|--------|
| 🖋️ 墨韵 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 📃 素笺 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🎋 竹影 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🌙 月色 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🏺 青花 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🍵 茶语 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🔴 朱砂 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🏔️ 山水 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |

### Android

| Template | BG Image | Text Position | Overlay Size | No Yellow | Zoom | Back Nav | Result |
|----------|:--------:|:------------:|:------------:|:---------:|:----:|:--------:|--------|
| 🖋️ 墨韵 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 📃 素笺 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🎋 竹影 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🌙 月色 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🏺 青花 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🍵 茶语 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🔴 朱砂 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| 🏔️ 山水 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |

---

## Ship Gate Checklist

- [ ] 10/10 Maestro flows pass on iPhone
- [ ] 10/10 Maestro flows pass on iPad
- [ ] 10/10 Maestro flows pass on Android
- [ ] All 24 manual QA cells checked (8 templates × 3 platforms)
- [ ] No crashes during save on any platform
- [ ] No yellow underline on any template
- [ ] Background images render on all platforms
- [ ] Overlay elements correctly sized
- [ ] Photo cards render correctly
- [ ] AI Rewrite preamble does not appear in card content

---

## Issues Found

| ID | Platform | Template | Description | Severity |
|----|----------|----------|-------------|----------|
| | | | | |

---

## Sign-off

- [ ] **Ready to ship** (all gates passed)
- [ ] **Needs fixes** (issues documented above)
