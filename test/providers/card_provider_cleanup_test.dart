import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/models/note_card.dart';

/// Fake StorageService — overrides only the methods CardProvider calls.
/// Does NOT call init() so no platform channels are needed.
class _FakeStorage extends StorageService {
  @override
  Future<void> deleteNoteCard(String id) async {}

  @override
  Future<void> updateNoteCard(NoteCard card) async {}
}

NoteCard _card({String id = 'c1', String? imagePath}) => NoteCard(
      id: id,
      entryIds: const [],
      templateId: 'tmpl',
      folderId: 'folder',
      renderedImagePath: imagePath,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('CardProvider — PNG cleanup', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('card_cleanup_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('deleteCard deletes the rendered PNG from disk', () async {
      final pngFile = File('${tempDir.path}/card.png')..writeAsBytesSync([0, 1]);
      expect(pngFile.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card(imagePath: pngFile.path)]);

      await provider.deleteCard('c1');

      expect(pngFile.existsSync(), isFalse,
          reason: 'deleteCard must delete the PNG file from disk');
    });

    test('updateCard deletes old PNG when renderedImagePath changes', () async {
      final oldPng = File('${tempDir.path}/old.png')..writeAsBytesSync([0, 1]);
      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card(imagePath: oldPng.path)]);

      final updatedCard = _card(imagePath: '${tempDir.path}/new.png');
      await provider.updateCard(updatedCard);

      expect(oldPng.existsSync(), isFalse,
          reason: 'updateCard must delete old PNG when path changes');
    });

    test('updateCard does NOT delete PNG when path is unchanged', () async {
      final png = File('${tempDir.path}/same.png')..writeAsBytesSync([0, 1]);
      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card(imagePath: png.path)]);

      await provider.updateCard(_card(imagePath: png.path));

      expect(png.existsSync(), isTrue,
          reason: 'updateCard must not delete PNG when path is unchanged');
    });

    test('deleteCard with null renderedImagePath does not throw', () async {
      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card()]); // no image path

      await expectLater(provider.deleteCard('c1'), completes);
    });
  });
}
