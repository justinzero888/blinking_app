# Phase 1 UAT — Test Cases

> **Date:** May 22, 2026  
> **Build:** v1.2.0-dev (post Phase 1)  
> **Changes:** iPad share fix, deprecated API migration (share_plus + purchases_flutter), RevenueCat listener, receipt stub, platform audit

---

## Test Matrix

| # | Test | Device | Result |
|---|------|--------|--------|
| S-1 | Entry share (text) — share sheet opens with correct content | iPhone 17 Pro | ⬜ |
| S-2 | Entry share (text) — share sheet opens with correct content | iPad Air 11" (M4) | ⬜ |
| S-3 | Backup export (text-only) — ZIP created, share sheet opens | iPhone 17 Pro | ⬜ |
| S-4 | Backup export (text-only) — ZIP created, share sheet opens | iPad Air 11" (M4) | ⬜ |
| S-5 | Habit export (JSON) — share sheet opens, file attached | iPhone 17 Pro | ⬜ |
| S-6 | Habit export (JSON) — share sheet opens, file attached | iPad Air 11" (M4) | ⬜ |
| S-7 | Backup restore (text-only) — restore from ZIP, verify data intact | iPhone 17 Pro | ⬜ |
| S-8 | Backup restore (with media) — restore from ZIP, media files restored | iPhone 17 Pro | ⬜ |
| S-9 | Habit import (JSON) — import, verify routines added | iPhone 17 Pro | ⬜ |
| R-1 | Entry CRUD — create note, edit, delete, emotion picker | iPhone 17 Pro | ⬜ |
| R-2 | Entry CRUD — create checklist, toggle items, carry-forward | iPhone 17 Pro | ⬜ |
| R-3 | Routine CRUD — create daily routine, toggle complete | iPhone 17 Pro | ⬜ |
| R-4 | AI Assistant — multi-turn chat, save reflection | iPhone 17 Pro | ⬜ |
| R-5 | Insights — emoji jar carousel, charts render | iPhone 17 Pro | ⬜ |
| R-6 | Calendar — day navigation, emoji badges, routine checklist | iPhone 17 Pro | ⬜ |
| R-7 | Settings — language toggle (EN↔ZH), theme switch | iPhone 17 Pro | ⬜ |
| E-1 | Fresh install → preview mode active, 21 days, 3 AI/day | iPhone 17 Pro | ⬜ |
| E-2 | Debug toggle → restricted → tap robot → paywall | iPhone 17 Pro | ⬜ |
| E-3 | Debug toggle → preview → AI features work | iPhone 17 Pro | ⬜ |
| P-1 | Persona switch (Kael→Elara→Rush→Marcus) — avatar/name/lenses change | iPhone 17 Pro | ⬜ |
| P-2 | Custom persona create/edit/delete — full flow | iPhone 17 Pro | ⬜ |
| P-3 | Private tag filter — #私密 entries excluded from AI on all 5 surfaces | iPhone 17 Pro | ⬜ |
| A-1 | Android entry share (text) — share sheet opens | Android emulator | ⬜ |
| A-2 | Android backup export — ZIP created, share sheet opens | Android emulator | ⬜ |
| A-3 | Android IAP purchase flow — RevenueCat sandbox | Android emulator | ⬜ |

---

## Instructions

1. Launch all 3 simulators: `iPhone 17 Pro`, `iPad Air 11-inch (M4)`, `Medium_Phone_API_36.1`
2. Build and install the app on each
3. Execute tests in order: S-1 through S-10 (share/export/import), then R-1 through R-7 (regression)
4. Execute entitlement tests E-1 through E-3
5. Execute persona tests P-1 through P-3
6. Execute Android tests A-1 through A-3
7. Mark each row ✅ or ❌ with notes
