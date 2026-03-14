import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  
  runApp(BlinkingApp(storageService: storageService));
}
