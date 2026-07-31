import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/bookmark_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists bookmark changes for a newly created store', () async {
    final store = SharedPreferencesBookmarkStore();

    await store.setBookmarked('ankizy-01', bookmarked: true);

    expect(
      await SharedPreferencesBookmarkStore().isBookmarked('ankizy-01'),
      isTrue,
    );

    await store.setBookmarked('ankizy-01', bookmarked: false);

    expect(
      await SharedPreferencesBookmarkStore().isBookmarked('ankizy-01'),
      isFalse,
    );
  });
}
