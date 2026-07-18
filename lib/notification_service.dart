// Mentesana — real OS notifications for the daily/weekly reminder.
// Replaces the earlier "quiet in-app note" stand-in: reminders now arrive
// as actual local notifications on Android and iOS, including while
// Mentesana is closed or backgrounded.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _dailyId = 1001;
  static const _weeklyId = 1002;
  static const _channelId = 'mentesana_reminders';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fall back to UTC if the platform's abbreviation isn't in the
      // timezone database — schedules still fire, just on UTC-relative time
      // until a future run resolves the local zone correctly.
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    const channel = AndroidNotificationChannel(
      _channelId,
      'Reminders',
      description: 'Quiet daily and weekly journaling reminders.',
      importance: Importance.low,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (android ?? true) && (ios ?? true);
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          importance: Importance.low,
          priority: Priority.low,
          silent: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      );

  tz.TZDateTime _nextInstanceOfTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 30;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int jsWeekday, String hhmm) {
    var scheduled = _nextInstanceOfTime(hhmm);
    // jsWeekday: 0 = Sunday, matching AppStore.weeklyReminderDay.
    while (scheduled.weekday % 7 != jsWeekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedules (or re-schedules) the daily reminder at [hhmm] ("HH:mm").
  Future<void> scheduleDaily(String hhmm) async {
    await init();
    await _plugin.zonedSchedule(
      _dailyId,
      'a quiet nudge',
      'the sea has room for a page.',
      _nextInstanceOfTime(hhmm),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_dailyId);
  }

  /// Schedules (or re-schedules) the weekly reminder on [weekday]
  /// (0 = Sunday), at 09:30.
  Future<void> scheduleWeekly(int weekday) async {
    await init();
    await _plugin.zonedSchedule(
      _weeklyId,
      'your weekly reflection',
      'is ready when you are.',
      _nextInstanceOfWeekday(weekday, '09:30'),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelWeekly() async {
    await init();
    await _plugin.cancel(_weeklyId);
  }
}
