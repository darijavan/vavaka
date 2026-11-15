import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/prayer_lists.dart';
import 'package:vavaka/data/recent_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recent prayers move to the front, dedupe, and are capped', () async {
    final recent = RecentPrayers(SharedPreferencesRecentStore());

    for (var i = 0; i < RecentStore.maximumLength + 5; i++) {
      await recent.add('prayer-$i');
    }
    await recent.add('prayer-10');

    final stored = await SharedPreferencesRecentStore().loadRecentIds();
    expect(stored, recent.value);
    expect(stored, hasLength(RecentStore.maximumLength));
    expect(stored.first, 'prayer-10');
    expect(stored.where((id) => id == 'prayer-10'), hasLength(1));
    expect(stored[1], 'prayer-${RecentStore.maximumLength + 4}');
  });
}
