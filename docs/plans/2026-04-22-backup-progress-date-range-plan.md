# Backup Progress Indicator + Date Range Selection — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the silent full-backup operation with a two-phase dialog — date range selection first, then a live progress bar with time estimate and "do not close" warning.

**Architecture:** Two independent changes: (1) `ExportService.exportAll()` gains an `onProgress` callback by pre-scanning media file sizes and reporting bytes-processed ratio after each file; (2) `_handleBackup()` in `settings_screen.dart` becomes a `StatefulBuilder` dialog with phase 1 (range chips + Start button) and phase 2 (non-dismissible progress + estimate + warning). A small `_BackupEstimator` class owns the rolling-average time estimation logic.

**Tech Stack:** Flutter/Dart, archive (ZipFileEncoder), dart:io, flutter_test

---

## Task 1: Add `onProgress` callback to `ExportService.exportAll()`

**Files:**
- Modify: `lib/core/services/export_service.dart`
- Test: `test/core/export_service_progress_test.dart`

**Step 1: Write the failing test**

Create `test/core/export_service_progress_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/services/export_service.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/models/entry.dart';
import 'package:blinking/models/tag.dart';
import 'package:blinking/models/routine.dart';

class _FakeStorage extends StorageService {
  @override Future<List<Entry>> getEntries() async => [];
  @override Future<List<Tag>> getTags() async => [];
  @override Future<List<Routine>> getRoutines() async => [];
}

void main() {
  group('ExportService.exportAll — onProgress', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('export_progress_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('onProgress called with 1.0 when no media files', () async {
      final service = ExportService(_FakeStorage());
      final progressValues = <double>[];

      await service.exportAll(
        onProgress: progressValues.add,
        docDirOverride: tempDir.path,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
    });

    test('onProgress values are monotonically increasing and end at 1.0', () async {
      // Create fake media files
      final mediaDir = Directory('${tempDir.path}/media')..createSync();
      for (var i = 0; i < 3; i++) {
        File('${mediaDir.path}/photo_$i.jpg')
            .writeAsBytesSync(List.filled(1024, i)); // 1KB each
      }

      final service = ExportService(_FakeStorage());
      final progressValues = <double>[];

      await service.exportAll(
        onProgress: progressValues.add,
        docDirOverride: tempDir.path,
      );

      // Monotonically increasing
      for (var i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
      }
      expect(progressValues.last, 1.0);
    });
  });
}
```

**Step 2: Run to verify it fails**

```bash
flutter test test/core/export_service_progress_test.dart
```
Expected: FAIL — `onProgress` and `docDirOverride` parameters not found.

**Step 3: Implement in `lib/core/services/export_service.dart`**

a) Change the `exportAll` signature:
```dart
Future<String> exportAll({
  DateTime? startDate,
  DateTime? endDate,
  void Function(double progress)? onProgress,
  String? docDirOverride, // test-only: override documents directory path
}) async {
```

b) Replace the documents directory line:
```dart
// BEFORE:
final docDir = await getApplicationDocumentsDirectory();

// AFTER:
final docDir = docDirOverride != null
    ? Directory(docDirOverride)
    : await getApplicationDocumentsDirectory();
```

c) Replace the media streaming section (step 4 in the method) with this pre-scan + progress version:

```dart
// 4. Add media files — pre-scan sizes, stream one at a time, report progress
final mediaDir = Directory(path_pkg.join(docDir.path, 'media'));
if (await mediaDir.exists()) {
  final entities = await mediaDir.list(recursive: true).toList();
  final mediaFiles = entities.whereType<File>().toList();

  // Pre-scan total bytes for progress estimation
  int totalBytes = 0;
  for (final f in mediaFiles) {
    totalBytes += await f.length();
  }

  int bytesProcessed = 0;
  for (final file in mediaFiles) {
    final fileSize = await file.length();
    final relativePath = path_pkg.relative(file.path, from: docDir.path);
    await zipEncoder.addFile(file, relativePath);
    bytesProcessed += fileSize;
    if (totalBytes > 0) {
      onProgress?.call(bytesProcessed / totalBytes);
    }
  }
}

// Signal 100% completion (covers no-media case too)
onProgress?.call(1.0);

await zipEncoder.close();
return filePath;
```

> Note: Remove the old `await zipEncoder.close(); return filePath;` at the end — it is now inside the new block above. Ensure only one `close()` call exists.

**Step 4: Run tests**

```bash
flutter test test/core/export_service_progress_test.dart
```
Expected: 2 tests PASS.

**Step 5: Run full suite**

```bash
flutter test
```
Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/core/services/export_service.dart test/core/export_service_progress_test.dart
git commit -m "feat(export): add onProgress callback and docDirOverride to exportAll"
```

---

## Task 2: Two-phase backup dialog in `settings_screen.dart`

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

This task is all UI — no new files needed. The changes are self-contained in `_handleBackup`.

**Step 1: Add `_BackupEstimator` class**

Add this private class at the bottom of `settings_screen.dart` (after the closing `}` of `_SettingsScreenState`, before end of file):

```dart
/// Estimates remaining backup time using a rolling average of the last 5 progress samples.
class _BackupEstimator {
  final _start = DateTime.now();
  final _samples = <({double progress, int elapsed})>[]; // elapsed in ms

  /// Returns a human-friendly estimate string. Returns empty string until 15% complete.
  String estimate(double progress, bool isZh) {
    final elapsedMs = DateTime.now().difference(_start).inMilliseconds;
    _samples.add((progress: progress, elapsed: elapsedMs));
    if (_samples.length > 5) _samples.removeAt(0);

    if (progress < 0.15 || _samples.length < 2) return '';

    final oldest = _samples.first;
    final newest = _samples.last;
    final progressDelta = newest.progress - oldest.progress;
    final timeDelta = newest.elapsed - oldest.elapsed;
    if (progressDelta <= 0 || timeDelta <= 0) return '';

    final msPerProgress = timeDelta / progressDelta;
    final remainingMs = msPerProgress * (1.0 - progress);
    final remainingSec = (remainingMs / 1000).round();

    if (remainingSec < 10) {
      return isZh ? '不到10秒' : 'Less than 10 seconds';
    } else if (remainingSec < 60) {
      final rounded = ((remainingSec / 10).round() * 10).clamp(10, 50);
      return isZh ? '约${rounded}秒' : 'About $rounded seconds';
    } else {
      final mins = (remainingSec / 60).ceil();
      return isZh ? '约${mins}分钟' : 'About $mins minute${mins > 1 ? 's' : ''}';
    }
  }
}
```

**Step 2: Add `_BackupRange` enum**

Add this enum at the top of the file, outside the class, after the imports:

```dart
enum _BackupRange { all, lastMonth, last3Months, last6Months, custom }
```

**Step 3: Replace `_handleBackup` with the two-phase dialog**

Replace the existing `_handleBackup` method with:

```dart
Future<void> _handleBackup(BuildContext context, bool isZh) async {
  var phase = 0; // 0 = range select, 1 = in progress
  var range = _BackupRange.all;
  DateTime? customFrom;
  DateTime? customTo;
  var progress = 0.0;
  var estimateText = '';
  final estimator = _BackupEstimator();

  // Resolve date range from choice
  (DateTime?, DateTime?) resolveRange() {
    final now = DateTime.now();
    switch (range) {
      case _BackupRange.lastMonth:
        return (now.subtract(const Duration(days: 30)), null);
      case _BackupRange.last3Months:
        return (now.subtract(const Duration(days: 90)), null);
      case _BackupRange.last6Months:
        return (now.subtract(const Duration(days: 180)), null);
      case _BackupRange.custom:
        return (customFrom, customTo);
      case _BackupRange.all:
        return (null, null);
    }
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setDialogState) {
        if (phase == 0) {
          // ── Phase 1: range selection ──
          return AlertDialog(
            title: Text(isZh ? '选择备份范围' : 'Select Backup Range'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _BackupRange.values)
                        if (r != _BackupRange.custom)
                          ChoiceChip(
                            label: Text(_rangeLabel(r, isZh)),
                            selected: range == r,
                            onSelected: (_) => setDialogState(() => range = r),
                          ),
                      ChoiceChip(
                        label: Text(isZh ? '自定义' : 'Custom'),
                        selected: range == _BackupRange.custom,
                        onSelected: (_) => setDialogState(() => range = _BackupRange.custom),
                      ),
                    ],
                  ),
                  if (range == _BackupRange.custom) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(customFrom != null
                                ? '${customFrom!.year}-${customFrom!.month.toString().padLeft(2, '0')}-${customFrom!.day.toString().padLeft(2, '0')}'
                                : (isZh ? '开始日期' : 'From')),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: customFrom ?? DateTime.now().subtract(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setDialogState(() => customFrom = picked);
                            },
                          ),
                        ),
                        const Text('→'),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(customTo != null
                                ? '${customTo!.year}-${customTo!.month.toString().padLeft(2, '0')}-${customTo!.day.toString().padLeft(2, '0')}'
                                : (isZh ? '结束日期' : 'To')),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: customTo ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setDialogState(() => customTo = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(isZh ? '取消' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setDialogState(() => phase = 1);
                  final exportService = context.read<ExportService>();
                  try {
                    final (startDate, endDate) = resolveRange();
                    final path = await exportService.exportAll(
                      startDate: startDate,
                      endDate: endDate,
                      onProgress: (p) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            progress = p;
                            estimateText = estimator.estimate(p, isZh);
                          });
                        }
                      },
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await exportService.shareFile(
                      path,
                      subject: isZh ? 'Blinking 全量备份' : 'Blinking Full Backup',
                      text: isZh ? '这是我的 Blinking App 备份文件。' : 'This is my Blinking App backup file.',
                    );
                  } catch (e) {
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) _showError(context, isZh, e.toString());
                  }
                },
                child: Text(isZh ? '开始备份' : 'Start Backup'),
              ),
            ],
          );
        }

        // ── Phase 2: progress ──
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(isZh ? '正在备份...' : 'Backing up...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress > 0 ? progress : null),
                const SizedBox(height: 12),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (estimateText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(estimateText, style: const TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      isZh ? '请勿关闭应用' : 'Do not close the app',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

String _rangeLabel(_BackupRange r, bool isZh) {
  switch (r) {
    case _BackupRange.all:
      return isZh ? '全部数据' : 'All data';
    case _BackupRange.lastMonth:
      return isZh ? '最近1个月' : 'Last month';
    case _BackupRange.last3Months:
      return isZh ? '最近3个月' : 'Last 3 months';
    case _BackupRange.last6Months:
      return isZh ? '最近6个月' : 'Last 6 months';
    case _BackupRange.custom:
      return isZh ? '自定义' : 'Custom';
  }
}
```

**Step 4: Run analyze to check for issues**

```bash
flutter analyze lib/screens/settings/settings_screen.dart --no-pub
```
Expected: 0 errors. Fix any issues before proceeding.

**Step 5: Run full test suite**

```bash
flutter test
```
Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat(backup): two-phase dialog with date range selection and progress indicator"
```

---

## Task 3: Build debug APK and manual regression

**Step 1: Build debug APK**

```bash
flutter build apk --debug
```
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

**Step 2: Manual regression checklist**

Install and test on device:

- [ ] Settings → Full Backup (ZIP) → dialog opens with range chips
- [ ] "All data" chip selected by default
- [ ] "Last month", "Last 3 months", "Last 6 months" chips selectable
- [ ] "Custom" chip shows date pickers (From / To)
- [ ] Cancel closes dialog without starting backup
- [ ] Start Backup → dialog transitions to phase 2 (progress bar appears)
- [ ] Back button does NOT dismiss the progress dialog
- [ ] Progress bar fills left to right
- [ ] Percentage text updates (e.g. 0% → 45% → 100%)
- [ ] "Calculating..." shown until ~15% progress
- [ ] Time estimate appears after 15% (e.g. "About 30 seconds")
- [ ] "Do not close the app" warning visible with orange icon
- [ ] Dialog closes automatically on completion
- [ ] Share sheet opens with the backup file
- [ ] Backup with "Last month" completes faster than "All data"
- [ ] Backup with "Custom" range respects the selected dates (verify entry count in restored JSON)
- [ ] Backup with no media: progress jumps to 100% immediately, dialog closes fast
