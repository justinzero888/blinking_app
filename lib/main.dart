import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/device_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Generate device ID early (one-time, anonymous install identifier)
  await DeviceService.getDeviceId();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  runApp(BlinkingApp(storageService: storageService));
}
