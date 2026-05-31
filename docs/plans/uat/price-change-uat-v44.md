# v1.2.0+44 — Price Change & Purchase Fix UAT Checklist

> **Version:** 1.2.0+44 (build 44)
> **Changes:** Dynamic pricing from RevenueCat, crash guard for missing RC key, price $19.99→$7.99
> **Manual only** — visual price verification across all 6 surfaces.

---

## Maestro Automated

| ID | Flow | File | iPhone | iPad | Android |
|----|------|------|:------:|:----:|:-------:|
| p1 | Paywall loaded — RC initialized, price displayed, "Get Pro" enabled | `p1-paywall-ready.yaml` | 🔲 | 🔲 | 🔲 |

### Run command
```bash
maestro test maestro-tests/apps/blink-notes/flows/uat/p1-paywall-ready.yaml
```

**Expected:** Paywall shows `$7.99` (or localized equivalent), "Get Pro" button is enabled (not greyed out), "Restore Purchases" visible. No "Store unavailable" warning.

---

## Manual — Price Display Verification

**Setup:** Fresh install + complete onboarding. For paywall: Settings → About → tap version 5x → tap robot.

### M-1: Paywall screen
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Large price shows store price (not hardcoded) | | | 🔲 | 🔲 | 🔲 |
| "Get Pro" button shows correct price | `Get Pro — $X` | `获取 Pro — $X` | 🔲 | 🔲 | 🔲 |
| "Get Pro" button is enabled (not greyed out) | | | 🔲 | 🔲 | 🔲 |
| No "Store unavailable" warning below button | | | 🔲 | 🔲 | 🔲 |

### M-2: Onboarding — Screen 3 (The Deal)
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Price in text matches store price | `Pro is $X once...` | `Pro 一次购买 $X...` | 🔲 | 🔲 | 🔲 |

### M-3: Settings — AI tab (restricted state)
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Button shows correct price | `Get Pro — $X` | `获取 Pro — $X` | 🔲 | 🔲 | 🔲 |

### M-4: Settings — AI entitlement banner (preview state)
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Banner button shows price | `Get Blinking Pro — $X` | `获取 Blinking Pro — $X` | 🔲 | 🔲 | 🔲 |

### M-5: Settings — AI entitlement banner (restricted state)
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Orange banner button shows price | `Get Blinking Pro — $X once, lifetime` | `获取 Blinking Pro — $X 一次购买，终身使用` | 🔲 | 🔲 | 🔲 |

### M-6: Floating robot — long-press menu
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Menu item shows price | `Get Pro — $X once` | `获取 Pro — $X 一次购买` | 🔲 | 🔲 | 🔲 |
| Tap menu item opens paywall | | | 🔲 | 🔲 | 🔲 |

### M-7: Day 21 Transition screen
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Button shows price | `Get Pro — $X` | `获取 Pro — $X` | 🔲 | 🔲 | 🔲 |

### M-8: Soft prompt (day 19 preview re-engagement)
| Check | EN | ZH | iPhone | iPad | Android |
|-------|----|----|:------:|:----:|:-------:|
| Dialog body shows price | `Pro is $7.99 once...` | `Pro 只需 $7.99...` | 🔲 | 🔲 | 🔲 |
| Dialog CTA button shows price | `Get Pro — $X` | `获取 Pro — $X` | 🔲 | 🔲 | 🔲 |

---

## Manual — Purchase Flow

| Check | Description | iPhone | iPad | Android |
|-------|-------------|:------:|:----:|:-------:|
| P-1 | Tap "Get Pro" → native purchase sheet appears | 🔲 | 🔲 | 🔲 |
| P-2 | Test Store: valid purchase → "Welcome to Pro!" snackbar | 🔲 | 🔲 | 🔲 |
| P-3 | "Restore Purchases" → works with test account | 🔲 | 🔲 | 🔲 |

---

## Regression — Existing Maestro Flows

Run full suite (32/26 flows) to confirm no regressions:
```bash
./maestro-tests/ci/run-uat-iphone.sh --device E755BD80
./maestro-tests/ci/run-uat-ipad.sh --device 39B46CD1
./maestro-tests/ci/run-uat-android.sh --device emulator-5554
```

| Platform | Result | Notes |
|----------|--------|-------|
| iPhone | 🔲 | |
| iPad | 🔲 | |
| Android | 🔲 | |

> **Note about k1–k10 keepsake flows:** These depend on demo entries seeded by `_seedDemoEntries()` which was removed in v1.2.0+44. The flows may fail on fresh install. Create a test entry manually before running keepsake flows, or add a setup step to create a seed entry in `subflows/launch.yaml`.

---

**Tester:** _______
**Date:** _______
**Build:** 1.2.0+44
**Overall result:** PASS / FAIL
