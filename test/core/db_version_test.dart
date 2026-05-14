import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/services/database_service.dart';

void main() {
  test('DatabaseService targets schema version 13', () {
    expect(DatabaseService.kSchemaVersion, 13);
  });
}
