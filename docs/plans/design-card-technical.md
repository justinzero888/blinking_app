# Card System — Technical Design & Test Plan

> **Date:** May 23, 2026 (revised)  
> **Phase:** 3 | **Status:** Design locked (D1–D14) | **Scope:** v1.2.0 Keepsake-only  
> **Design philosophy:** 宁静 · 淡雅 · 含蓄 — calm, quiet, with subtle traditional Chinese elements

---

## 1. Design Philosophy: Blinking × Chinese Aesthetics

### Core Principles

| Principle | Expression in Cards |
|-----------|-------------------|
| **宁静 (Calm)** | Soft color palettes. No neon, no harsh contrasts. Gradients over flat colors. Whitespace over clutter. |
| **淡雅 (Quiet Elegance)** | Muted tones. Single accent color max. Subtle textures (rice paper, ink wash). Fonts that breathe. |
| **含蓄 (Restrained)** | No loud patterns. Motifs are subtle — a bamboo silhouette, a seal stamp, a misty mountain gradient. Nothing that screams. |

### Color Palette

| Name | Hex | Use |
|------|-----|-----|
| Rice Paper | `#F5F0E8` | Background |
| Ink Black | `#2C2C2C` | Primary text |
| Ink Grey | `#8C8C8C` | Secondary text, date |
| Cinnabar | `#C43A31` | Accent only (seal stamp, single line) |
| Celadon | `#8FBFB3` | Calm accent |
| Moonlight Blue | `#3A4F6B` | Dark bg text |
| Mist White | `#E8E4DF` | Gradient light end |
| Tea Amber | `#D4A76A` | Warm accent |
| Porcelain Blue | `#2B5F8A` | Blue accent |
| Bamboo Green | `#7A9A6D` | Subtle green |

---

## 2. Template Designs (8 Templates)

(Template specifications unchanged from original design — see [`card-system-design-v1.2.0.md` §5.3](./card-system-design-v1.2.0.md).)

| ID | Name (ZH) | Name (EN) | Layout | Decoration |
|----|-----------|-----------|--------|-----------|
| `tpl_ink_rhythm` | 墨韵 | Ink Rhythm | hero_image | Ink wash gradient + cinnabar line |
| `tpl_plain_paper` | 素笺 | Plain Paper | left_aligned | Rice paper texture + red accent bar |
| `tpl_bamboo` | 竹影 | Bamboo Shadow | hero_image | Celadon gradient + bamboo leaf silhouette |
| `tpl_moonlight` | 月色 | Moonlight | centered | Navy gradient + crescent moon |
| `tpl_porcelain` | 青花 | Blue Porcelain | centered | White bg + porcelain blue borders |
| `tpl_tea` | 茶语 | Tea Whisper | hero_image | Amber gradient + steam curves |
| `tpl_seal` | 朱砂 | Cinnabar Seal | centered | Rice paper bg + red seal stamp |
| `tpl_landscape` | 山水 | Landscape | hero_image | Mountain silhouettes + mist |

---

## 3. Technical Architecture

### Component Tree (v1.2.0 Keepsake-Only)

```
CardBuilderSheet (BottomSheet)
  ├── TemplatePicker (horizontal scroll of 8 thumbnails)
  ├── ContentEditor (text field + AI Rewrite button)
  ├── PhotoSection (entry photo preview + full-bleed/header/inline toggle)
  ├── StylePanel (collapsible)
  │   ├── ColorPicker (font color + accent color)
  │   ├── OpacitySlider (text backdrop)
  │   └── ToggleRow (mood / date / tags / footer)
  └── "Save Keepsake" button → CardPreviewScreen

EntryDetailScreen
  ├── Entry content (existing)
  ├── Emotion + tags (existing)
  ├── Photo (existing)
  └── [If linked NoteCard:] Keepsake badge
       └── Tap → CardPreviewScreen

CardPreviewScreen (single page only)
  ├── FullPreview (rendered PNG, full screen)
  ├── ShareButton → system share sheet
  └── EditButton → re-open CardBuilderSheet
```

### Data Flow

```
Entry / AI Reflection
  │
  ▼
CardBuilderSheet
  │  content, template, style config, toggles, photo
  ▼
CardRenderService.renderCard()
  │  1. Build render config from template + user overrides
  │  2. Load photo (if available, per-template handling)
  │  3. Auto-font-size text to fill card text area
  │  4. Add overlay elements (emotion, date, tags, footer)
  │  5. Render template layers → single PNG 1080×1440
  │  6. Return String (PNG file path)
  ▼
CardPreviewScreen
  │  User confirms. Edit or Share.
  ▼
Save: NoteCard persisted to DB → Keepsake badge on entry
Share: PNG saved to camera roll → system share sheet
```

### Render Pipeline (CardRenderService)

```dart
class CardRenderService {
  /// Render a single Keepsake card — returns PNG file path
  static Future<String> renderCard({
    required CardTemplate template,
    required String content,
    String? imagePath,                // entry photo
    String? emotion,                  // emoji
    List<String>? tags,               // tag names
    DateTime? date,
    bool showMood = true,
    bool showDate = true,
    bool showTags = true,
    bool showFooter = true,
    CardRenderConfig? config,         // style overrides
  }) async { ... }

  /// Get card image — uses cached PNG, re-renders if missing (restore path)
  static Future<String> getCardImage(NoteCard card) async {
    if (card.renderedImagePath != null &&
        File(card.renderedImagePath!).existsSync()) {
      return card.renderedImagePath!;
    }
    // Re-render from stored metadata
    final template = await CardProvider.getTemplate(card.templateId);
    return renderCard(
      template: template,
      content: card.cardContent ?? '',
      imagePath: _getEntryPhoto(card),
      emotion: card.emotion,
      tags: card.displayTags,
      date: card.createdAt,
      showMood: card.showMood,
      showDate: card.showDate,
      showTags: card.showTags,
      showFooter: card.showFooter,
      config: card.templateOverrides != null
          ? CardRenderConfig.fromJson(card.templateOverrides!)
          : null,
    );
  }
}
```

### Restore Strategy (D14 — Re-render on Demand)

| Store in Backup | Don't Store |
|-----------------|-------------|
| `NoteCard` row in DB (all fields) | `renderedImagePath` — regenerated lazily via `getCardImage()` |
| Entry photo (already in backup via entry) | Rendered PNG files |
| `templateOverrides` JSON | — |

Backup impact: ~2KB/card (metadata) vs. ~2MB/card (with PNG). Deterministic rendering — same inputs produce identical output.

---

## 4. Database Migration (v15)

v14 was consumed by T-6 (voice_enabled on routines). Card migration is v15.

### Tables Changed

```sql
-- templates: add new columns
ALTER TABLE templates ADD COLUMN layout TEXT NOT NULL DEFAULT 'hero_image';
ALTER TABLE templates ADD COLUMN accent_color TEXT;
ALTER TABLE templates ADD COLUMN text_area_opacity REAL NOT NULL DEFAULT 0.85;
ALTER TABLE templates ADD COLUMN text_backdrop_color TEXT;
ALTER TABLE templates ADD COLUMN footer_text TEXT DEFAULT 'Blinking Notes';
ALTER TABLE templates ADD COLUMN show_mood INTEGER NOT NULL DEFAULT 1;
ALTER TABLE templates ADD COLUMN show_date INTEGER NOT NULL DEFAULT 1;
ALTER TABLE templates ADD COLUMN show_tags INTEGER NOT NULL DEFAULT 1;
ALTER TABLE templates ADD COLUMN show_footer INTEGER NOT NULL DEFAULT 1;
ALTER TABLE templates ADD COLUMN corner_style TEXT NOT NULL DEFAULT 'rounded';
ALTER TABLE templates ADD COLUMN decoration_style TEXT; -- bamboo, seal, landscape, porcelain, tea, ink_wash

-- note_cards: add new columns
ALTER TABLE note_cards ADD COLUMN card_content TEXT;
ALTER TABLE note_cards ADD COLUMN emotion TEXT;
ALTER TABLE note_cards ADD COLUMN display_tags TEXT; -- JSON array
ALTER TABLE note_cards ADD COLUMN show_mood INTEGER NOT NULL DEFAULT 1;
ALTER TABLE note_cards ADD COLUMN show_date INTEGER NOT NULL DEFAULT 1;
ALTER TABLE note_cards ADD COLUMN show_tags INTEGER NOT NULL DEFAULT 1;
ALTER TABLE note_cards ADD COLUMN show_footer INTEGER NOT NULL DEFAULT 1;
ALTER TABLE note_cards ADD COLUMN template_overrides TEXT; -- JSON for user style overrides
```

Columns removed from original v1.2.0 plan (deferred to v1.3.0):
- `page_count` — multi-page support deferred
- `rendered_pages` — multi-page support deferred
- `aspect_ratio` — 3:4 fixed, no toggle needed

---

## 5. Test Cases

### Unit Tests

| ID | Test | Expected |
|----|------|----------|
| UT-1 | `CardTemplate.seedDefaults()` returns 8 templates | All 8 have unique IDs, correct layout, valid hex colors, decoration style set |
| UT-2 | `CardTemplate` fromJson/toJson round-trip with new fields | All fields preserved (layout, accentColor, decorationStyle, etc.) |
| UT-3 | `renderCard()` produces PNG at 1080×1440 | File exists, dimensions correct, 3:4 aspect |
| UT-4 | `renderCard()` includes emotion emoji when showMood = true | Rendered image contains emoji text |
| UT-5 | `renderCard()` excludes emotion when showMood = false | Rendered image does not contain emoji |
| UT-6 | `renderCard()` includes tags as hashtags when showTags = true | "#tag1 #tag2" visible in rendered output |
| UT-7 | `renderCard()` excludes system tags (tag_synthesis, tag_private) | These tags not rendered even when showTags = true |
| UT-8 | `renderCard()` with photo as full-bleed background (hero_image layout) | Photo covers entire card, text readable with backdrop |
| UT-9 | `renderCard()` with photo as inline thumbnail (left_aligned layout) | Photo appears small, text visible above and below |
| UT-10 | `renderCard()` with photo as hero header (two_column layout) | Photo at top 40%, text below |
| UT-11 | `renderCard()` with no photo, text-only template (centered layout) | Clean gradient background, no image placeholder |
| UT-12 | `renderCard()` auto-font-sizes text to fill text area | Largest font that fits, never below 9px |
| UT-13 | `renderCard()` with each of 8 templates | All produce valid PNG without crash |
| UT-14 | `renderCard()` with template 墨韵 renders ink wash + cinnabar line | Ink wash gradient, cinnabar hairline above text |
| UT-15 | `renderCard()` with template 竹影 renders bamboo motif | Bamboo leaf visible in corner |
| UT-16 | `renderCard()` with template 月色 renders crescent moon | Crescent moon visible, dark gradient |
| UT-17 | `renderCard()` with template 青花 renders porcelain borders | Top + bottom borders with vine motif |
| UT-18 | `renderCard()` with template 茶语 renders steam curves | Subtle wavy lines visible |
| UT-19 | `renderCard()` with template 朱砂 renders seal stamp | Red seal visible, centered below text |
| UT-20 | `renderCard()` with template 山水 renders mountain silhouettes | 3-layer mountain shapes + mist gradient |
| UT-21 | Style overrides: user font color overrides template default | Text color matches user override from templateOverrides |
| UT-22 | Style overrides: user accent color applied | Accent elements use user override |
| UT-23 | `getCardImage()` returns cached PNG if file exists | Same path returned, no re-render |
| UT-24 | `getCardImage()` re-renders if PNG file missing | New PNG created, matches original config |
| UT-25 | `getCardImage()` re-render produces identical output to original | Same content + same template = same PNG (deterministic) |
| UT-26 | `NoteCard` fromJson/toJson round-trip with new fields | All fields preserved (cardContent, emotion, displayTags, show toggles, templateOverrides) |
| UT-27 | DB migration v15: new template columns exist after upgrade | All columns present with correct defaults |
| UT-28 | DB migration v15: new note_card columns exist after upgrade | All columns present with correct defaults |
| UT-29 | `renderCard()` handles empty content gracefully | Returns error or renders template without text, no crash |

### Widget Tests

| ID | Test | Expected |
|----|------|----------|
| WT-1 | `CardTemplatePicker` renders 8 template thumbnails | 8 items in horizontal scroll |
| WT-2 | `CardTemplatePicker` tap selects template | Selected state with border highlight |
| WT-3 | `CardTemplatePicker` shows template name below thumbnail | Name text visible (ZH or EN per locale) |
| WT-4 | `CardBuilderSheet` opens with content pre-filled | Text field contains entry/reflection text |
| WT-5 | `CardBuilderSheet` "AI Rewrite" button triggers loading state | Spinner shown, content updated on response |
| WT-6 | `CardBuilderSheet` style panel expands/collapses | Chevron rotates, content reveals/hides |
| WT-7 | `CardBuilderSheet` toggles update preview in real-time | Mood/date/tags/footer checkboxes change card output |
| WT-8 | `CardBuilderSheet` photo section shows entry photo | Photo preview visible, full-bleed/header/inline toggle works |
| WT-9 | `CardBuilderSheet` "Save Keepsake" renders and saves | PNG created, NoteCard persisted, camera roll saved |
| WT-10 | `CardPreviewScreen` shows full-screen PNG | Single page, no page strip. Image fills screen. |
| WT-11 | `CardPreviewScreen` "Share" opens share sheet | `SharePlus.instance.share()` called with PNG file |
| WT-12 | `CardPreviewScreen` "Edit" re-opens builder | `CardBuilderSheet` shown with pre-filled content + config |
| WT-13 | `EntryDetailScreen` Keepsake badge visible when card exists | Badge chip with template name shown |
| WT-14 | `EntryDetailScreen` Keepsake badge tap opens preview | `CardPreviewScreen` pushed, PNG displayed |
| WT-15 | `EntryDetailScreen` Keepsake badge hidden when no card | No badge chip visible |

### Integration Tests

| ID | Test | Expected |
|----|------|----------|
| IT-1 | Entry → Save as Keepsake → Pick template → Edit → Toggles → Save | Full flow completes without error. Badge visible on entry. |
| IT-2 | AI Reflection → Save as Keepsake → AI Rewrite → Save | Card saved to DB, badge visible on reflection |
| IT-3 | Re-render on restore | Export backup → reinstall → restore → open entry → badge visible → tap → card re-renders correctly |
| IT-4 | Edit existing keepsake | Entry with keepsake → badge → Edit → change template + content → Save → updated card in preview |
| IT-5 | Switch locale ZH → EN → create card | Template names switch language, text renders in correct locale |
| IT-6 | Card with all toggles OFF | No emoji, date, tags, or footer on rendered image |
| IT-7 | Card with all toggles ON + photo | All elements visible on rendered image |

---

## 6. UAT Test Cases

| ID | Test | Device | Steps | Expected | Result |
|----|------|--------|-------|----------|--------|
| K-1 | Create keepsake from entry | iPhone 17 Pro | EntryDetail → "Save as Keepsake" → pick 墨韵 → toggle mood ON → Save | Card renders. Badge visible on entry. | ⬜ |
| K-2 | Create keepsake from entry | iPad Air 11" | Same as K-1 | Card renders correctly on iPad. No layout issues. | ⬜ |
| K-3 | Create keepsake from AI reflection | iPhone 17 Pro | AI → Save Reflection → "Save as Keepsake" → pick 月色 → Save | Reflection text on Moonlight template. Readable. Badge visible. | ⬜ |
| K-4 | Create keepsake from Assistant saved reflection | iPhone 17 Pro | Assistant → save reflection → "Save as Keepsake" → pick 茶语 → Save | Assistant reflection on Tea Whisper template. | ⬜ |
| K-5 | All 8 templates render correctly | iPhone 17 Pro | Create keepsake with each of 8 templates | All 8 unique styles. No crashes. Visual distinct. | ⬜ |
| K-6 | Keepsake badge visible | iPhone 17 Pro | Create keepsake → return to EntryDetailScreen | Badge visible with template name. | ⬜ |
| K-7 | Keepsake badge tap → preview | iPhone 17 Pro | Tap badge → see full-screen PNG | CardPreviewScreen opens. Card renders correctly. | ⬜ |
| K-8 | Keepsake badge hidden (no card) | iPhone 17 Pro | Entry without keepsake → EntryDetailScreen | No badge visible. | ⬜ |
| K-9 | Photo as background (hero template) | iPhone 17 Pro | Entry with photo → Save as Keepsake → 墨韵 → Save | Photo covers card. Text readable with backdrop. | ⬜ |
| K-10 | Photo inline (journal template) | iPhone 17 Pro | Entry with photo → Save as Keepsake → 素笺 → Save | Photo appears as inline thumbnail. | ⬜ |
| K-11 | Emotion emoji visible | iPhone 17 Pro | Entry with 😊 → Save as Keepsake → showMood ON | 😊 visible on card. | ⬜ |
| K-12 | Emotion emoji hidden | iPhone 17 Pro | Same → toggle showMood OFF → Save | No emoji on card. | ⬜ |
| K-13 | Tags as hashtags visible | iPhone 17 Pro | Entry with #日记 #日常 → showTags ON → Save | "#日记 #日常" at bottom of card. | ⬜ |
| K-14 | System tags excluded | iPhone 17 Pro | Entry with tag_synthesis → Save as Keepsake | "synthesis" NOT on card hashtags. | ⬜ |
| K-15 | Date stamp visible | iPhone 17 Pro | showDate ON → Save | Date visible (e.g., "2026-05-23"). | ⬜ |
| K-16 | Footer visible | iPhone 17 Pro | showFooter ON → Save | "Blinking Notes" visible bottom. | ⬜ |
| K-17 | Footer hidden | iPhone 17 Pro | showFooter OFF → Save | No "Blinking Notes" on card. | ⬜ |
| K-18 | Style override: font color | iPhone 17 Pro | Builder → Style → pick red font → Save | Text color changed to red on card. | ⬜ |
| K-19 | Share keepsake from preview | iPhone 17 Pro | Badge → Preview → Share | System share sheet opens with PNG. | ⬜ |
| K-20 | Edit keepsake | iPhone 17 Pro | Badge → Preview → Edit → change template to 素笺 → Save | Card updates. Preview shows new template. | ⬜ |
| K-21 | AI Rewrite button works | iPhone 17 Pro | Builder → tap AI Rewrite → wait | Content changes. Loading spinner during call. | ⬜ |
| K-22 | Restore — keepsake survives | iPhone 17 Pro | Backup → reinstall → restore → open entry → badge visible → tap | Card re-renders correctly from stored metadata. | ⬜ |
| K-23 | Backup size (no PNG bloat) | iPhone 17 Pro | Create 5 keepsakes → backup → check ZIP size | Backup < 200KB larger than without keepsakes. | ⬜ |
| K-24 | Android keepsake creation | Android emulator | Same as K-1 | Card renders. Share sheet opens (Android). | ⬜ |
| K-25 | Chinese template names (ZH locale) | iPhone 17 Pro | Set locale to 中文 → browse templates | Names: 墨韵, 素笺, 竹影, 月色, 青花, 茶语, 朱砂, 山水 | ⬜ |
| K-26 | English template names (EN locale) | iPhone 17 Pro | Set locale to English → browse templates | Names: Ink Rhythm, Plain Paper, Bamboo Shadow, Moonlight, Blue Porcelain, Tea Whisper, Cinnabar Seal, Landscape | ⬜ |
| K-27 | Dark mode compatibility | iPhone 17 Pro | Switch to dark theme → Save as Keepsake → 月色 | Template renders consistently. | ⬜ |
