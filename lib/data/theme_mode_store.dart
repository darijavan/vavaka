import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeModeStore {
  Future<ThemeMode> loadThemeMode();

  Future<void> saveThemeMode(ThemeMode themeMode);
}

class SharedPreferencesThemeModeStore implements ThemeModeStore {
  static const preferenceKey = 'theme_mode';

  @override
  Future<ThemeMode> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(preferenceKey) == ThemeMode.dark.name
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, themeMode.name);
  }
}
