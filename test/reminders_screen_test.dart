import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/app.dart';
import 'package:vavaka/copy.dart';

import 'data/reminders_test.dart' show FakeScheduler;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('adds, toggles and deletes a daily reminder', (tester) async {
    final scheduler = FakeScheduler();
    await tester.pumpWidget(
      MyApp(initialLocation: '/reminders', reminderScheduler: scheduler),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.addReminder));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('06:00'), findsOneWidget);
    expect(find.text(Copy.remindersLabel.toUpperCase()), findsOneWidget);
    expect(scheduler.scheduled!.single.enabled, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(scheduler.scheduled!.single.enabled, isFalse);

    await tester.tap(find.byTooltip(Copy.deleteReminder));
    await tester.pumpAndSettle();
    expect(find.text('06:00'), findsNothing);
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('explains when notification permission is refused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        initialLocation: '/reminders',
        reminderScheduler: FakeScheduler(granted: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.addReminder));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.permissionDenied), findsOneWidget);
    expect(find.text('06:00'), findsNothing);
  });
}
