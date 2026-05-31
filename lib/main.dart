import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
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

  if (kDebugMode || kProfileMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  await DeviceService.getDeviceId();

  final storageService = StorageService();
  await storageService.init();

  final prefs = await SharedPreferences.getInstance();

  // Reset previous trial state on fresh install
  final wasPreview = prefs.getBool('entitlement_was_preview');
  if (wasPreview == null) {
    await prefs.remove('trial_token');
    await prefs.remove('trial_started_at');
    await prefs.remove('trial_device_id');
  }

  if (kReleaseMode && _rcApiKey.isEmpty) {
    throw Exception(
      'FATAL: RC_API_KEY must be defined for release builds.\n'
      'Build with: flutter build ipa --dart-define=RC_API_KEY=appl_...\n'
      'Or use: RC_API_KEY=appl_... bash scripts/build_ios.sh',
    );
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

