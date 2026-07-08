import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/main.dart';

Future<void> pumpUntilLoaded(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigates from category list to prayer detail', (tester) async {
    await tester.pumpWidget(const MyApp());
    await pumpUntilLoaded(tester);

    expect(find.text('Vavaka'), findsWidgets);
    expect(find.text('Andro manelanelana'), findsOneWidget);
    expect(find.text('Ankizy'), findsOneWidget);

    await tester.tap(find.text('Ankizy'));
    await pumpUntilLoaded(tester);

    expect(find.text('Ankizy'), findsWidgets);
    final prayerTile = find.textContaining('Ry Andriamanitro! Tariho aho');
    expect(prayerTile, findsOneWidget);
    expect(find.text("'Abdu'l-Bahá"), findsWidgets);

    await tester.tap(prayerTile);
    await pumpUntilLoaded(tester);

    expect(find.textContaining('Ry Andriamanitro! Tariho aho'), findsWidgets);
    expect(find.text("'Abdu'l-Bahá"), findsOneWidget);
    expect(find.textContaining('fanaovanjiro hanazava'), findsOneWidget);
  });
}
