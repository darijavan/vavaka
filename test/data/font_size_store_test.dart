import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/font_size_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads the default when the preference is absent or invalid', () async {
    final store = SharedPreferencesFontSizeStore();

    expect(await store.loadFontSize(), 18.0);

    for (final value in <Object>['large', double.nan, 13.0, 33.0]) {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesFontSizeStore.preferenceKey: value,
      });
      expect(await store.loadFontSize(), 18.0);
    }
  });

  test('persists a font size for a newly created store', () async {
    await SharedPreferencesFontSizeStore().saveFontSize(24.0);

    expect(await SharedPreferencesFontSizeStore().loadFontSize(), 24.0);
  });
}
