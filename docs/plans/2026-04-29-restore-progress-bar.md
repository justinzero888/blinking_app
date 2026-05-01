# Add Progress Bar to Restore — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a progress bar, percentage display, time estimate, and "Do not close the app" warning to the Restore flow, matching the UX of the Backup feature.

**Architecture:** 
- Modify `StorageService.restoreFromBackup()` to accept an optional `onProgress` callback parameter and invoke it as files are extracted from the ZIP.
- Update `_handleRestore()` in `SettingsScreen` to use a `StatefulBuilder` with two phases: phase 0 (file picker) and phase 1 (progress dialog). The progress dialog displays a `LinearProgressIndicator`, percentage, time estimate (reusing `_BackupEstimator`), and a non-dismissible UI.
- The progress callback reports normalized progress (0.0 to 1.0) based on the number of files processed in the archive.

**Tech Stack:** 
- Flutter (`StatefulBuilder`, `LinearProgressIndicator`, `PopScope`)
- Dart `archive` package (already in use for ZIP extraction)
- Existing `_BackupEstimator` class for time estimation

---

## Task 1: Update `StorageService.restoreFromBackup()` signature and add progress tracking

**Files:**
- Modify: `lib/core/services/storage_service.dart:521–583`
- Test: `test/core/storage_service_test.dart` (verify progress callback is invoked correctly)

**Step 1: Add the `onProgress` callback parameter**

Read the current function signature and modify it to include the callback:

```dart
Future<void> restoreFromBackup(
  File backupFile, {
  void Function(double progress)? onProgress,
}) async {
```

**Step 2: Count files in the archive**

After creating the `Archive` object from the ZIP, calculate the total number of files that will be processed:

```dart
final inputStream = InputFileStream(backupFile.path);
Archive? archive;
try {
  archive = ZipDecoder().decodeStream(inputStream);
  
  // Count media and avatar files for progress tracking
  int totalFiles = 0;
  for (final file in archive) {
    if (file.isFile && (file.name.startsWith('media/') || file.name.startsWith('avatar/'))) {
      totalFiles++;
    }
  }
  int processedFiles = 0;
```

**Step 3: Update progress callback in the media/avatar extraction loop**

Modify the existing loop that extracts media and avatar files to call `onProgress` after each file:

```dart
for (final file in archive) {
  if (file.isFile && (file.name.startsWith('media/') || file.name.startsWith('avatar/'))) {
    final targetPath = path_pkg.join(docDir.path, file.name);
    final targetDir = Directory(path_pkg.dirname(targetPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final output = OutputFileStream(targetPath);
    try {
      file.writeContent(output);
    } finally {
      await output.close();
    }
    
    // Report progress
    processedFiles++;
    if (totalFiles > 0) {
      onProgress?.call(processedFiles / totalFiles);
    }
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/core/storage_service_test.dart --verbose`

Verify that existing tests still pass.

**Step 5: Commit**

```bash
git add lib/core/services/storage_service.dart
git commit -m "feat(restore): add onProgress callback to restoreFromBackup"
```

---

## Task 2: Update `_handleRestore()` in SettingsScreen to show progress dialog

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart:1171–1208`
- Test: Manual UI testing (will verify in Task 3)

**Step 1: Refactor `_handleRestore()` to use StatefulBuilder with two phases**

Replace the simple `CircularProgressIndicator` dialog with a `StatefulBuilder` similar to the backup flow:

```dart
Future<void> _handleRestore(BuildContext context, bool isZh) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      
      // State for the restore dialog
      var phase = 0;
      var progress = 0.0;
      var estimateText = '';
      final estimator = _BackupEstimator();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (_, setDialogState) {
            if (phase == 0) {
              // Phase 0: Confirmation dialog
              return AlertDialog(
                title: Text(isZh ? '恢复数据' : 'Restore Data'),
                content: Text(
                  isZh 
                    ? '确定要恢复此备份吗？这将替换您的所有数据。'
                    : 'Restore data from this backup? This will replace all your current data.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(isZh ? '取消' : 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setDialogState(() => phase = 1);
                      // Start restore with progress tracking
                      _performRestore(
                        file,
                        context,
                        dialogContext,
                        isZh,
                        setDialogState,
                        (p) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              progress = p;
                              estimateText = estimator.estimate(p, isZh);
                            });
                          }
                        },
                      );
                    },
                    child: Text(isZh ? '恢复' : 'Restore'),
                  ),
                ],
              );
            }

            // Phase 1: Progress dialog
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text(isZh ? '正在恢复...' : 'Restoring...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (estimateText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        estimateText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
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
  } catch (e) {
    if (mounted) Navigator.pop(context);
    _showError(context, isZh, e.toString());
  }
}
```

**Step 2: Add the `_performRestore()` helper method**

This method handles the actual restore operation and calls the progress callback:

```dart
Future<void> _performRestore(
  File file,
  BuildContext context,
  BuildContext dialogContext,
  bool isZh,
  StateSetter setDialogState,
  void Function(double progress)? onProgress,
) async {
  try {
    final storage = context.read<StorageService>();
    await storage.restoreFromBackup(
      file,
      onProgress: onProgress,
    );

    if (!dialogContext.mounted) return;
    Navigator.pop(dialogContext); // Close progress dialog

    // Reload all providers
    if (context.mounted) {
      context.read<EntryProvider>().loadEntries();
      context.read<RoutineProvider>().loadRoutines();
      context.read<TagProvider>().loadTags();
      await context.read<AiPersonaProvider>().reload();
    }

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh ? '数据恢复成功！' : 'Data restored successfully!'),
        ),
      );
    }
  } catch (e) {
    if (dialogContext.mounted) Navigator.pop(dialogContext);
    if (context.mounted) _showError(context, isZh, e.toString());
  }
}
```

**Step 3: Run Flutter analyze**

Run: `flutter analyze --no-pub`

Expected: 0 errors

**Step 4: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat(restore): add progress dialog with percentage and time estimate"
```

---

## Task 3: Manual UI testing and verification

**Test Plan:**

1. **Setup:** Have a test backup file ready (ZIP with some media files)

2. **Test the restore flow:**
   - Open Settings → Data Portability → Restore
   - Select the test backup file
   - Verify a confirmation dialog appears
   - Tap "Restore"
   - Verify the progress dialog shows:
     - A `LinearProgressIndicator` that updates
     - A percentage number (0–100%)
     - A time estimate (after ~15% progress)
     - A warning message "Do not close the app"
     - No dismiss button or way to close the dialog
   - Verify the dialog closes when restore completes
   - Verify a success snackbar appears
   - Verify the app's data was actually restored (check Moments feed for entries)

3. **Edge cases:**
   - Test with a small JSON-only backup (no media files)
   - Test with a large ZIP backup (many media files)
   - Verify the progress callback is called multiple times during extract

**Commands for local testing:**

```bash
# Build and run the app on a device/emulator
flutter run

# Or for iOS:
flutter run -d <device-id>

# Or for Android:
flutter run -d <device-id>
```

**Step 1: Create a test backup file**

Use the app's Backup feature (Settings → Data Portability → Backup) to create a test backup with some entries that have media files.

**Step 2: Test the basic restore flow**

1. Open Settings → Data Portability → Restore
2. Select the test backup file
3. Tap "Restore"
4. Observe the progress dialog updates smoothly
5. Verify the snackbar shows success

**Step 3: Verify data integrity**

1. Open Moments tab
2. Verify entries from the backup are present
3. Open Keepsakes tab
4. Verify cards and notes are present

**Step 4: Commit**

```bash
git add .
git commit -m "test(restore): manual UI verification of progress bar"
```

---

## Task 4: Write unit tests for progress callback

**Files:**
- Modify: `test/core/storage_service_test.dart` (add new test cases)

**Step 1: Write a test that verifies the progress callback is invoked**

```dart
test('restoreFromBackup invokes onProgress callback during ZIP extraction', () async {
  // Create a mock ZIP file with some media files
  // (or use a fixture file if available)
  
  final progressValues = <double>[];
  
  await storageService.restoreFromBackup(
    testZipFile,
    onProgress: (progress) {
      progressValues.add(progress);
    },
  );
  
  // Verify callback was called at least once
  expect(progressValues, isNotEmpty);
  
  // Verify progress values are monotonically increasing
  for (int i = 1; i < progressValues.length; i++) {
    expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
  }
  
  // Verify final progress is 1.0 (or close to it)
  expect(progressValues.last, greaterThanOrEqualTo(0.9));
});
```

**Step 2: Write a test for JSON-only restore (no progress)**

```dart
test('restoreFromBackup handles JSON files without progress callback', () async {
  final progressValues = <double>[];
  
  // JSON restore should not call onProgress (no files to extract)
  await storageService.restoreFromBackup(
    testJsonFile,
    onProgress: (progress) {
      progressValues.add(progress);
    },
  );
  
  // Verify onProgress was not called for JSON
  expect(progressValues, isEmpty);
});
```

**Step 3: Run the tests**

Run: `flutter test test/core/storage_service_test.dart --verbose`

Expected: All tests pass

**Step 4: Commit**

```bash
git add test/core/storage_service_test.dart
git commit -m "test(restore): add unit tests for progress callback"
```

---

## Task 5: Integration test (optional but recommended)

**Files:**
- Create: `test/integration/restore_progress_test.dart` (if integration tests exist)

**Step 1: Write an integration test**

```dart
testWidgets('Restore flow shows progress bar and completes successfully',
  (WidgetTester tester) async {
  
  // Build the app
  await tester.pumpWidget(const MyApp());
  
  // Navigate to Settings → Data Portability
  // (Use your app's navigation pattern)
  
  // Tap Restore button
  // (Simulate file picker with a test backup)
  
  // Verify progress dialog appears
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
  
  // Pump until restore completes
  await tester.pumpUntilFound(
    find.text('Data restored successfully!'),
    timeout: const Duration(seconds: 30),
  );
  
  // Verify success message
  expect(find.byType(SnackBar), findsOneWidget);
});
```

**Step 2: Run the integration test**

Run: `flutter test integration_test/restore_progress_test.dart` (if integration tests are set up)

**Step 3: Commit**

```bash
git add test/integration/restore_progress_test.dart
git commit -m "test(restore): add integration test for progress flow"
```

---

## Summary

| Task | Effort | Complexity |
|------|--------|------------|
| 1. Add progress callback to StorageService | 30 min | Medium |
| 2. Refactor _handleRestore with StatefulBuilder | 45 min | Medium |
| 3. Manual UI testing | 20 min | Low |
| 4. Unit tests | 20 min | Low |
| 5. Integration test (optional) | 15 min | Low |

**Total estimated effort:** 2–3 hours (including testing and commits)

**Key reuse:** The `_BackupEstimator` class is used as-is — no new time estimation code needed.

**Risk:** Low — the change is isolated to the restore flow and follows the exact pattern of the backup flow (already tested and in production).
