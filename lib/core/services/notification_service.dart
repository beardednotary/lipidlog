import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/user_profile.dart';

/// Local notification scheduling for reminder workflows.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyHabitId = 1001;
  static const int _dailyMedicationId = 1002;
  static const int _labCheckId = 1003;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback uses default timezone location.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> configureReminders(UserProfile profile) async {
    await init();

    if (profile.habitReminderEnabled) {
      await _scheduleDaily(
        id: _dailyHabitId,
        title: 'Log your habits',
        body: profile.prefersMorningLogging
            ? 'Log yesterday\'s habits to keep your score accurate.'
            : 'Quickly log today\'s habits to keep your score accurate.',
        hour: profile.habitReminderHour,
        minute: profile.habitReminderMinute,
      );
    } else {
      await _plugin.cancel(_dailyHabitId);
    }

    if (profile.onMedication && profile.medReminderEnabled) {
      await _scheduleDaily(
        id: _dailyMedicationId,
        title: 'Medication reminder',
        body: 'Remember to take your cholesterol medication today.',
        hour: profile.medReminderHour,
        minute: profile.medReminderMinute,
      );
    } else {
      await _plugin.cancel(_dailyMedicationId);
    }

    if (profile.labReminderEnabled) {
      await _scheduleLabCheck(profile.labReminderMonths);
    } else {
      await _plugin.cancel(_labCheckId);
    }
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduleDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily reminders',
          channelDescription: 'Daily habit and medication reminders.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleLabCheck(int months) async {
    final now = tz.TZDateTime.now(tz.local);
    final dueDate = now.add(Duration(days: months * 30));

    await _plugin.zonedSchedule(
      _labCheckId,
      'Lab check reminder',
      'It\'s time to schedule your next lipid lab test.',
      dueDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lab_reminders',
          'Lab reminders',
          channelDescription:
              'Long-interval reminders for follow-up lab tests.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
