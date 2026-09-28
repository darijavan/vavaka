import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/bookmark_store.dart';
import 'package:vavaka/data/font_size_store.dart';
import 'package:vavaka/data/prayer_lists.dart';
import 'package:vavaka/data/models/prayer.dart';
import 'package:vavaka/data/prayer_repository.dart';
import 'package:vavaka/data/prayer_sharer.dart';
import 'package:vavaka/data/recent_store.dart';
import 'package:vavaka/screens/prayer_detail_screen.dart';

class _RecordingPrayerSharer implements PrayerSharer {
  String? text;

  @override
  Future<void> share(String text) async => this.text = text;
}

class _ControllablePrayerSharer implements PrayerSharer {
  final calls = <Completer<void>>[];

  @override
  Future<void> share(String text) {
    final call = Completer<void>();
    calls.add(call);
    return call.future;
  }
}

class _ShareRepository extends PrayerRepository {
  @override
  Future<Prayer?> findPrayerById(String id) => Future.value(
    Prayer(
      id: id,
      title: 'Vavaka fitsapana',
      category: 'fitsapana',
      author: "'Abdu'l-Bahá",
      content: PrayerContent(schema: 'dast', paragraphs: ['Vavaka fitsapana.']),
    ),
  );
}

Future<void> _tapShare(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More options'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Zarao'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shares the loaded prayer title, author, and all paragraphs', (
    tester,
  ) async {
    final sharer = _RecordingPrayerSharer();
    final repository = PrayerRepository();
    final prayer = await repository.findPrayerById('ankizy-01');

    await tester.pumpWidget(
      MaterialApp(
        home: PrayerDetailScreen(
          repository: repository,
          bookmarks: Bookmarks(SharedPreferencesBookmarkStore()),
          recentPrayers: RecentPrayers(SharedPreferencesRecentStore()),
          fontSizeStore: SharedPreferencesFontSizeStore(),
          prayerSharer: sharer,
          prayerId: 'ankizy-01',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapShare(tester);

    expect(
      sharer.text,
      [prayer!.title, prayer.author, ...prayer.paragraphs].join('\n\n'),
    );
  });

  testWidgets('recovers from a share failure and allows a successful retry', (
    tester,
  ) async {
    final sharer = _ControllablePrayerSharer();
    final repository = _ShareRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PrayerDetailScreen(
          repository: repository,
          bookmarks: Bookmarks(SharedPreferencesBookmarkStore()),
          recentPrayers: RecentPrayers(SharedPreferencesRecentStore()),
          fontSizeStore: SharedPreferencesFontSizeStore(),
          prayerSharer: sharer,
          prayerId: 'ankizy-01',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapShare(tester);
    expect(sharer.calls, hasLength(1));

    // While the first share is pending, the menu entry is disabled.
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    final shareItem = find.ancestor(
      of: find.text('Zarao'),
      matching: find.byType(PopupMenuItem<void>),
    );
    expect(tester.widget<PopupMenuItem<void>>(shareItem).enabled, isFalse);
    await tester.tap(find.text('Zarao'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(sharer.calls, hasLength(1));
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    sharer.calls.single.completeError(Exception('share failed'));
    await tester.pumpAndSettle();

    expect(find.text('Could not share prayer.'), findsOneWidget);

    await _tapShare(tester);
    expect(sharer.calls, hasLength(2));

    sharer.calls.last.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
