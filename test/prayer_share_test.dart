import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/bookmark_store.dart';
import 'package:vavaka/data/font_size_store.dart';
import 'package:vavaka/data/prayer_repository.dart';
import 'package:vavaka/data/prayer_sharer.dart';
import 'package:vavaka/screens/prayer_detail_screen.dart';

class _RecordingPrayerSharer implements PrayerSharer {
  String? text;

  @override
  Future<void> share(String text) async => this.text = text;
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
          bookmarkStore: SharedPreferencesBookmarkStore(),
          fontSizeStore: SharedPreferencesFontSizeStore(),
          prayerSharer: sharer,
          prayerId: 'ankizy-01',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Share prayer'));
    await tester.pump();

    expect(
      sharer.text,
      [prayer!.title, prayer.author, ...prayer.paragraphs].join('\n\n'),
    );
  });
}
