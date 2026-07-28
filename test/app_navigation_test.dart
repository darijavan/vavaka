import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/data/models/prayer.dart';
import 'package:vavaka/data/models/prayer_category.dart';
import 'package:vavaka/data/prayer_repository.dart';
import 'package:vavaka/main.dart';

class _MissingCategoryRepository extends PrayerRepository {
  @override
  Future<PrayerCategory> findCategoryBySlug(String slug) {
    return Future.error(FormatException('Unknown prayer category: $slug'));
  }
}

class _SearchRepository extends PrayerRepository {
  final prayer = Prayer(
    id: 'ankizy-01',
    title: 'Ry Andriamanitro! Tariho aho',
    category: 'ankizy',
    author: "'Abdu'l-Bahá",
    content: PrayerContent(
      schema: 'dast',
      paragraphs: ['Ataovy ho toy ny fanaovanjiro hanazava aho.'],
    ),
  );

  late final category = PrayerCategory(
    slug: 'ankizy',
    name: 'Ankizy',
    prayers: [prayer],
  );

  @override
  Future<List<PrayerCategory>> loadCategories() async => [category];

  @override
  Future<List<Prayer>> loadAllPrayers() async => [prayer];

  @override
  Future<PrayerCategory> findCategoryBySlug(String slug) async => category;

  @override
  Future<Prayer?> findPrayerById(String id) async => prayer;
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
    expect(find.text("'Abdu'l-Bahá"), findsWidgets);

    await tester.tap(prayerTile);
    await pumpUntil(tester, find.textContaining('fanaovanjiro hanazava'));

    expect(find.textContaining('Ry Andriamanitro! Tariho aho'), findsWidgets);
    expect(find.text("'Abdu'l-Bahá"), findsWidgets);
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

  testWidgets('shows an error for an unknown category', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(
          repository: _MissingCategoryRepository(),
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

  testWidgets('searches prayer text and opens the matching reader', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: _SearchRepository()));
    await pumpUntil(tester, find.byTooltip('Search prayers'));
    await tester.tap(find.byTooltip('Search prayers'));
    await pumpUntil(
      tester,
      find.text('Enter a word or phrase to search prayers.'),
    );

    await tester.enterText(find.byType(TextField), 'FANAOVANJIRO HANAZAVA');
    await tester.pump();
    expect(
      find.text('Enter a word or phrase to search prayers.'),
      findsNothing,
    );
    final result = find.textContaining('Ry Andriamanitro! Tariho aho');
    await pumpUntil(tester, result);
    expect(result, findsOneWidget);
    await tester.tap(result);
    await pumpUntil(tester, find.textContaining('fanaovanjiro hanazava'));

    expect(find.textContaining('fanaovanjiro hanazava'), findsOneWidget);
    expect(find.byTooltip('Increase text size'), findsOneWidget);
  });
}
