# Design: Backup Progress Indicator + Date Range Selection

**Date:** 2026-04-22
**Context:** Full backup (ZIP) takes 20-30s for ~1.7GB and will grow linearly over time. Users see no feedback and risk closing the app. Date-range selection prevents the backup from growing unmanageable long-term.

---

## User Flow

Tapping "Full Backup (ZIP)" in Settings opens a two-phase dialog.

### Phase 1 — Date Range Selection

Non-fullscreen `AlertDialog` with:
- Title: "选择备份范围 / Select Backup Range"
- Five `ChoiceChip` options (single-select, default = All):
  - All data
  - Last month (startDate = now - 30 days)
  - Last 3 months (startDate = now - 90 days)
  - Last 6 months (startDate = now - 180 days)
  - Custom (reveals two `TextButton`-triggered date pickers: From / To)
- "Start Backup" `ElevatedButton` → transitions to Phase 2
- "Cancel" `TextButton` → closes dialog

### Phase 2 — Progress (same dialog, content replaced)

Dialog becomes `barrierDismissible: false`. Content:
- `LinearProgressIndicator(value: _progress)` (0.0 → 1.0)
- `"45%"` percentage text
- Time estimate text:
  - `< 15%` progress: "Calculating... / 正在计算..."
  - `≥ 15%`: rounded bucket — "Less than 10 seconds", "About 30 seconds", "About 1 minute", "About N minutes"
- Warning: "请勿关闭应用 / Do not close the app"

On completion: dialog auto-closes, share sheet opens.
On error: dialog closes, error snackbar shown.

---

## Technical Design

### `ExportService.exportAll()` changes

Add optional callback parameter:
```dart
Future<String> exportAll({
  DateTime? startDate,
  DateTime? endDate,
  void Function(double progress)? onProgress,
})
```

Before streaming files:
1. Collect all media `File` entities into a list
2. Sum their sizes → `totalBytes`
3. Stream each file; after each `addFile`, accumulate `bytesProcessed` and call `onProgress(bytesProcessed / totalBytes)`

Non-media items (data.json, manifest.json, persona.json, avatar) are small — count them as 0 bytes for progress purposes (negligible vs. media).

If `totalBytes == 0` (no media), call `onProgress(1.0)` immediately after JSON files are added.

### `_handleBackup()` in `settings_screen.dart`

Replaced with a stateful approach using a local `StatefulWidget` dialog or `setState`-driven `showDialog` with a `StatefulBuilder`:

```
_BackupDialogState:
  _phase: enum { rangeSelect, inProgress }
  _rangeChoice: enum { all, lastMonth, last3Months, last6Months, custom }
  _customFrom: DateTime?
  _customTo: DateTime?
  _progress: double (0.0–1.0)
  _estimateText: String
  _startTime: DateTime?
  _bytesSamples: List<(double progress, Duration elapsed)> (last 5, for rolling avg)
```

Time estimation logic (called on each `onProgress`):
- If `progress < 0.15`: show "Calculating..."
- Else: compute `bytesPerSecRolling` from last 5 samples → `remainingSec = (1.0 - progress) * totalBytes / bytesPerSecRolling` → round to bucket

### Date range → startDate/endDate mapping

| Choice | startDate | endDate |
|--------|-----------|---------|
| All | null | null |
| Last month | now - 30d | null |
| Last 3 months | now - 90d | null |
| Last 6 months | now - 180d | null |
| Custom | `_customFrom` | `_customTo` |

---

## Error Handling

- If backup fails mid-stream: dialog closes, error snackbar. Partial ZIP file is left on disk (acceptable — subsequent backup overwrites with a new timestamp).
- If `totalBytes` calculation fails: fall back to indeterminate `LinearProgressIndicator(value: null)` with no time estimate.

---

## Testing

- `exportAll()` calls `onProgress` with monotonically increasing values from 0.0 to 1.0
- `onProgress(1.0)` is called exactly once at completion
- With no media files, `onProgress(1.0)` is called after JSON is written
- UI: progress dialog appears on backup start, closes on completion
