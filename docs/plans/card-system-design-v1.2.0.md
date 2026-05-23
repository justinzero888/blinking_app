# Card System Revitalization — Design Document

> **Part of:** v1.2.0 Implementation Plan  
> **Target:** June 18, 2026  
> **Status:** All 11 design decisions locked. Scope revised May 23 — v1.2.0 focused on Keepsake cards. XHS Export deferred to v1.3.0.

---

## 1. Two Use Cases

Two distinct user goals were identified. v1.2.0 ships Keepsake only.

| | **Keepsake Card** (v1.2.0) | **XHS Export** (v1.3.0+) |
|---|---|---|
| **Goal** | Preserve a memory — photo + text, beautiful, personal | Share on 小红书 — readable, swipeable, platform-native |
| **Primary user** | Journal keeper | Creator/sharer |
| **Multi-page?** | ❌ Not needed. One moment, one card. | ✅ Critical. Long entries must span multiple images. |
| **Photo on card?** | ✅ Critical — combine photo with note text | Nice-to-have |
| **Aspect ratio** | 3:4 portrait (fixed) | 3:4 portrait (fixed) |
| **Template variety** | One beautiful pick | Variety matters for social feed |
| **AI Rewrite** | Optional polish | Important for public sharing |
| **Where it lives** | In-app (linked to source entry) + camera roll | Camera roll → RedNotes app |
| **Re-edit?** | From source entry always possible | N/A — shared once |

---

## 2. Goals (v1.2.0)

1. **Revive the `NoteCard` system** — restore `CardProvider` registration, rebuild UI for card creation
2. **Richer templates** — replace 6 primitive color-only templates with 8 RedNotes-style layouts
3. **Keepsake creation** — single-page cards from entry content + photo + emotion + tags
4. **Two content sources** — cards can be created from:
   - Original notes (single entry)
   - AI-generated reflections (from Reflection Session or Assistant chat)
5. **Restore-safe** — cards re-render from metadata on restore, no backup bloat

---

## 3. Current State (What We Have)

| Asset | Status | Notes |
|-------|--------|-------|
| `NoteCard` model | Exists, works | `id`, `entryIds`, `templateId`, `folderId`, `renderedImagePath`, `aiSummary`, `richContent` |
| `CardTemplate` model | Exists, works | `id`, `name`, `icon`, `fontFamily`, `fontColor`, `bgColor`, `isBuiltIn`, `customImagePath` |
| `CardProvider` | Exists, **not registered** | CRUD methods defined, no UI calls them |
| DB tables | Exist, intact | `note_cards`, `note_card_entries`, `templates`, `card_folders` |
| 6 built-in templates | Seeded, **unused** | Spring Day, Midnight Blue, Warm Sunrise, Minimal, Forest Green, Custom |
| Card renderer | **Deleted** | Old `card_renderer.dart` used flutter_quill + auto-font sizing |
| Card builder dialog | **Deleted** | Old `card_builder_dialog.dart` had AI merge (≤100 words) |
| Card editor screen | **Deleted** | Old `card_editor_screen.dart` used flutter_quill rich text |
| Card preview screen | **Deleted** | Old `card_preview_screen.dart` showed rendered PNG |

---

## 4. RedNotes (小红书) Card Aesthetics — Reference

Typical 小红书 post card characteristics to emulate:

| Element | RedNotes Style |
|---------|---------------|
| **Layout** | Image-first, often full-bleed photo background or textured/gradient fill |
| **Aspect ratio** | 3:4 portrait or 1:1 square |
| **Text** | Short quote or reflection, clean serif or modern sans-serif, 1-3 lines prominent + optional body |
| **Visual flourishes** | Subtle borders, decorative lines, mood emoji accent, date stamp |
| **Tags** | Hashtags at bottom in small, muted text |
| **Branding** | Small app watermark/logo (optional) |
| **Mood** | Color palette should reflect entry emotion or template theme |

---

## 5. Template System

### 5.1 Template Model Changes

Add fields to `CardTemplate` to support richer layouts:

```dart
class CardTemplate {
  // existing fields
  String id;
  String name;
  String nameEn;
  String icon;           // emoji
  String fontFamily;     // 'default' | 'serif' | 'sans'
  String fontColor;      // #hex
  String bgColor;        // #hex
  bool isBuiltIn;
  String? customImagePath;
  String? sourceTemplateId;
  DateTime createdAt;

  // NEW fields
  CardLayout layout;          // hero_image | centered | left_aligned | two_column
  String? accentColor;        // #hex — for borders, lines, tag badges
  double? textAreaOpacity;    // 0.0–1.0 — semi-transparent text backdrop
  String? textBackdropColor;  // #hex — background behind text block
  String? footerText;         // "Blinking Notes" or custom (default: "Blinking Notes")
  bool showMood;              // include emotion emoji in card (default: true)
  bool showDate;              // include date stamp (default: true)
  bool showTags;              // include entry tags as hashtags at bottom (default: true)
  bool showFooter;            // include app watermark (default: true)
  CardCornerStyle cornerStyle; // rounded | sharp | pill
  String? decorationStyle;    // bamboo | seal | landscape | porcelain | tea — template motif
}
```

### 5.2 Layout Types

| Layout | Description | Keepsake Fit |
|--------|-------------|--------------|
| `hero_image` | Full-bleed background image with text overlay (centered, with semi-transparent backdrop) | Primary — photo + text combined |
| `centered` | Solid/gradient background, text centered vertically | Quote cards, reflections |
| `left_aligned` | Text left-aligned with accent bar on left edge | Journal/note style |
| `two_column` | Image left, text right (or top/bottom split) | Photo + caption |

### 5.3 Built-in Templates (8 RedNotes-Inspired)

Replace the 6 color-only templates with 8 templates using Chinese aesthetic design (宁静 · 淡雅 · 含蓄):

| ID | Name (ZH) | Name (EN) | Layout | Character |
|----|-----------|-----------|--------|-----------|
| `tpl_ink_rhythm` | 墨韵 | Ink Rhythm | hero_image | Ink wash gradient + cinnabar accent line. Desaturated photo overlay. |
| `tpl_plain_paper` | 素笺 | Plain Paper | left_aligned | Rice paper texture, cinnabar left accent bar, ruled lines. |
| `tpl_bamboo` | 竹影 | Bamboo Shadow | hero_image | Celadon green gradient + subtle bamboo leaf silhouette. |
| `tpl_moonlight` | 月色 | Moonlight | centered | Deep navy gradient + silver text + crescent moon. For evening reflections. |
| `tpl_porcelain` | 青花 | Blue Porcelain | centered | Off-white + porcelain blue borders + vine motif. Elegant, restrained. |
| `tpl_tea` | 茶语 | Tea Whisper | hero_image | Amber-tea gradient + steam wave curves. Warm, quiet. |
| `tpl_seal` | 朱砂 | Cinnabar Seal | centered | Rice paper bg + single cinnabar seal stamp accent. Minimalist, powerful. |
| `tpl_landscape` | 山水 | Landscape | hero_image | Layered mountain silhouettes + mist gradient. For travel/nature memories. |

Full template specs (colors, fonts, decorations): [`design-card-technical.md`](./design-card-technical.md)

### 5.4 Customization Per Card

Users can edit per-card (D2 — full per-card, save-as-template deferred):
- Font color, accent color
- Text backdrop opacity
- Toggle mood emoji, date, tags, footer visibility
- Photo source: entry image or none

Custom template saving deferred to v1.3.0 (D11).

---

## 6. Keepsake Creation Flow

### 6.1 From Entry

```
EntryDetailScreen
  └─ "Save as Keepsake" button
       └─ CardBuilderSheet (bottom sheet)
            ├─ Mode: "Save as Keepsake" (single page, photo+text, persist to DB)
            ├─ Template picker (horizontal scroll, 8 thumbnails)
            ├─ Content: pre-filled with entry text (editable)
            ├─ Photo: entry's first photo (if any), with full-bleed / header toggle per template
            ├─ Toggle row: show mood / show date / show tags / show footer
            ├─ "AI Rewrite" button (optional polish)
            └─ "Save Keepsake" → render PNG 1080×1440 → persist NoteCard to DB → save to camera roll
```

### 6.2 From AI Reflection

```
ReflectionSessionScreen / AssistantScreen
  └─ "Save as Keepsake" button
       └─ CardBuilderSheet
            ├─ Same as entry flow above
            ├─ Content: AI reflection text (editable)
            ├─ Emotion: derived from reflection context
            └─ "Save Keepsake" → render → persist → camera roll
```

### 6.3 Revisit Keepsake (Post-Save)

```
EntryDetailScreen
  └─ If entry has linked NoteCard:
       └─ "Keepsake" badge → tap → CardPreviewScreen → shows rendered PNG
            └─ "Share" → system share sheet (re-shares same PNG)
            └─ "Edit" → re-open CardBuilderSheet with pre-filled content + config
```

---

## 7. Rendering Pipeline

### 7.1 Render Flow

```
CardBuilderSheet (user confirms content + template)
  └─ CardRenderService.renderCard()
       ├─ Load template (bg gradient or solid color + decoration motif)
       ├─ Load photo (if available, per-template handling)
       ├─ Apply layout (position text block, accent elements)
       ├─ Render text with auto-font sizing (96px→9px, CJK+English aware)
       ├─ Add optional elements (mood emoji, date, tags, footer)
       ├─ Output: single PNG at 1080×1440 (3:4 portrait), ~800KB–2MB
       └─ Save to NoteCard.renderedImagePath
  └─ CardPreviewScreen
       ├─ Full-screen preview of rendered PNG
       ├─ "Share" button → system share sheet
       └─ "Edit" button → re-open CardBuilderSheet
```

### 7.2 Render Resolution

| Resolution | Aspect | Use |
|------------|--------|-----|
| 1080×1440 | 3:4 | v1.2.0 — single fixed ratio for Keepsake cards |
| Output format | PNG | — |

1:1 square format deferred to v1.3.0 (for XHS / social sharing).

### 7.3 Restore Strategy: Re-render on Demand

Rendered PNGs are NOT included in backup. Only card metadata (DB row) is exported.

| Store in Backup | Don't Store |
|-----------------|-------------|
| `NoteCard` row in DB (all fields) | `renderedImagePath` — regenerated lazily |
| Entry photo (already in backup via entry) | Rendered PNG files |
| Card-specific uploaded photos | — |

On restore, `CardRenderService.getCardImage()`:
```dart
static Future<String> getCardImage(NoteCard card) {
  if (card.renderedImagePath != null && File(card.renderedImagePath).existsSync()) {
    return card.renderedImagePath; // cached
  }
  return renderCard(card: card, template: template); // re-render from stored config
}
```

**Backup impact:** ~2KB per card (metadata only) vs. ~2MB per card (with PNG). A user with 50 keepsakes adds ~100KB to backup instead of ~100MB.

---

## 8. Entry Detail Keepsake Indicator

No separate Card History screen (deferred to v1.2.1). Instead, a minimal indicator on `EntryDetailScreen`:

```
EntryDetailScreen
  ├─ Entry content (existing)
  ├─ Emotion + tags (existing)
  ├─ Photo (existing)
  └─ [If linked NoteCard exists:]
       └─ "Keepsake" badge (small chip with card icon)
            ├─ Tap → CardPreviewScreen (full-screen PNG)
            ├─ Shows template name + creation date
            └─ Share button to re-share
```

The badge is the one-to-one link: entry → keepsake. One entry can have one keepsake card. No grid browsing needed.

---

## 9. Tags on Cards

Tags from the source entry are rendered as styled hashtags at the bottom of the card:

```
┌──────────────────────────────┐
│                              │
│   "Today was a good day..."  │
│                              │
│   😊  2026-06-18             │
│                              │
│   #日记 #日常 #感恩            │
│         Blinking Notes        │
└──────────────────────────────┘
```

- Font: 2-3 sizes smaller than body text
- Color: accent color or muted (60% opacity of body color)
- Max tags shown: 5 (with "+2 more" overflow if needed)
- System tags (`tag_synthesis`, `tag_private`) excluded from display

---

## 10. Data Model Changes

### 10.1 New Fields on NoteCard

```dart
class NoteCard {
  // existing
  String id;
  List<String> entryIds;
  String templateId;
  String folderId;
  String? renderedImagePath;    // regenerated lazily on restore
  String? aiSummary;            // AI-merged text (for multi-entry cards — deferred)
  String? richContent;          // user-edited text
  DateTime createdAt;
  DateTime updatedAt;

  // NEW (v1.2.0)
  String? cardContent;          // final text displayed on card (post-edit)
  String? emotion;              // emoji shown on card
  List<String>? displayTags;    // tags shown as hashtags on card
  bool showMood;                // per-card override (default: true)
  bool showDate;                // per-card override (default: true)
  bool showTags;                // per-card override (default: true)
  bool showFooter;              // per-card override (default: true)
  String? templateOverrides;    // JSON — user style overrides (fontColor, accentColor, textOpacity, etc.)
}
```

### 10.2 DB Migration (v15)

- Add columns to `note_cards`: `card_content TEXT`, `emotion TEXT`, `display_tags TEXT` (JSON array), `show_mood INTEGER DEFAULT 1`, `show_date INTEGER DEFAULT 1`, `show_tags INTEGER DEFAULT 1`, `show_footer INTEGER DEFAULT 1`, `template_overrides TEXT`
- Add columns to `templates`: `layout TEXT DEFAULT 'hero_image'`, `accent_color TEXT`, `text_area_opacity REAL DEFAULT 0.85`, `text_backdrop_color TEXT`, `footer_text TEXT DEFAULT 'Blinking Notes'`, `show_mood INTEGER DEFAULT 1`, `show_date INTEGER DEFAULT 1`, `show_tags INTEGER DEFAULT 1`, `show_footer INTEGER DEFAULT 1`, `corner_style TEXT DEFAULT 'rounded'`, `decoration_style TEXT`

Note: Migration bumped to v15 since v14 was consumed by T-6 (voice_notification columns on routines).

---

## 11. UI Components to Build

| Component | Description | New/Revived | v1.2.0 |
|-----------|-------------|-------------|:---:|
| `CardProvider` registration | Register in `app.dart` provider tree | Revived | ✅ |
| `CardTemplatePicker` | Horizontal scroll of 8 template thumbnails with selection highlight | New | ✅ |
| `CardBuilderSheet` | Bottom sheet: template select + content edit + photo handling + toggles + AI Rewrite + Save | New | ✅ |
| `CardPreviewScreen` | Full-screen PNG preview + share/edit buttons (single page only) | New | ✅ |
| `CardRenderService` | Off-screen PNG renderer with template engine + re-render-on-restore logic | New | ✅ |
| `EntryDetailScreen` "Save as Keepsake" | Button → opens `CardBuilderSheet` | New | ✅ |
| `EntryDetailScreen` Keepsake badge | Chip indicator if entry has linked card → tap to preview | New | ✅ |
| `ReflectionSessionScreen` "Save as Keepsake" | Button in reflection → opens `CardBuilderSheet` | New | ✅ |
| `AssistantScreen` "Save as Keepsake" | Button on saved reflection → opens `CardBuilderSheet` | New | ✅ |
| `CardHistoryScreen` | Grid of previously created cards | New | ❌ Deferred to v1.2.1 |

---

## 12. Deletions / Deprecations

| Item | Action |
|------|--------|
| Old 6 color-only templates | Replace with 8 new templates (migration: delete old, seed new) |
| `card_builder_dialog.dart` (deleted) | Replaced by `CardBuilderSheet` |
| `card_editor_screen.dart` (deleted) | Content editing now inline in `CardBuilderSheet` |
| `card_preview_screen.dart` (deleted) | Replaced by new `CardPreviewScreen` |
| `card_renderer.dart` (deleted) | Replaced by `CardRenderService` |
| flutter_quill dependency | Not needed — plain text editing only (no rich text) |

---

## 🗳 Design Decisions — ALL LOCKED (May 23, 2026)

| D# | Decision | Resolution |
|----|----------|------------|
| **D1** | Template replacement strategy | **Replace all** — delete 6 old, seed 8 new |
| **D2** | Template customizability | **Full per-card** — user can edit font color, accent, opacity, toggles per card. Custom template saving deferred to v1.3.0. |
| **D3** | Background images | **Both** — built-in gradients + entry photo. Custom user-uploaded backgrounds deferred to v1.3.0. |
| **D4** | Card content editing | **Pre-filled, editable** + "AI Rewrite" button |
| **D5** | Multi-entry merge | **Deferred to v1.3.0** — serves neither Keepsake nor XHS use case |
| **D6** | Card aspect ratio | **3:4 portrait fixed** for v1.2.0. 1:1 alternative deferred to v1.3.0. |
| **D7** | Persistence | **Persist metadata only** — re-render PNGs lazily on first view/restore. No backup bloat. |
| **D8** | Multi-page support | **Deferred to v1.3.0** — only needed for XHS export, not Keepsake |
| **D9** | Image handling per template | **Per-template defaults** — full-bleed on hero layouts, hero header on photo layouts, inline on journal layouts. |
| **D10** | Page break awareness | **Deferred to v1.3.0** — only needed for multi-page XHS export |
| **D11** | Saved custom templates | **Built-in only for v1.2.0.** Custom template saving deferred to v1.3.0. |
| **D12** | XHS Export mode | **Deferred to v1.3.0** — v1.2.0 ships Keepsake only |
| **D13** | Card History screen | **Deferred to v1.2.1** — replaced by Keepsake badge on EntryDetailScreen |
| **D14** | Re-render on restore | **Metadata only in backup** — PNGs regenerated lazily. ~2KB/card vs. ~2MB/card. |

---

## 13. Deferred to Later Versions

| Item | Target | Reason |
|------|--------|--------|
| Card History screen (grid) | v1.2.1 | Camera roll + entry badge covers current needs |
| XHS Export mode (multi-page, page breaks, ratio toggle) | v1.3.0 | Separate use case, needs its own design pass |
| Multi-entry merge | v1.3.0 | Niche feature, neither core use case needs it now |
| Custom background uploads | v1.3.0 | Entry photos cover the primary photo integration need |
| Custom template saving | v1.3.0 | Per-card customization ships first |
| Manual page break adjustment | v1.3.0 | Depends on XHS Export mode |

---

## Next Steps

1. Build Phase 3 per revised execution plan (May 29 – Jun 8, ~11 days)
2. Deploy Keepsake cards in v1.2.0
3. XHS Export design pass + implementation in v1.3.0
