import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/data/theme_mode_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads light by default and for invalid preferences', () async {
    final store = SharedPreferencesThemeModeStore();

    expect(await store.loadThemeMode(), ThemeMode.light);

    SharedPreferences.setMockInitialValues({
      SharedPreferencesThemeModeStore.preferenceKey: 'system',
    });
    expect(await store.loadThemeMode(), ThemeMode.light);
  });

  test('persists dark mode for a newly created store', () async {
    await SharedPreferencesThemeModeStore().saveThemeMode(ThemeMode.dark);

    expect(
      await SharedPreferencesThemeModeStore().loadThemeMode(),
      ThemeMode.dark,
    );
  });
}
