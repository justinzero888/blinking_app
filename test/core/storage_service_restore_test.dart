import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:blinking/core/services/storage_service.dart';

class MockPathProvider extends PathProviderPlatform {
  final String tempDir;

  MockPathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;

  @override
  Future<String?> getApplicationCachePath() async => tempDir;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir;

  @override
  Future<String?> getExternalStoragePath() async => tempDir;

  @override
  Future<List<String>?> getExternalCachePaths() async => [tempDir];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => [tempDir];

  @override
  Future<String?> getDownloadsPath() async => tempDir;
}

class _FakeStorageService extends StorageService {
  @override
  Future<void> init() async {
    // Skip actual initialization for testing
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService.restoreFromBackup — onProgress', () {
    late Directory tempDir;
    late Directory appDocDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('restore_progress_test_');
      appDocDir = Directory('${tempDir.path}/app_docs');
      appDocDir.createSync(recursive: true);

      // Mock the PathProvider to return our temp directory
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('restoreFromBackup handles JSON files without progress callback', () async {
      // Create a test JSON backup file
      final jsonData = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });

      final jsonPath = '${tempDir.path}/test_backup.json';
      File(jsonPath).writeAsStringSync(jsonData);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(jsonPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // JSON restore should not call onProgress
      expect(progressValues, isEmpty);
    });

    test('restoreFromBackup invokes onProgress callback during ZIP extraction', () async {
      // Create a test ZIP file with media files
      final archive = Archive();

      // Add data.json
      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // Add 3 media files to simulate extraction progress
      for (int i = 0; i < 3; i++) {
        final fileContent = List<int>.filled(1024, i);
        archive.addFile(ArchiveFile(
          'media/test_file_$i.jpg',
          fileContent.length,
          fileContent,
        ));
      }

      // Create ZIP file
      final zipPath = '${tempDir.path}/test_backup.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
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

      // Verify final progress is 1.0 (all 3 files processed)
      expect(progressValues.last, 1.0);
    });

    test('restoreFromBackup with no media files does not call progress callback', () async {
      // Create a ZIP file with only data.json and no media files
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final zipPath = '${tempDir.path}/test_backup_no_media.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // With no media files to extract, totalFiles = 0, so progress not called
      expect(progressValues, isEmpty);
    });

    test('restoreFromBackup only tracks media and avatar files for progress', () async {
      // Create a ZIP with data.json, media files, and other files
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // Add manifest.json (should not count toward progress)
      final manifest = jsonEncode({'version': 1});
      archive.addFile(ArchiveFile('manifest.json', manifest.length, utf8.encode(manifest)));

      // Add 2 media files (should count)
      for (int i = 0; i < 2; i++) {
        final fileContent = List<int>.filled(1024, i);
        archive.addFile(ArchiveFile(
          'media/file_$i.jpg',
          fileContent.length,
          fileContent,
        ));
      }

      // Add 1 avatar file (should count)
      final avatarContent = List<int>.filled(2048, 99);
      archive.addFile(ArchiveFile(
        'avatar/custom_avatar.png',
        avatarContent.length,
        avatarContent,
      ));

      final zipPath = '${tempDir.path}/test_mixed.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Should have 3 progress updates (2 media + 1 avatar)
      expect(progressValues.length, 3);

      // Progress should be: 1/3, 2/3, 1.0
      expect(progressValues[0], closeTo(1.0 / 3.0, 0.01));
      expect(progressValues[1], closeTo(2.0 / 3.0, 0.01));
      expect(progressValues[2], 1.0);
    });

    test('restoreFromBackup without onProgress callback does not crash', () async {
      // Create a simple test ZIP file with media
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final fileContent = List<int>.filled(1024, 1);
      archive.addFile(ArchiveFile(
        'media/test_file.jpg',
        fileContent.length,
        fileContent,
      ));

      final zipPath = '${tempDir.path}/test_no_callback.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      // Call without onProgress callback — should not crash
      expect(
        () => storageService.restoreFromBackup(File(zipPath)),
        returnsNormally,
      );
    });
  });
}
