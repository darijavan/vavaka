import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/copy.dart';
import 'package:vavaka/data/bookmark_store.dart';
import 'package:vavaka/data/font_size_store.dart';
import 'package:vavaka/data/prayer_lists.dart';
import 'package:vavaka/data/prayer_repository.dart';
import 'package:vavaka/data/recent_store.dart';
import 'package:vavaka/screens/prayer_detail_screen.dart';

class _MemoryFontSizeStore implements FontSizeStore {
  _MemoryFontSizeStore(this.fontSize);

  double fontSize;
  final loadCompleter = Completer<double>();
  final savedValues = <double>[];
  var _loaded = false;

  @override
  Future<double> loadFontSize() async {
    if (!_loaded) {
      fontSize = await loadCompleter.future;
      _loaded = true;
    }
    return fontSize;
  }

  @override
  Future<void> saveFontSize(double value) async {
    fontSize = value;
    savedValues.add(value);
  }
}

Future<void> _pumpReader(
  WidgetTester tester,
  FontSizeStore fontSizeStore,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PrayerDetailScreen(
        repository: PrayerRepository(),
        bookmarks: Bookmarks(SharedPreferencesBookmarkStore()),
        recentPrayers: RecentPrayers(SharedPreferencesRecentStore()),
        fontSizeStore: fontSizeStore,
        prayerId: 'ankizy-01',
      ),
    ),
  );
}

void main() {
  testWidgets('waits for the saved size, then persists reader changes', (
    tester,
  ) async {
    final store = _MemoryFontSizeStore(24.0);
    await _pumpReader(tester, store);
    await tester.pumpAndSettle();

    expect(find.textContaining('fanaovanjiro hanazava'), findsNothing);
    final increaseButton = find.ancestor(
      of: find.byTooltip(Copy.increaseTextSize),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(increaseButton).onPressed, isNull);
    expect(store.savedValues, isEmpty);

    store.loadCompleter.complete(store.fontSize);
    await tester.pumpAndSettle();

    final paragraph = find.textContaining('fanaovanjiro hanazava');
    expect(tester.widget<Text>(paragraph).style?.fontSize, 24.0);

    await tester.tap(find.byTooltip(Copy.increaseTextSize));
    await tester.pump();
    expect(tester.widget<Text>(paragraph).style?.fontSize, 26.0);
    expect(store.savedValues, [26.0]);

    await tester.pumpWidget(const SizedBox());
    await _pumpReader(tester, store);
    await tester.pumpAndSettle();

    final reopenedParagraph = find.textContaining('fanaovanjiro hanazava');
    expect(tester.widget<Text>(reopenedParagraph).style?.fontSize, 26.0);
    expect(store.savedValues, [26.0]);

    store.fontSize = 31;
    await tester.pumpWidget(const SizedBox());
    await _pumpReader(tester, store);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(reopenedParagraph).style?.fontSize, 31);
    await tester.tap(find.byTooltip(Copy.increaseTextSize));
    await tester.pump();
    expect(store.savedValues.last, FontSizeStore.maximumFontSize);
    expect(
      tester.widget<Text>(reopenedParagraph).style?.fontSize,
      FontSizeStore.maximumFontSize,
    );
  });
}
