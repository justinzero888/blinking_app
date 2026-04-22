import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService.exportAll — onProgress', () {
    late Directory tempDir;

    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

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
      final mediaDir = Directory('${tempDir.path}/media')..createSync();
      for (var i = 0; i < 3; i++) {
        File('${mediaDir.path}/photo_$i.jpg')
            .writeAsBytesSync(List.filled(1024, i));
      }

      final service = ExportService(_FakeStorage());
      final progressValues = <double>[];

      await service.exportAll(
        onProgress: progressValues.add,
        docDirOverride: tempDir.path,
      );

      for (var i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
      }
      expect(progressValues.last, 1.0);
    });
  });
}
