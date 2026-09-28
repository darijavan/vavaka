import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/copy.dart';
import 'package:vavaka/app.dart';
import 'package:vavaka/data/bookmark_store.dart';
import 'package:vavaka/data/recent_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Cached asset futures from a previous test never resolve in the next
  // test's fake-async zone.
  setUp(rootBundle.clear);

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('favorites tab lists bookmarked prayers', (tester) async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesBookmarkStore.preferenceKey: ['ankizy-01'],
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await openTab(tester, 'Tiana');

    expect(find.text('1 VAVAKA VOATAHIRY'), findsOneWidget);
    expect(find.textContaining('Ry Andriamanitro! Tariho aho'), findsOneWidget);

    await tester.tap(find.byTooltip(Copy.removeBookmark));
    await tester.pumpAndSettle();

    expect(find.text('0 VAVAKA VOATAHIRY'), findsOneWidget);
    expect(find.text(Copy.favoritesEmpty), findsOneWidget);
    expect(await SharedPreferencesBookmarkStore().loadBookmarkedIds(), isEmpty);
  });

  testWidgets('recent tab shows prayers opened in the reader', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp(initialLocation: '/recent'));
    await tester.pumpAndSettle();

    expect(
      find.text('Eto no hisehoan’ny vavaka novakinao farany.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MyApp(
        key: ValueKey('reader'),
        initialLocation: '/prayers/ankizy-01',
      ),
    );
    await tester.pumpAndSettle();
    expect(await SharedPreferencesRecentStore().loadRecentIds(), ['ankizy-01']);

    await tester.pumpWidget(
      const MyApp(key: ValueKey('recent'), initialLocation: '/recent'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ankizy · '), findsOneWidget);
  });

  testWidgets('reminders tab shows the designed empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await openTab(tester, 'Tsiahy');

    expect(
      find.text('Mametraha fampahatsiahivana mba hivavaka isan’andro.'),
      findsOneWidget,
    );
  });
}
