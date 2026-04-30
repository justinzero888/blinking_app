import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/models/note_card.dart';
import 'package:blinking/models/card_template.dart';

/// Fake StorageService — overrides only the methods CardProvider calls.
/// Does NOT call init() so no platform channels are needed.
class _FakeStorage extends StorageService {
  @override
  Future<void> deleteNoteCard(String id) async {}

  @override
  Future<void> updateNoteCard(NoteCard card) async {}

  @override
  Future<void> deleteCardFolder(String id) async {}

  @override
  Future<void> deleteTemplate(String id) async {}

  @override
  Future<void> updateTemplate(CardTemplate template) async {}
}

NoteCard _card({String id = 'c1', String folderId = 'folder', String? imagePath}) => NoteCard(
      id: id,
      entryIds: const [],
      templateId: 'tmpl',
      folderId: folderId,
      renderedImagePath: imagePath,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

CardTemplate _template({
  String id = 't1',
  String? customImagePath,
  bool isBuiltIn = false,
}) =>
    CardTemplate(
      id: id,
      name: 'Test',
      icon: '🎨',
      fontColor: '#222222',
      bgColor: '#FFFFFF',
      isBuiltIn: isBuiltIn,
      customImagePath: customImagePath,
      createdAt: DateTime(2026),
    );

/// Fake PathProviderPlatform for tests that need deterministic doc dir paths.
class MockPathProvider extends PathProviderPlatform {
  final String _docDir;
  MockPathProvider(this._docDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => _docDir;

  @override
  Future<String?> getApplicationCachePath() async => _docDir;

  @override
  Future<String?> getApplicationSupportPath() async => _docDir;

  @override
  Future<String?> getTemporaryPath() async => _docDir;

  @override
  Future<String?> getExternalStoragePath() async => _docDir;

  @override
  Future<List<String>?> getExternalCachePaths() async => [_docDir];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => [_docDir];

  @override
  Future<String?> getDownloadsPath() async => _docDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardProvider — PNG cleanup', () {
    late Directory tempDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('card_cleanup_test_');
      PathProviderPlatform.instance = MockPathProvider(tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    // ===== existing tests =====

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
      provider.seedForTest([_card()]);

      await expectLater(provider.deleteCard('c1'), completes);
    });

    // ===== G1: deleteFolder =====

    test('deleteFolder deletes PNGs for all cards in folder', () async {
      final png1 = File('${tempDir.path}/card1.png')..writeAsBytesSync([0, 1]);
      final png2 = File('${tempDir.path}/card2.png')..writeAsBytesSync([0, 1]);
      expect(png1.existsSync(), isTrue);
      expect(png2.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([
        _card(id: 'c1', folderId: 'folderA', imagePath: png1.path),
        _card(id: 'c2', folderId: 'folderA', imagePath: png2.path),
      ]);

      await provider.deleteFolder('folderA');

      expect(png1.existsSync(), isFalse,
          reason: 'deleteFolder must delete rendered PNGs for cards in the folder');
      expect(png2.existsSync(), isFalse,
          reason: 'deleteFolder must delete rendered PNGs for cards in the folder');
      expect(provider.cards.length, 0,
          reason: 'deleteFolder must remove folder cards from _cards');
    });

    test('deleteFolder does not affect cards in other folders', () async {
      final pngA = File('${tempDir.path}/cardA.png')..writeAsBytesSync([0, 1]);
      final pngB = File('${tempDir.path}/cardB.png')..writeAsBytesSync([0, 1]);

      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([
        _card(id: 'c1', folderId: 'folderA', imagePath: pngA.path),
        _card(id: 'c2', folderId: 'folderB', imagePath: pngB.path),
      ]);

      await provider.deleteFolder('folderA');

      expect(pngA.existsSync(), isFalse);
      expect(pngB.existsSync(), isTrue,
          reason: 'deleteFolder must not delete PNGs of cards in other folders');
      expect(provider.cards.length, 1);
      expect(provider.cards.first.id, 'c2');
    });

    // ===== G2: deleteCard deterministic path fallback =====

    test('deleteCard deletes deterministic PNG when renderedImagePath is null', () async {
      final cardsDir = Directory('${tempDir.path}/cards')..createSync(recursive: true);
      final deterministicPng = File('${cardsDir.path}/c1.png')..writeAsBytesSync([0, 1]);
      expect(deterministicPng.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card(id: 'c1')]);

      await provider.deleteCard('c1');

      expect(deterministicPng.existsSync(), isFalse,
          reason: 'deleteCard must clean up deterministic PNG even when renderedImagePath is null');
    });

    // ===== G3: deleteTemplate customImagePath =====

    test('deleteTemplate deletes customImagePath file', () async {
      final imgFile = File('${tempDir.path}/template_bg.jpg')..writeAsBytesSync([0, 1]);
      expect(imgFile.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template(customImagePath: imgFile.path)]);

      await provider.deleteTemplate('t1');

      expect(imgFile.existsSync(), isFalse,
          reason: 'deleteTemplate must delete the customImagePath file');
      expect(provider.templates.length, 0);
    });

    test('deleteTemplate with null customImagePath does not throw', () async {
      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template()]);

      await expectLater(provider.deleteTemplate('t1'), completes);
    });

    test('deleteTemplate respects built-in protection', () async {
      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template(isBuiltIn: true)]);

      await provider.deleteTemplate('t1');

      expect(provider.templates.length, 1,
          reason: 'deleteTemplate must not delete built-in templates');
    });

    // ===== G4: updateTemplate customImagePath =====

    test('updateTemplate deletes old customImagePath when image changes', () async {
      final oldImg = File('${tempDir.path}/old_bg.jpg')..writeAsBytesSync([0, 1]);
      final newImg = '${tempDir.path}/new_bg.jpg';
      expect(oldImg.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template(customImagePath: oldImg.path)]);

      await provider.updateTemplate(_template(customImagePath: newImg));

      expect(oldImg.existsSync(), isFalse,
          reason: 'updateTemplate must delete old customImagePath when image changes');
      expect(provider.templates.first.customImagePath, newImg);
    });

    test('updateTemplate deletes old customImagePath when image cleared', () async {
      final oldImg = File('${tempDir.path}/old_bg.jpg')..writeAsBytesSync([0, 1]);
      expect(oldImg.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template(customImagePath: oldImg.path)]);

      final cleared = _template().copyWith(clearCustomImage: true);
      await provider.updateTemplate(cleared);

      expect(oldImg.existsSync(), isFalse,
          reason: 'updateTemplate must delete old customImagePath when image is cleared');
      expect(provider.templates.first.customImagePath, isNull);
    });

    test('updateTemplate does NOT delete customImagePath when unchanged', () async {
      final img = File('${tempDir.path}/bg.jpg')..writeAsBytesSync([0, 1]);
      expect(img.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template(customImagePath: img.path)]);

      await provider.updateTemplate(_template(customImagePath: img.path));

      expect(img.existsSync(), isTrue,
          reason: 'updateTemplate must not delete customImagePath when unchanged');
    });

    test('updateTemplate does not change/delete built-in templates', () async {
      final provider = CardProvider(_FakeStorage());
      provider.seedTemplatesForTest([_template(isBuiltIn: true)]);

      await provider.updateTemplate(_template(isBuiltIn: true, customImagePath: '/new.jpg'));

      expect(provider.templates.first.customImagePath, isNull,
          reason: 'updateTemplate must not modify built-in templates');
    });
  });
}
