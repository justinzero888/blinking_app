import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

const _autoRestorePath = String.fromEnvironment('AUTO_RESTORE');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceService.getDeviceId();

  final storageService = StorageService();
  await storageService.init();

  // Debug: auto-restore from backup path if provided
  if (_autoRestorePath.isNotEmpty) {
    final file = File(_autoRestorePath);
    if (await file.exists()) {
      // Reset entitlement + onboarding state so restored data shows fresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('entitlement_state');
      await prefs.remove('entitlement_jwt');
      await prefs.remove('entitlement_quota');
      await prefs.remove('entitlement_quota_date');
      await prefs.remove('entitlement_preview_days');
      await prefs.remove('entitlement_preview_started');
      await prefs.remove('entitlement_was_preview');
      await prefs.remove('onboarding_completed');
      // Clear old trial data too
      await prefs.remove('trial_token');
      await prefs.remove('trial_started_at');
      await prefs.remove('trial_device_id');
      await storageService.restoreFromBackup(file);
    }
  }

  final purchasesService = PurchasesService();
  await purchasesService.init(unifiedKey: _rcTestApiKey);

  runApp(BlinkingApp(
    storageService: storageService,
    purchasesService: purchasesService,
  ));
}
