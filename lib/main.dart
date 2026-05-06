import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/device_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceService.getDeviceId();

  final storageService = StorageService();
  await storageService.init();

  runApp(BlinkingApp(storageService: storageService));
}
