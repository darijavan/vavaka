import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class Reminder {
  const Reminder({
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  /// Parses the `HH:MM:1` form written by [encode]; null if malformed.
  static Reminder? decode(String value) {
    final parts = value.split(':');
    if (parts.length != 3) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || hour < 0 || hour > 23) return null;
    if (minute == null || minute < 0 || minute > 59) return null;
    return Reminder(hour: hour, minute: minute, enabled: parts[2] == '1');
  }

  final int hour;
  final int minute;
  final bool enabled;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String encode() => '$label:${enabled ? 1 : 0}';

  int get _minutesOfDay => hour * 60 + minute;

  Reminder copyWith({bool? enabled}) =>
      Reminder(hour: hour, minute: minute, enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.hour == hour &&
      other.minute == minute &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(hour, minute, enabled);
}

abstract class ReminderStore {
  Future<List<Reminder>> loadReminders();

  Future<void> saveReminders(List<Reminder> reminders);
}

class SharedPreferencesReminderStore implements ReminderStore {
  static const preferenceKey = 'daily_reminders';

  @override
  Future<List<Reminder>> loadReminders() async {
    final preferences = await SharedPreferences.getInstance();
    return [
      for (final value in preferences.getStringList(preferenceKey) ?? const [])
        ?Reminder.decode(value),
    ];
  }

  @override
  Future<void> saveReminders(List<Reminder> reminders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(preferenceKey, [
      for (final reminder in reminders) reminder.encode(),
    ]);
  }
}

/// Delivers daily notifications for the enabled reminders.
abstract class ReminderScheduler {
  /// Asks the OS for permission to notify; false when refused.
  Future<bool> requestPermission();

  /// Replaces every scheduled notification with [reminders].
  Future<void> schedule(List<Reminder> reminders);
}

/// Daily reminders, sorted by time, shared with the Tsiahy screen.
class Reminders extends ValueNotifier<List<Reminder>?> {
  Reminders(this._store, this._scheduler) : super(null) {
    _store.loadReminders().then(
      (reminders) => value = List.unmodifiable(_sorted(reminders)),
      onError: (Object _) => value = const [],
    );
  }

  final ReminderStore _store;
  final ReminderScheduler _scheduler;

  /// Returns false when notification permission was refused.
  Future<bool> add(int hour, int minute) async {
    if (!await _scheduler.requestPermission()) return false;
    await _update([
      ...?value?.where((r) => r.hour != hour || r.minute != minute),
      Reminder(hour: hour, minute: minute),
    ]);
    return true;
  }

  /// Returns false when enabling needed a permission that was refused.
  Future<bool> setEnabled(Reminder reminder, bool enabled) async {
    if (enabled && !await _scheduler.requestPermission()) return false;
    await _update([
      for (final r in value ?? const <Reminder>[])
        r == reminder ? r.copyWith(enabled: enabled) : r,
    ]);
    return true;
  }

  Future<void> remove(Reminder reminder) =>
      _update([...?value?.where((r) => r != reminder)]);

  Future<void> _update(List<Reminder> reminders) async {
    final sorted = List<Reminder>.unmodifiable(_sorted(reminders));
    await _store.saveReminders(sorted);
    value = sorted;
    await _scheduler.schedule(sorted);
  }

  static List<Reminder> _sorted(List<Reminder> reminders) =>
      [...reminders]..sort((a, b) => a._minutesOfDay - b._minutesOfDay);
}
