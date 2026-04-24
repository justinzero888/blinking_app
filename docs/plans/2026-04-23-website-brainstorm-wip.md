# Website Brainstorm — WIP (paused 2026-04-24)

> Status: Paused mid-design. Resume from Section 2 (Landing Page Layout).

## Decisions Made

- **Platform:** Astro + GitHub Pages
- **Domain:** `blinking.app` (or `blinkingapp.com` as fallback)
- **Audience:** Bilingual — equal weight Chinese and English, language toggle in nav
- **Scope:** Landing page + blog/news

## Site Structure (approved)

```
blinkingapp.com/
├── /                    # Landing page (bilingual toggle)
├── /en/blog/            # English blog / news
├── /zh/blog/            # Chinese blog / news
├── /privacy             # Privacy policy (already written)
└── /terms               # Terms of service (already written)
```

**Language switching:** Toggle in nav bar switches EN/ZH. Landing page hero, features, CTAs all swap. Blog posts written per-language (separate `.md` files in `/en/` and `/zh/`).

**Hosting:** GitHub Pages → custom domain, HTTPS via Cloudflare. Free.

## Still To Design

- Section 2: Landing page layout (hero, features, screenshots, CTA)
- Section 3: Blog structure and post format
- Section 4: Domain registration steps
- Implementation plan (Astro scaffold, i18n config, deployment)
