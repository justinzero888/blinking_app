# T-1: Restore Streaming Refactor — Design Document

> **Phase:** 2 | **Effort:** ~2h | **File:** `lib/core/services/storage_service.dart`

---

## Current State Analysis

### Code flow (lines 649–733)

```
1. ZipDecoder().decodeStream(inputStream)  → Archive (lazy entries, metadata loaded)
2. archive.findFile('data.json').content   → decompresses FULL data.json into RAM
3. utf8.decode(bytes)                      → String copy in RAM
4. json.decode(string)                     → Map/List objects in RAM (peak)
5. importData(map)                         → inserts into SQLite row-by-row
6. Iterate archive, writeContent(output)   → streaming to disk per file ✅
7. Persona restore from persona.json
```

### Memory analysis

| Step | What's in RAM | Size |
|------|--------------|------|
| 1 | Archive metadata (~200 bytes/entry) | 1000 files = ~200KB |
| 2 | Decompressed data.json bytes | Up to backup size |
| 3 | UTF-8 string | Equal to step 2 |
| 4 | Parsed Map/List + all model objects | ~2x step 2 |
| **Peak** | Steps 2 + 3 + 4 coexist | **~4x data.json size** |

### Key finding: `ZipDecoder().decodeStream()` is NOT the culprit

The archive package uses lazy `InputStream` references for entry data. Entry content is only decompressed on first access. The `writeContent()` calls at line 695 already stream correctly.

**The real bottleneck is `data.json`:** all entries + routines + tags serialized as one JSON blob, decompressed, decoded to string, then parsed to objects — all held simultaneously.

---

## Design

### Goal

Peak RAM during restore: `backup_size` → `max(data.json_size, largest_media_file)`

### Strategy: Three-phase processing with explicit memory release

```
Phase A: Decode + Import data.json (with memory cleanup)
Phase B: Stream media files to disk (with event-loop yields)
Phase C: Restore persona settings
```

### Detailed changes

#### 1. Phase A: Import data.json with immediate cleanup

```dart
// Import data.json
final dataFile = archive.findFile('data.json');
if (dataFile != null) {
  // Step 1: decompress bytes
  final dataBytes = dataFile.content as List<int>;
  
  // Step 2: decode in one fused operation (avoids intermediate String copy)
  final data = json.fuse(utf8).decode(dataBytes) as Map<String, dynamic>;
  
  // Step 3: import into DB
  await importData(data);
  
  // Step 4: IMMEDIATE cleanup — null references so GC can collect
  // before we start processing potentially large media files
  archive.clearFile(name: 'data.json');  // or: remove from archive
  // data and dataBytes go out of scope after this block
}
```

**Key change:** `json.fuse(utf8).decode()` — fuses UTF-8 decode + JSON parse into a single step, avoiding the intermediate String allocation. Saves ~1x `data.json` in RAM.

**Post-import cleanup:** Remove `data.json` entry from archive before proceeding to media.

#### 2. Phase B: Stream media with GC yields

```dart
// Pre-scan: count total bytes for byte-weighted progress
int totalBytes = 0;
for (final file in archive) {
  if (file.isFile && (file.name.startsWith('media/') || file.name.startsWith('avatar/'))) {
    totalBytes += file.uncompressedSize;
  }
}

int processedBytes = 0;
int fileCount = 0;
for (final file in archive) {
  if (file.isFile && (file.name.startsWith('media/') || file.name.startsWith('avatar/'))) {
    // ... write file to disk (existing streaming code) ...
    
    processedBytes += file.uncompressedSize;
    fileCount++;
    
    // Progress by bytes (more accurate for mixed-size files)
    if (totalBytes > 0) {
      onProgress?.call(processedBytes / totalBytes);
    }
    
    // Yield to event loop every 10 files to prevent UI freeze and allow GC
    if (fileCount % 10 == 0) {
      await Future(() {});
    }
  }
}
```

**Key changes:**
- **Byte-weighted progress** instead of file-count progress. A 50MB video and a 50KB thumbnail now contribute proportional weight.
- **Event-loop yield every 10 files** (`await Future(() {})`). Gives the Flutter event loop a chance to run GC and process pending UI frames. This is the same pattern used for the iPad backup fix.

#### 3. Minor: Persona restore uses fused decode

```dart
final personaFile = archive.findFile('persona.json');
if (personaFile != null) {
  final personaMap = json.fuse(utf8).decode(personaFile.content as List<int>) as Map<String, dynamic>;
  // ... restore prefs ...
}
```

---

## Behavior Changes (User-Visible)

| Before | After |
|--------|-------|
| Progress: "Processing file 5 of 200" | Progress: "45% complete" (byte-weighted) |
| Memory spike at data.json parse | Single-copy parse, immediately cleaned |
| UI freeze during large media restore | Yields to event loop every 10 files |
| Progress dialog briefly unresponsive | Progress updates smoothly |

---

## Test Cases

### Unit Tests (`test/core/storage_service_restore_test.dart`)

| ID | Test | Expected |
|----|------|----------|
| UT-1 | Restore text-only backup (~200KB, no media) | All data intact. No memory spike. |
| UT-2 | Restore backup with 10 media files (1MB each) | All media files restored to correct paths. Progress reports 10 increments. |
| UT-3 | Restore backup with 100 media files (varying sizes) | Progress is byte-weighted (50MB file = larger progress jump than 50KB file). |
| UT-4 | Restore with corrupt persona.json | Data imported, persona skipped, no crash. |
| UT-5 | Restore with missing data.json | Throws clear error, does not crash. |
| UT-6 | Progress callback invoked at least once | `onProgress` called with values 0.0 to 1.0. |
| UT-7 | Post-restore: data.json entry removed from archive | After importData, archive no longer contains 'data.json'. |
| UT-8 | Memory: large backup (500MB+ of total data) | Peak process memory < 100MB (test with memory profiler). |

### Integration Tests

| ID | Test | Expected |
|----|------|----------|
| IT-1 | Restore real 50MB backup (text + 20 photos) | App does not crash. Data intact. |
| IT-2 | Restore 100MB backup | App responsive during restore. Cancel works. |
| IT-3 | Consecutive restores (restore A, then restore B) | No data leak between restores. |

---

## UAT Cases

| ID | Test | Device | Steps | Expected |
|----|------|--------|-------|----------|
| UAT-1 | Restore text-only backup | iPhone 17 Pro | Export → uninstall → reinstall → restore | All entries, routines, tags restored. No crash. |
| UAT-2 | Restore with media | iPhone 17 Pro | Same as UAT-1 with photos | Photos visible in entries. File paths correct. |
| UAT-3 | Restore + progress bar | iPhone 17 Pro | Restore 50MB backup, watch progress | Progress bar moves smoothly (no jumps to 100%). Approximate time estimate reasonable. |
| UAT-4 | Restore on iPad | iPad Air 11" | Restore 100MB+ backup | No black screen. Progress visible. |
| UAT-5 | Restore cancel mid-way | iPhone 17 Pro | Start restore, dismiss dialog at 30% | App clean. No partial data corruption. |
| UAT-6 | Restore old backup (v1.0 format) | iPhone 17 Pro | Restore backup from v1.0.0 era | Backward compat works. Data imported. |
| UAT-7 | Restore + immediate use | iPhone 17 Pro | Restore, immediately navigate to Calendar | Calendar shows restored data. No crash. |
| UAT-8 | Restore corrupted ZIP | iPhone 17 Pro | Hand-edit ZIP to corrupt it, attempt restore | Clear error message. App not in broken state. |

---

## Implementation Steps (in order)

| Step | What | Time |
|------|------|------|
| 1 | Add `importDataStreaming()` or modify existing `restoreFromBackup` to use `json.fuse(utf8).decode` | 30min |
| 2 | Add post-import cleanup (null references + remove data.json from archive) | 15min |
| 3 | Add byte-weighted progress counter | 15min |
| 4 | Add event-loop yields every 10 media files | 10min |
| 5 | Apply same `json.fuse(utf8).decode` to persona.json path | 5min |
| 6 | Update existing tests for new progress behavior | 20min |
| 7 | Add new unit tests (UT-1 through UT-8) | 30min |
| 8 | Run full test suite, fix failures | 15min |
