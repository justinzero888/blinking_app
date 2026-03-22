import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/card_template.dart';

void main() {
  final _now = DateTime(2026, 3, 21);

  CardTemplate _base() => CardTemplate(
        id: 'tmpl-1',
        name: 'Warm Sunset',
        icon: '🌅',
        fontFamily: 'serif',
        fontColor: '#FFFFFF',
        bgColor: '#FF6B35',
        isBuiltIn: true,
        customImagePath: '/images/sunset.jpg',
        createdAt: _now,
      );

  group('CardTemplate.copyWith', () {
    test('preserves all fields when called with no arguments', () {
      final tmpl = _base();
      final copy = tmpl.copyWith();

      expect(copy.id, tmpl.id);
      expect(copy.name, tmpl.name);
      expect(copy.icon, tmpl.icon);
      expect(copy.fontFamily, tmpl.fontFamily);
      expect(copy.fontColor, tmpl.fontColor);
      expect(copy.bgColor, tmpl.bgColor);
      expect(copy.isBuiltIn, tmpl.isBuiltIn);
      expect(copy.customImagePath, tmpl.customImagePath);
      expect(copy.createdAt, tmpl.createdAt);
    });

    test('overrides bgColor without affecting other fields', () {
      final tmpl = _base();
      final copy = tmpl.copyWith(bgColor: '#1A1A2E');

      expect(copy.bgColor, '#1A1A2E');
      expect(copy.fontColor, tmpl.fontColor);
      expect(copy.customImagePath, tmpl.customImagePath);
      expect(copy.isBuiltIn, tmpl.isBuiltIn);
    });

    test('overrides customImagePath without affecting other fields', () {
      final tmpl = _base();
      final copy = tmpl.copyWith(customImagePath: '/images/new_bg.jpg');

      expect(copy.customImagePath, '/images/new_bg.jpg');
      expect(copy.bgColor, tmpl.bgColor);
      expect(copy.name, tmpl.name);
    });

    // Regression: built-in templates must never be mutated; copyBuiltInTemplate
    // sets isBuiltIn: false before allowing edits.
    test('isBuiltIn flag can be cleared when copying a built-in template', () {
      final builtIn = _base(); // isBuiltIn = true
      final copy = builtIn.copyWith(id: 'tmpl-1-copy', isBuiltIn: false);

      expect(copy.isBuiltIn, isFalse);
      expect(builtIn.isBuiltIn, isTrue, reason: 'original must not be mutated');
    });

    test('changing id creates a distinct template identity', () {
      final tmpl = _base();
      final copy = tmpl.copyWith(id: 'tmpl-2');

      expect(copy.id, 'tmpl-2');
      expect(tmpl.id, 'tmpl-1', reason: 'original must not be mutated');
    });
  });

  group('CardTemplate serialization round-trip', () {
    test('toJson / fromJson preserves all fields', () {
      final tmpl = _base();
      final json = tmpl.toJson();
      final restored = CardTemplate.fromJson(json);

      expect(restored.id, tmpl.id);
      expect(restored.name, tmpl.name);
      expect(restored.icon, tmpl.icon);
      expect(restored.fontFamily, tmpl.fontFamily);
      expect(restored.fontColor, tmpl.fontColor);
      expect(restored.bgColor, tmpl.bgColor);
      expect(restored.isBuiltIn, tmpl.isBuiltIn);
      expect(restored.customImagePath, tmpl.customImagePath);
    });

    test('fromJson handles null optional fields with defaults', () {
      final json = {
        'id': 'tmpl-2',
        'name': 'Minimal',
        'icon': '📝',
        'font_color': '#222222',
        'bg_color': '#FFFFFF',
        'is_built_in': 0,
        'custom_image_path': null,
        'created_at': _now.toIso8601String(),
      };
      final tmpl = CardTemplate.fromJson(json);

      expect(tmpl.fontFamily, 'default');
      expect(tmpl.customImagePath, isNull);
      expect(tmpl.isBuiltIn, isFalse);
    });
  });
}
