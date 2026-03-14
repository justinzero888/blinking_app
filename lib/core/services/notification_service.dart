import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../models/routine.dart';

/// Service to handle local push notifications for routine reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> init() async {
    // 1. Initialize timezone data
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS / macOS settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request this separately
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 4. Combined settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 5. Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  /// Request notification permissions (mandatory for Android 13+)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.requestNotificationsPermission() ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Schedule a daily reminder for a routine
  Future<void> scheduleRoutineReminder(Routine routine) async {
    if (routine.reminderTime == null || !routine.isActive) return;

    final parts = routine.reminderTime!.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Use routine's hashcode as a unique ID for the notification
    final int notificationId = routine.id.hashCode.abs();

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '日常提醒: ${routine.name}', // Reminder: [Name]
      '该去完成你的习惯啦！', // Time to complete your habit!
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders',
          '习惯提醒',
          channelDescription: '用于日常习惯打卡的提醒',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Recurring daily
      payload: routine.id,
    );
    
    debugPrint('Scheduled reminder for ${routine.name} at $hour:$minute');
  }

  /// Cancel a specific routine reminder
  Future<void> cancelRoutineReminder(String routineId) async {
    await _notificationsPlugin.cancel(routineId.hashCode.abs());
    debugPrint('Cancelled reminder for $routineId');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Helper to calculate the next instance of a time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
