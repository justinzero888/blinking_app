import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/device_service.dart';
import 'core/services/purchases_service.dart';

// RevenueCat Test Store API key — use for development/testing.
// Replace with platform-specific keys (appl_ / goog_) for production.
const _rcTestApiKey = String.fromEnvironment(
  'RC_API_KEY',
  defaultValue: 'test_FFZAekOZQXGwwReuLkrvQLTjyOP',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceService.getDeviceId();

  final storageService = StorageService();
  await storageService.init();

  final purchasesService = PurchasesService();
  await purchasesService.init(unifiedKey: _rcTestApiKey);

  runApp(BlinkingApp(
    storageService: storageService,
    purchasesService: purchasesService,
  ));
}
