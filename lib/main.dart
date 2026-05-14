import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/device_service.dart';
import 'core/services/purchases_service.dart';
import 'core/services/config_service.dart';
import 'core/services/notification_service.dart';

const _rcApiKey = String.fromEnvironment('RC_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceService.getDeviceId();

  final storageService = StorageService();
  await storageService.init();

  // Reset previous trial state on fresh install
  final prefs = await SharedPreferences.getInstance();
  final wasPreview = prefs.getBool('entitlement_was_preview');
  if (wasPreview == null) {
    // First launch — clean any stale state
    await prefs.remove('trial_token');
    await prefs.remove('trial_started_at');
    await prefs.remove('trial_device_id');
  }

  final purchasesService = PurchasesService();
  await purchasesService.init(
    unifiedKey: _rcApiKey.isNotEmpty
        ? _rcApiKey
        : kDebugMode
            ? 'test_FFZAekOZQXGwwReuLkrvQLTjyOP'
            : null,
  );

  ConfigService.fetch();
  await NotificationService.init();

  runApp(BlinkingApp(
    storageService: storageService,
    purchasesService: purchasesService,
  ));
}
