import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/app.dart';
import 'package:vavaka/data/bookmark_store.dart';
import 'package:vavaka/data/models/prayer.dart';
import 'package:vavaka/data/models/prayer_category.dart';
import 'package:vavaka/data/prayer_lists.dart';
import 'package:vavaka/data/prayer_repository.dart';
import 'package:vavaka/screens/category_detail_screen.dart';
import 'package:vavaka/screens/category_list_screen.dart';

class _MissingCategoryRepository extends PrayerRepository {
  @override
  Future<PrayerCategory> findCategoryBySlug(String slug) {
    return Future.error(FormatException('Unknown prayer category: $slug'));
  }
}

class _RetryingCategoryRepository extends PrayerRepository {
  var attempts = 0;

  @override
  Future<List<PrayerCategory>> loadCategories() {
    attempts++;
    if (attempts == 1) {
      return Future.error(const FormatException('Temporary asset failure'));
    }

    return Future.value([
      PrayerCategory(slug: 'retry', name: 'Loaded categories', prayers: []),
    ]);
  }
}

class _SearchRepository extends PrayerRepository {
  final prayers = [
    Prayer(
      id: 'search-result',
      title: 'Vavaka maraina',
      category: 'isanandro',
      author: "'Abdu'l-Bahá VAVAKA",
      content: PrayerContent(
        schema: 'dast',
        paragraphs: ['Hazavao ny foko amin’ny vavaka sy ny fahazavanao.'],
      ),
    ),
  ];

  @override
  Future<List<PrayerCategory>> loadCategories() => Future.value([
    PrayerCategory(slug: 'isanandro', name: 'Isanandro', prayers: prayers),
  ]);
}

Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('navigates from category list to prayer detail', (tester) async {
    await tester.pumpWidget(const MyApp());
    await pumpUntil(tester, find.text('Ankizy'));

    expect(find.text('Vavaka'), findsWidgets);
    expect(find.text('Andro manelanelana'), findsOneWidget);
    expect(find.text('Ankizy'), findsOneWidget);

    await tester.tap(find.text('Ankizy'));
    final prayerTile = find.textContaining('Ry Andriamanitro! Tariho aho');
    await pumpUntil(tester, prayerTile);

    expect(find.text('Ankizy'), findsWidgets);
    expect(prayerTile, findsOneWidget);
    expect(find.textContaining("'Abdu'l-Bahá · 22 teny"), findsWidgets);

    await tester.tap(prayerTile);
    await pumpUntil(tester, find.textContaining('fanaovanjiro hanazava'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ry Andriamanitro! Tariho aho'), findsWidgets);
    expect(find.text("— 'Abdu'l-Bahá"), findsOneWidget);
    expect(find.textContaining('fanaovanjiro hanazava'), findsOneWidget);

    final paragraph = find.textContaining('fanaovanjiro hanazava');
    Text paragraphText() => tester.widget<Text>(paragraph);

    expect(paragraphText().style?.fontSize, 18);
    final increaseButton = find.byTooltip('Increase text size');
    await tester.ensureVisible(increaseButton);
    await tester.tap(increaseButton);
    await tester.pump();
    expect(paragraphText().style?.fontSize, 20);
  });

  testWidgets('debounces search and highlights matches case-insensitively', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: _SearchRepository()));
    await tester.tap(find.byTooltip('Search prayers'));
    await pumpUntil(
      tester,
      find.text('Enter a word or phrase to search prayers.'),
    );

    await tester.enterText(find.byType(TextField), 'vAvAkA');
    await tester.pump();
    expect(find.text('Vavaka maraina'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Vavaka maraina'), findsOneWidget);

    final highlighted = tester
        .widgetList<Text>(find.byType(Text))
        .expand(
          (text) => text.textSpan is TextSpan
              ? (text.textSpan as TextSpan).children ?? const <InlineSpan>[]
              : const <InlineSpan>[],
        )
        .whereType<TextSpan>()
        .where((span) => span.style?.fontWeight == FontWeight.bold)
        .map((span) => span.text)
        .toList();
    expect(highlighted, ['Vavaka']);
    expect(find.text('VALINY 1'), findsOneWidget);

    await tester.tap(find.text('Vavaka maraina'));
    await pumpUntil(tester, find.textContaining('Hazavao ny foko'));

    expect(find.textContaining('Hazavao ny foko'), findsOneWidget);
  });

  testWidgets('retries category loading after an error', (tester) async {
    final repository = _RetryingCategoryRepository();

    await tester.pumpWidget(
      MaterialApp(home: CategoryListScreen(repository: repository)),
    );
    await pumpUntil(tester, find.textContaining('Temporary asset failure'));

    await tester.tap(find.text('Try again'));
    await pumpUntil(tester, find.text('Loaded categories'));

    expect(repository.attempts, 2);
    expect(find.text('Loaded categories'), findsOneWidget);
  });

  testWidgets('shows an error for an unknown category', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(
          repository: _MissingCategoryRepository(),
          bookmarks: Bookmarks(SharedPreferencesBookmarkStore()),
          slug: 'does-not-exist',
        ),
      ),
    );
    await pumpUntil(
      tester,
      find.textContaining('Unknown prayer category: does-not-exist'),
    );

    expect(
      find.textContaining('Unknown prayer category: does-not-exist'),
      findsOneWidget,
    );
  });
}
