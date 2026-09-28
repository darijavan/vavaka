import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../copy.dart';
import 'reminders.dart';

/// [ReminderScheduler] backed by flutter_local_notifications. The plugin is
/// only touched on first use, so tests and screens that never schedule
/// anything need no platform channel.
class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminders',
      Copy.remindersChannel,
      importance: Importance.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false,
      TargetPlatform.iOS =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false,
      _ => false,
    };
  }

  @override
  Future<void> schedule(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final (index, reminder) in reminders.indexed) {
      if (!reminder.enabled) continue;
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: index,
        title: Copy.reminderTitle,
        body: Copy.reminderBody,
        scheduledDate: next,
        notificationDetails: _details,
        // Inexact delivery avoids the exact-alarm permission on Android 14+.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
