import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../models/routine.dart';

/// Local-only notification service tied to routine reminders.
/// Zero data leaves the device — fully aligned with privacy claim.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'routine_reminders';
  static const _channelName = 'Routine Reminders';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily habit and routine reminders',
      importance: Importance.defaultImportance,
      enableVibration: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  static Future<void> scheduleRoutine(Routine routine, bool isZh) async {
    if (!_initialized) return;
    if (routine.reminderTime == null) return;
    if (!routine.isActive) return;

    await cancelRoutine(routine.id, isZh);

    final parts = routine.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    try {
      final title = routine.icon ?? routine.effectiveIcon;
      final body = routine.displayName(isZh);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final details = _notificationDetails();

      if (routine.frequency == RoutineFrequency.weekly && routine.scheduledDaysOfWeek != null) {
        for (final day in routine.scheduledDaysOfWeek!) {
          final weekdayDate = _nextWeekday(now, day, hour, minute);
          await _plugin.zonedSchedule(
            id: _routineNotificationId(routine, day),
            title: title,
            body: body,
            scheduledDate: weekdayDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        return;
      }

      if (routine.frequency == RoutineFrequency.scheduled && routine.scheduledDate != null) {
        final sched = routine.scheduledDate!;
        scheduledDate = tz.TZDateTime(tz.local, sched.year, sched.month, sched.day, hour, minute);
        if (scheduledDate.isBefore(now)) return;
      }

      await _plugin.zonedSchedule(
        id: _routineNotificationId(routine, 0),
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancelRoutine(String routineId, bool isZh) async {
    if (!_initialized) return;
    final baseId = routineId.hashCode.abs();
    for (var i = 0; i <= 7; i++) {
      await _plugin.cancel(id: baseId + i);
    }
  }

  static Future<void> rescheduleAll(List<Routine> routines, bool isZh) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    for (final r in routines) {
      if (r.isActive && r.reminderTime != null) {
        await scheduleRoutine(r, isZh);
      }
    }
  }

  static int _routineNotificationId(Routine routine, int subId) {
    return routine.id.hashCode.abs() + subId;
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily habit and routine reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );
  }

  static tz.TZDateTime _nextWeekday(tz.TZDateTime now, int weekday, int hour, int minute) {
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (date.weekday != weekday || date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }
}
