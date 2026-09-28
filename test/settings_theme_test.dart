import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vavaka/app.dart';
import 'package:vavaka/data/theme_mode_store.dart';

class _MemoryThemeModeStore implements ThemeModeStore {
  _MemoryThemeModeStore(this.themeMode);

  ThemeMode themeMode;

  @override
  Future<ThemeMode> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(ThemeMode value) async => themeMode = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Settings toggle changes and persists the app theme mode', (
    tester,
  ) async {
    final store = _MemoryThemeModeStore(ThemeMode.light);
    await tester.pumpWidget(MyApp(themeModeStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    await tester.tap(find.text('Endrika maizina'));
    await tester.pumpAndSettle();

    expect(store.themeMode, ThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Endrika maizina'))).brightness,
      Brightness.dark,
    );
  });
}
