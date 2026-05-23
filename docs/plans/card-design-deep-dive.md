# Card Design Deep-Dive — Two Use Cases, Multi-Page, Content, Styling

> **Date:** May 23, 2026  
> **Refines:** `card-system-design-v1.2.0.md`  
> **Revision:** May 23 — v1.2.0 scoped to Keepsake only. XHS Export + Multi-page deferred to v1.3.0.

---

## 1. Two-Use-Case Model

Two distinct user goals with different feature needs. v1.2.0 ships Keepsake; XHS Export deferred to v1.3.0.

| | **Keepsake Card** (v1.2.0) | **XHS Export** (v1.3.0) |
|---|---|---|
| **Goal** | Preserve memory — photo + text, beautiful, personal | Share on 小红书 — readable, swipeable, platform-native |
| **Multi-page?** | Not needed. One moment, one card. | Critical. Long entries must span multiple images. |
| **Photo on card?** | Critical — combine photo with note text | Nice-to-have |
| **Aspect ratio** | 3:4 portrait (fixed) | 3:4 portrait |
| **Template variety** | One beautiful pick | Variety matters for social feed |
| **AI Rewrite** | Optional polish | Important for public sharing |
| **Where it lives** | In-app (linked to entry) + camera roll | Camera roll → RedNotes app |
| **Re-edit?** | From source entry always possible | N/A — shared once |
| **Tags as hashtags** | Decorative | Discoverability on XHS |

---

## 2. RedNotes Format Standard (v1.3.0 Reference)

### Platform Requirements

| Requirement | RedNotes Standard | Implementation (v1.3.0) |
|-------------|------------------|--------------------------|
| **Aspect ratio** | 3:4 portrait primary (1080×1440px). Also 1:1 (1080×1080px) for square posts. | Both supported. User picks per card. |
| **Multi-image posts** | 1–9 images per post. All must be same aspect ratio. | Blinking generates consistent 3:4 cards. User can create up to 9 cards, export as a batch. |
| **Image quality** | Max 20MB per image. JPEG or PNG. | PNG rendering at 1080×1440. Compress if >5MB. |
| **Text in image** | Common: quote overlay, handwriting fonts, mood colors. | Built into templates. |
| **Hashtags** | At bottom of post, below image caption. | Tags rendered as `#tag1 #tag2` at card bottom. |

### Template Resolution Options

| Option | Resolution | Aspect | RedNotes Fit | Storage per card |
|--------|-----------|--------|-------------|-----------------|
| **A — Standard** | 1080×1440 | 3:4 | ✅ Primary feed ratio | ~800KB–2MB PNG |
| **B — Square** | 1080×1080 | 1:1 | ✅ Square posts (less common on RedNotes, more on WeChat/IG) | ~600KB–1.5MB PNG |

**v1.2.0:** 3:4 fixed. **v1.3.0:** 3:4 default, 1:1 toggle.

---

## 3. Multi-Page Card Support (v1.3.0)

This section preserved for v1.3.0 XHS Export design reference. Not implemented in v1.2.0.

### Problem Statement

> A user writes a 500-word journal entry. Sharing as one card would require tiny 9px font — illegible. They need to split across 3–4 cards with consistent styling.

### Decision (D8): Hybrid Auto-Paginate (v1.3.0)

**How it works:** Default is auto-paginate. User sees preview of all pages with split points. They can adjust page breaks by tapping "Adjust" which opens manual mode. Best of both worlds.

**Effort:** ~8h. Deferred to v1.3.0.

---

## 4. Content Elements on Card

### Element Inventory

| Element | Source | Visual Placement | Always / Optional | v1.2.0 |
|---------|--------|-----------------|------------------|:---:|
| **Entry text** | `entry.content` or AI reflection text | Main body area (auto-sized) | Always | ✅ |
| **Emotion emoji** | `entry.emotion` from mood picker | Top-right badge or header accent | Optional (toggle per card) | ✅ |
| **Tags** | `entry.tagIds` → Tag names | Bottom as `#tag1 #tag2` (exclude system tags: `tag_synthesis`, `tag_private`) | Optional (toggle per card) | ✅ |
| **Photos/images** | `entry.mediaPaths` | Full-bleed background OR hero header OR inline thumbnail | Per template layout | ✅ |
| **Date** | `entry.createdAt` | Bottom-left or top-left | Optional (toggle per card) | ✅ |
| **Persona indicator** | Active persona name + emoji | Footer "— via Kael 📝" or small logo | Optional | Deferred |
| **App watermark** | "Blinking Notes" text | Bottom-center, small, semi-transparent | Optional (toggle per card) | ✅ |
| **Title** | First line of entry or user-provided | Top of card, bold, larger font | Optional (auto-extract first line or manual) | Deferred |

### Image Handling Options

Photos are the most impactful visual element for Keepsake cards.

#### Option A: Full-Bleed Background (v1.2.0 ✅)

Entry photo covers entire card. Text overlays with semi-transparent dark backdrop.

- Best for: Photo-heavy entries. Matches RedNotes aesthetic.
- Implemented on hero_image layout templates.

#### Option B: Hero Image Header (v1.2.0 ✅)

Photo at top 40%, text below on solid/gradient background.

- Best for: Entries with both photo and substantial text.
- Implemented on two_column layout templates.

#### Option C: Inline Thumbnail (v1.2.0 ✅)

Small photo embedded in text flow, like a blog post.

- Best for: Text-first entries with supporting photos.
- Implemented on left_aligned layout templates.

#### Option D: No Image (v1.2.0 ✅)

Solid color or gradient background. Clean, minimal.

- Best for: Pure reflection entries, AI-generated content.
- Default for centered layout templates.

### Image Handling Per Template (D9)

| Template Type | Layout | Image Behavior | v1.2.0 |
|---------------|--------|---------------|:---:|
| 墨韵, 竹影, 茶语, 山水 | hero_image | Full-bleed background | ✅ |
| 素笺 | left_aligned | Inline thumbnail | ✅ |
| 月色, 青花, 朱砂 | centered | No image (text-only) | ✅ |

**Per-template default behavior, overridable by user per card.**

---

## 5. Style Editability

### What Users Can Edit Per Card (v1.2.0)

| Element | Editability | Default |
|---------|------------|---------|
| **Template** | Choose from 8 built-in | 墨韵 (Ink Rhythm) |
| **Font color** | Color picker | Template default |
| **Accent color** | Color picker (for borders, tag badges) | Template default |
| **Text backdrop** | Opacity slider (0–1.0) | Template default |
| **Content** | Editable text field (pre-filled from entry) | Entry text |
| **Show mood emoji** | Toggle | ON |
| **Show date** | Toggle | ON |
| **Show tags** | Toggle | ON |
| **Show footer** | Toggle (app watermark) | ON |
| **Image handling** | Full-bleed / hero header / inline / none | Per-template default |

### Deferred (v1.3.0)

| Element | Target |
|---------|--------|
| Custom background image upload | v1.3.0 |
| Font family picker (serif/sans/handwriting) | v1.3.0 |
| Save as custom template | v1.3.0 |

---

## 6. Restore Strategy: Metadata Only (v1.2.0)

### Problem

Storing rendered PNGs in backup adds ~2MB per card. A user with 50 keepsakes adds 100MB to backup and restore.

### Solution: Re-render on Restore (D14)

Only card metadata (DB row) is exported in backup. Rendered PNGs are regenerated lazily on first view.

| Store in Backup | Don't Store |
|-----------------|-------------|
| `NoteCard` row in DB (all fields including `templateOverrides`) | `renderedImagePath` — regenerated lazily |
| Entry photo (already in backup via entry) | Rendered PNG files |

```dart
static Future<String> getCardImage(NoteCard card) {
  if (card.renderedImagePath != null && File(card.renderedImagePath).existsSync()) {
    return card.renderedImagePath; // cached
  }
  return renderCard(card: card, template: template); // re-render from stored config
}
```

**Result:** ~2KB/card vs. ~2MB/card. 50 keepsakes = ~100KB added to backup (not 100MB). Rendering is deterministic — same inputs produce identical output.

---

## 7. Entry Detail Keepsake Indicator (v1.2.0)

No separate Card History screen in v1.2.0 (D13). Instead, a minimal badge on `EntryDetailScreen`:

```
EntryDetailScreen
  ├─ Entry content (existing)
  ├─ Emotion + tags (existing)
  ├─ Photo (existing)
  └─ [If linked NoteCard exists:]
       └─ "Keepsake" badge (chip with template name)
            ├─ Tap → CardPreviewScreen (full PNG)
            └─ Share button → system share sheet
```

This is the one-to-one mapping: entry ↔ keepsake. Users know which entries have keepsakes by the badge. Camera roll already serves as the image repository — the badge provides the link back to the original entry.

**Deferred to v1.2.1:** Grid-based Card History screen for browsing all cards independent of source entries.

---

## 8. Decision Summary — LOCKED (May 23, 2026)

| D# | Decision | Resolution |
|----|----------|------------|
| **D1** | Template strategy | Replace all 6 old with 8 new (墨韵–山水) |
| **D2** | Customizability | Full per-card font/color/opacity/toggles. Save-as-template deferred to v1.3.0. |
| **D3** | Background images | Built-in gradients + entry photo. Custom uploads deferred to v1.3.0. |
| **D4** | Content editing | Pre-filled, editable + "AI Rewrite" button |
| **D5** | Multi-entry merge | **Deferred to v1.3.0** |
| **D6** | Aspect ratio | **3:4 portrait fixed** for v1.2.0. 1:1 alternative deferred to v1.3.0. |
| **D7** | Persistence | **Metadata only** — PNGs regenerated lazily (~2KB/card vs ~2MB/card) |
| **D8** | Multi-page support | **Deferred to v1.3.0** (XHS Export use case) |
| **D9** | Image handling | Per-template defaults (full-bleed hero, inline journal). User can override. |
| **D10** | Page break awareness | **Deferred to v1.3.0** |
| **D11** | Custom templates | Built-in only. Save-as-template deferred to v1.3.0. |
| **D12** | XHS Export mode | **Deferred to v1.3.0** |
| **D13** | Card History screen | **Deferred to v1.2.1** — replaced by Keepsake badge on EntryDetailScreen |
| **D14** | Re-render on restore | Metadata only in backup. PNGs generated lazily. Deterministic rendering. |

---

## 9. Effort Impact (v1.2.0 Keepsake-Only)

| Feature | Estimate |
|---------|----------|
| Core card system (renderer, builder, preview) | ~5 days |
| Template engine (4 layouts + 8 templates + 6 motifs) | ~4 days |
| UI (template picker, builder sheet, preview, entry badge) | ~4 days |
| Re-render-on-restore logic | ~0.5 day |
| Content element toggles (emoji, tags, date, footer) | ~1 day |
| Photo integration per-template (3 modes) | ~0.5 day |
| AI Rewrite button | ~1h |
| Integration tests + visual QA + bug fixes | ~3 days |
| **Total v1.2.0 Phase 3** | **~11 working days (May 29 – Jun 8)** |

### Deferred Effort (v1.2.1 / v1.3.0)

| Feature | Estimate | Target |
|---------|----------|--------|
| Card History screen (grid) | ~3h | v1.2.1 |
| Multi-page: auto-paginate with sentence-aware breaks | ~4h | v1.3.0 |
| Multi-page: manual adjustment | ~4h | v1.3.0 |
| XHS Export mode (builder flow, ratio toggle) | ~3 days | v1.3.0 |
| Custom template saving | ~2 days | v1.3.0 |
| Custom background image upload | ~2h | v1.3.0 |
