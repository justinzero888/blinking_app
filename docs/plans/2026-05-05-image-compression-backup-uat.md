# UAT — Image Compression & Backup Integrity
**Version:** v1.1.0-beta.7+22 (with compression patch)
**Date:** 2026-05-05
**Scope:** Option A (image compression) + Option B (media-exclude toggle) + Persona backup fix

---

## Setup Before Testing

1. Ensure the app has existing data: at least 5 entries with photos, a custom AI persona (name + personality text), and a custom AI avatar.
2. If starting fresh: create 3+ entries with photos taken from camera, set AI persona in Settings → AI section, set an avatar image.
3. Note the current backup size (if a prior backup exists at ~1.6 GB).

---

## Section A — Image Compression at Pick Time

### A-1: Gallery image pick compresses
| # | Step | Expected |
|---|------|----------|
| A-1.1 | Open a new entry, tap image picker, select a photo from gallery | Photo appears in entry normally |
| A-1.2 | Save entry. Check the photo quality visually | Photo looks crisp, no visible pixelation at normal zoom |
| A-1.3 | Create backup. Check file size versus old ~1.6 GB | Backup is significantly smaller (expect ~50–100 MB with photos, < 200 KB text-only) |

### A-2: Camera photo compresses
| # | Step | Expected |
|---|------|----------|
| A-2.1 | Open a new entry, tap camera, take a photo | Photo appears in entry normally |
| A-2.2 | Save entry. View the photo in entry detail | Photo looks crisp, no visible degradation |
| A-2.3 | Create backup. Compare with previous backup size | Size is similar to A-1 (compressed) |

### A-3: AI avatar compresses
| # | Step | Expected |
|---|------|----------|
| A-3.1 | Settings → AI 个性化 → tap avatar, select a large photo (e.g., 12MP) | Avatar saves and displays normally |
| A-3.2 | Check avatar on floating robot and assistant screen | Avatar renders without artifacts |
| A-3.3 | Create backup. Verify avatar/ file is in ZIP with reasonable size | Avatar file in ZIP is small (typically < 50 KB at 512px) |

### A-4: Routine icon compresses
| # | Step | Expected |
|---|------|----------|
| A-4.1 | Edit a routine → tap icon → select photo from gallery | Icon saves and displays |
| A-4.2 | Icon renders in routine list without distortion | Visible, clear |

---

## Section B — Backup Dialog: "Include photos" Toggle

### B-1: Toggle defaults to OFF (text-only)
| # | Step | Expected |
|---|------|----------|
| B-1.1 | Settings → Full Backup (ZIP) | Dialog opens with "Include photos" switch OFF |
| B-1.2 | Start Backup (any range, toggle OFF) | Progress bar appears briefly, completes quickly |
| B-1.3 | Share the ZIP. Check the file size | File is < 500 KB (text-only, no photos) |
| B-1.4 | Unzip the backup on a computer. Verify files | ZIP contains: data.json, manifest.json, persona.json, avatar/ file. NO media/ folder. |

### B-2: Toggle ON (with media)
| # | Step | Expected |
|---|------|----------|
| B-2.1 | Settings → Full Backup (ZIP) | Dialog opens. Toggle ON "Include photos" |
| B-2.2 | Start Backup (all data, toggle ON) | Progress bar shows progress, completes |
| B-2.3 | Share ZIP. Check file size | Much smaller than old ~1.6 GB (expect ~50–100 MB) |
| B-2.4 | Unzip backup. Verify contents | ZIP contains: data.json, manifest.json, persona.json, avatar/ file, AND media/ folder with compressed images |

### B-3: Date range + media toggle
| # | Step | Expected |
|---|------|----------|
| B-3.1 | Create backup: "Last Month", toggle ON | Only last month's entries + their media are included |
| B-3.2 | Create backup: "Custom" with specific dates, toggle OFF | Only text data for that range, < 500 KB |
| B-3.3 | Create backup: "All Data", toggle OFF | All entries as text, no media, < 500 KB |

---

## Section C — Persona Backup & Restore (Bug Fix)

### C-1: Persona survives backup → restore
| # | Step | Expected |
|---|------|----------|
| C-1.1 | Set custom AI name (e.g., "测试小悟") and personality text in Settings → AI 个性化 | Settings saves without error |
| C-1.2 | Set a custom AI avatar image | Avatar appears on FloatingRobot and in Settings |
| C-1.3 | Create full backup (all data, toggle ON) | Backup completes successfully |
| C-1.4 | Settings → Restore Data → select the backup just created | Confirm replace dialog appears |
| C-1.5 | Confirm restore | Progress shows, "Data restored successfully!" snackbar |
| C-1.6 | Go to Settings → AI 个性化 section | Custom name "测试小悟" is still set |
| C-1.7 | Check personality text | Personality text is intact |
| C-1.8 | Check FloatingRobot avatar | Custom avatar is displayed (not default 🤖) |
| C-1.9 | Open AI Assistant screen | Assistant greets with custom name and personality |

### C-2: Persona survives text-only backup → restore
| # | Step | Expected |
|---|------|----------|
| C-2.1 | Set different AI name (e.g., "Buddy") | Settings save |
| C-2.2 | Create text-only backup (toggle OFF) | Backup completes quickly |
| C-2.3 | Restore from this text-only backup | Success snackbar shown |
| C-2.4 | Verify AI name is "Buddy" | Name restored correctly |
| C-2.5 | Verify avatar is intact | Avatar displays normally |

### C-3: Persona preserved with excludeMedia
| # | Step | Expected |
|---|------|----------|
| C-3.1 | Create backup with toggle OFF (text-only) | Persona.json and avatar ARE in the ZIP (verified in C-2) |
| C-3.2 | Extract ZIP on computer, check persona.json exists | persona.json present with name, personality, avatar_zip_path |
| C-3.3 | Check avatar/ folder exists | avatar/ folder contains the avatar image |

---

## Section D — Backup with Existing Large Images (compression during export)

### D-1: Existing uncompressed images are compressed in backup
| # | Step | Expected |
|---|------|----------|
| D-1.1 | If you have the old 1.6 GB backup, restore it first | Old entries with full-res photos are in the app |
| D-1.2 | Create a new backup (all data, toggle ON) | Backup is significantly smaller than 1.6 GB |
| D-1.3 | Extract backup. Check media/ images | Images have reasonable sizes (typically 100–800 KB each, not 10–20 MB) |
| D-1.4 | Restore from this backup. View photos in entries | Photos display clearly, acceptable quality |

### D-2: Photo quality after compression
| # | Step | Expected |
|---|------|----------|
| D-2.1 | View a photo attached to an entry (from the compressed backup) | Photo looks clear at screen size |
| D-2.2 | Pinch-to-zoom on the photo | Photo remains legible up to ~2x zoom (text in photos should still be readable) |
| D-2.3 | Compare with original photo in gallery | Minor quality difference at extreme zoom, indistinguishable at normal viewing |

---

## Section E — Edge Cases & Regression

### E-1: Backup with no persona set
| # | Step | Expected |
|---|------|----------|
| E-1.1 | Reset AI persona to defaults (clear avatar if set) | Default name "AI 助手", no avatar |
| E-1.2 | Create backup (any range) | Backup completes normally |
| E-1.3 | Extract backup. Check for persona.json | No persona.json or it's absent (only written when persona is configured) |
| E-1.4 | Restore this backup | No crash, no error. Default persona remains |

### E-2: Backup with missing avatar file (pref set, file deleted)
| # | Step | Expected |
|---|------|----------|
| E-2.1 | Set AI avatar, then manually delete the file from device storage | This is hard to test — simulate by verifying no crash on backup |
| E-2.2 | Create backup | Backup completes. ZIP contains persona.json with name/personality but NO ai_avatar_zip_path |
| E-2.3 | Restore backup | No crash. Name and personality restored, avatar not restored (file was missing) |

### E-3: CSV export unaffected
| # | Step | Expected |
|---|------|----------|
| E-3.1 | Settings → Export CSV | CSV exports normally |
| E-3.2 | Check CSV contents | Entries and routines are present in CSV format |

### E-4: JSON export unaffected
| # | Step | Expected |
|---|------|----------|
| E-4.1 | Settings → Export JSON | JSON exports normally |
| E-4.2 | Check JSON contents | Full data structure present |

### E-5: Habit import/export unaffected
| # | Step | Expected |
|---|------|----------|
| E-5.1 | Export habits | Habits export JSON downloads |
| E-5.2 | Import habits from file | Habits import successfully |

### E-6: No crash on large backup
| # | Step | Expected |
|---|------|----------|
| E-6.1 | Create backup with many entries (50+) and photos (30+) | App does not crash. Progress bar updates smoothly |
| E-6.2 | "Do not close the app" warning is visible | Warning text shown during backup |
| E-6.3 | Backup completes and share sheet opens | Share sheet appears with the ZIP |

### E-7: Restore from old backup (backward compatibility)
| # | Step | Expected |
|---|------|----------|
| E-7.1 | Use an old backup (pre-compression, ~1.6 GB) | Restore dialog appears |
| E-7.2 | Restore the old backup | Data restores successfully. Entries, tags, routines are intact |
| E-7.3 | Check persona data | If old backup had persona.json, persona is restored |

---

## Sign-off Checklist

| Section | Tester | Result | Notes |
|---------|--------|--------|-------|
| A-1 Gallery pick compresses | | ⬜ Pass / ⬜ Fail | |
| A-2 Camera compresses | | ⬜ Pass / ⬜ Fail | |
| A-3 AI avatar compresses | | ⬜ Pass / ⬜ Fail | |
| A-4 Routine icon compresses | | ⬜ Pass / ⬜ Fail | |
| B-1 Text-only backup (OFF) | | ⬜ Pass / ⬜ Fail | |
| B-2 Full backup (ON) with media | | ⬜ Pass / ⬜ Fail | |
| B-3 Date range + toggle combos | | ⬜ Pass / ⬜ Fail | |
| C-1 Persona survives round-trip | | ⬜ Pass / ⬜ Fail | |
| C-2 Persona survives text-only | | ⬜ Pass / ⬜ Fail | |
| C-3 Persona in excludeMedia backup | | ⬜ Pass / ⬜ Fail | |
| D-1 Old images compressed in backup | | ⬜ Pass / ⬜ Fail | |
| D-2 Photo quality acceptable | | ⬜ Pass / ⬜ Fail | |
| E-1 No persona = no crash | | ⬜ Pass / ⬜ Fail | |
| E-2 Missing avatar = graceful | | ⬜ Pass / ⬜ Fail | |
| E-3 CSV export unaffected | | ⬜ Pass / ⬜ Fail | |
| E-4 JSON export unaffected | | ⬜ Pass / ⬜ Fail | |
| E-5 Habit export/import unaffected | | ⬜ Pass / ⬜ Fail | |
| E-6 No crash on large backup | | ⬜ Pass / ⬜ Fail | |
| E-7 Old backup restore works | | ⬜ Pass / ⬜ Fail | |
