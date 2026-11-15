import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/app.dart';
import 'package:vavaka/copy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tablet shows the reader next to the prayer list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(initialLocation: '/categories/ankizy'));
    await tester.pumpAndSettle();

    expect(find.text('Vavaka Baháʼí'), findsOneWidget);
    expect(find.text('5 VAVAKA'), findsOneWidget);

    await tester.tap(find.textContaining('Tariho aho').first);
    await tester.pumpAndSettle();

    // The list stays visible while the detail pane shows the reader.
    expect(find.textContaining('Beazo ireto zaza'), findsOneWidget);
    expect(find.textContaining('fanaovanjiro hanazava'), findsOneWidget);
    expect(find.text('Sokajy: Ankizy'), findsOneWidget);
    expect(find.text('Vavaka Baháʼí'), findsNothing);
  });

  testWidgets('phone pushes the reader over the list', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(initialLocation: '/categories/ankizy'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Tariho aho').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Beazo ireto zaza'), findsNothing);
    expect(find.textContaining('fanaovanjiro hanazava'), findsOneWidget);
  });

  testWidgets('settings slider updates an open tablet reader', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(initialLocation: '/categories/ankizy'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tariho aho').first);
    await tester.pumpAndSettle();

    final paragraph = find.textContaining('fanaovanjiro hanazava');
    expect(tester.widget<Text>(paragraph).style?.fontSize, 18);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Copy.settings));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();

    final size = tester.widget<Slider>(find.byType(Slider)).value;
    expect(size, isNot(18));
    expect(tester.widget<Text>(paragraph).style?.fontSize, size);
  });
}
