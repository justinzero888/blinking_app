import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/note_card.dart';

void main() {
  final _now = DateTime(2026, 3, 21);

  NoteCard _base({String? renderedImagePath}) => NoteCard(
        id: 'card-1',
        entryIds: ['e1', 'e2'],
        templateId: 'tmpl-A',
        folderId: 'folder-1',
        renderedImagePath: renderedImagePath,
        aiSummary: 'A good day.',
        richContent: '{"ops":[]}',
        createdAt: _now,
        updatedAt: _now,
      );

  group('NoteCard.copyWith', () {
    test('preserves all fields when called with no arguments', () {
      final card = _base(renderedImagePath: '/cache/card1.png');
      final copy = card.copyWith();

      expect(copy.id, card.id);
      expect(copy.entryIds, card.entryIds);
      expect(copy.templateId, card.templateId);
      expect(copy.folderId, card.folderId);
      expect(copy.renderedImagePath, card.renderedImagePath);
      expect(copy.aiSummary, card.aiSummary);
      expect(copy.richContent, card.richContent);
      expect(copy.createdAt, card.createdAt);
      expect(copy.updatedAt, card.updatedAt);
    });

    test('overrides individual fields without touching others', () {
      final card = _base(renderedImagePath: '/cache/card1.png');
      final copy = card.copyWith(templateId: 'tmpl-B', folderId: 'folder-2');

      expect(copy.templateId, 'tmpl-B');
      expect(copy.folderId, 'folder-2');
      // Unchanged
      expect(copy.id, card.id);
      expect(copy.renderedImagePath, card.renderedImagePath);
      expect(copy.aiSummary, card.aiSummary);
    });

    // Regression test: card background bug (v1.1.0 beta UAT)
    // After editing a card in CardBuilderDialog, the stale renderedImagePath
    // was NOT cleared, so CardTile kept showing the old cached PNG even after
    // the user picked a different template/background. Fix: clearImagePath: true.
    test('clearImagePath: true nulls renderedImagePath regardless of value passed', () {
      final card = _base(renderedImagePath: '/cache/card1.png');
      final copy = card.copyWith(
        templateId: 'tmpl-B',
        clearImagePath: true,
      );

      expect(copy.renderedImagePath, isNull,
          reason: 'stale cached PNG must be cleared on edit so the tile re-renders');
      expect(copy.templateId, 'tmpl-B');
    });

    test('clearImagePath: false (default) preserves existing renderedImagePath', () {
      final card = _base(renderedImagePath: '/cache/card1.png');
      final copy = card.copyWith(templateId: 'tmpl-C');

      expect(copy.renderedImagePath, '/cache/card1.png');
    });

    test('clearImagePath: true on a card with null renderedImagePath keeps it null', () {
      final card = _base(); // renderedImagePath is null
      final copy = card.copyWith(clearImagePath: true);

      expect(copy.renderedImagePath, isNull);
    });

    test('passing renderedImagePath and clearImagePath: true — clearImagePath wins', () {
      final card = _base(renderedImagePath: '/cache/old.png');
      final copy = card.copyWith(
        renderedImagePath: '/cache/new.png',
        clearImagePath: true,
      );

      // clearImagePath takes precedence per model implementation
      expect(copy.renderedImagePath, isNull);
    });
  });

  group('NoteCard serialization round-trip', () {
    test('toJson / fromJson preserves all fields', () {
      final card = _base(renderedImagePath: '/cache/card1.png');
      final json = card.toJson();
      final restored = NoteCard.fromJson(json);

      expect(restored.id, card.id);
      expect(restored.entryIds, card.entryIds);
      expect(restored.templateId, card.templateId);
      expect(restored.folderId, card.folderId);
      expect(restored.renderedImagePath, card.renderedImagePath);
      expect(restored.aiSummary, card.aiSummary);
      expect(restored.richContent, card.richContent);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'card-2',
        'entry_ids': <String>[],
        'template_id': 'tmpl-A',
        'folder_id': 'folder-1',
        'rendered_image_path': null,
        'ai_summary': null,
        'rich_content': null,
        'created_at': _now.toIso8601String(),
        'updated_at': _now.toIso8601String(),
      };
      final card = NoteCard.fromJson(json);

      expect(card.renderedImagePath, isNull);
      expect(card.aiSummary, isNull);
      expect(card.richContent, isNull);
    });
  });
}
