import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/reminders.dart';

class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.granted = true});

  bool granted;
  List<Reminder>? scheduled;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> schedule(List<Reminder> reminders) async =>
      scheduled = reminders;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Reminders> loaded(ReminderScheduler scheduler) async {
    final reminders = Reminders(SharedPreferencesReminderStore(), scheduler);
    await pumpEventQueue();
    return reminders;
  }

  test('adds reminders sorted by time, persists and schedules them', () async {
    final scheduler = FakeScheduler();
    final reminders = await loaded(scheduler);

    expect(await reminders.add(21, 0), isTrue);
    expect(await reminders.add(6, 30), isTrue);
    expect(await reminders.add(21, 0), isTrue); // same time is not duplicated

    expect(reminders.value!.map((r) => r.label), ['06:30', '21:00']);
    expect(scheduler.scheduled, reminders.value);
    expect(
      (await SharedPreferencesReminderStore().loadReminders()),
      reminders.value,
    );
  });

  test(
    'disabling and removing reschedule; refused permission changes nothing',
    () async {
      final scheduler = FakeScheduler();
      final reminders = await loaded(scheduler);
      await reminders.add(6, 0);
      final morning = reminders.value!.single;

      await reminders.setEnabled(morning, false);
      expect(scheduler.scheduled!.single.enabled, isFalse);

      scheduler.granted = false;
      expect(
        await reminders.setEnabled(reminders.value!.single, true),
        isFalse,
      );
      expect(await reminders.add(7, 0), isFalse);
      expect(reminders.value!.single.enabled, isFalse);

      await reminders.remove(reminders.value!.single);
      expect(reminders.value, isEmpty);
      expect(scheduler.scheduled, isEmpty);
    },
  );

  test('ignores malformed stored values', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesReminderStore.preferenceKey: ['25:00:1', 'x', '07:05:0'],
    });
    final reminders = await loaded(FakeScheduler());

    expect(reminders.value, [
      const Reminder(hour: 7, minute: 5, enabled: false),
    ]);
  });
}
