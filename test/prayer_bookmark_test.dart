import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/bookmark_store.dart';
import 'package:vavaka/data/font_size_store.dart';
import 'package:vavaka/data/prayer_repository.dart';
import 'package:vavaka/main.dart';

Future<void> _pumpReader(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PrayerDetailScreen(
        repository: PrayerRepository(),
        bookmarkStore: SharedPreferencesBookmarkStore(),
        fontSizeStore: SharedPreferencesFontSizeStore(),
        prayerId: 'ankizy-01',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bookmarks and unbookmarks the current prayer', (tester) async {
    await _pumpReader(tester);

    await tester.tap(find.byTooltip('Bookmark prayer'));
    await tester.pumpAndSettle();

    expect(
      await SharedPreferencesBookmarkStore().isBookmarked('ankizy-01'),
      isTrue,
    );
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove bookmark'));
    await tester.pumpAndSettle();

    expect(
      await SharedPreferencesBookmarkStore().isBookmarked('ankizy-01'),
      isFalse,
    );
    expect(find.byTooltip('Bookmark prayer'), findsOneWidget);
  });

  testWidgets('loads an existing bookmark when the reader opens', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesBookmarkStore.preferenceKey: ['ankizy-01'],
    });
    await _pumpReader(tester);

    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });
}
