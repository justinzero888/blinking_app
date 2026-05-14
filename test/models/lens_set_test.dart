import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/lens_set.dart';

void main() {
  group('LensSet', () {
    test('creates LensSet from defaults with correct lenses list', () {
      final sets = DefaultLensSets.defaults(true);
      expect(sets.length, 4);

      final zengzi = sets.firstWhere((s) => s.id == 'lens_builtin_zengzi');
      expect(zengzi.label, '曾子三省');
      expect(zengzi.lenses.length, 3);
      expect(zengzi.lenses[0], '为人谋而不忠乎？');
      expect(zengzi.isBuiltin, true);
    });

    test('Zengzi sort order is 1 in zh, 2 in en', () {
      final zhSets = DefaultLensSets.defaults(true);
      final enSets = DefaultLensSets.defaults(false);

      final zhZengzi = zhSets.firstWhere((s) => s.id == 'lens_builtin_zengzi');
      final enZengzi = enSets.firstWhere((s) => s.id == 'lens_builtin_zengzi');
      expect(zhZengzi.sortOrder, 1);
      expect(enZengzi.sortOrder, 2);
    });

    test('toJson and fromJson round-trip', () {
      final set = LensSet(
        id: 'test_id',
        label: 'Test',
        lens1: 'Lens 1',
        lens2: 'Lens 2',
        lens3: 'Lens 3',
        isBuiltin: false,
        sortOrder: 5,
        createdAt: DateTime(2026, 5, 8),
      );
      final json = set.toJson();
      final restored = LensSet.fromJson(json);
      expect(restored.id, set.id);
      expect(restored.label, set.label);
      expect(restored.lenses, set.lenses);
      expect(restored.isBuiltin, set.isBuiltin);
      expect(restored.sortOrder, set.sortOrder);
    });
  });
}
