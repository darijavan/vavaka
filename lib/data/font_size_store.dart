import 'package:shared_preferences/shared_preferences.dart';

abstract class FontSizeStore {
  static const defaultFontSize = 18.0;
  static const minimumFontSize = 14.0;
  static const maximumFontSize = 32.0;

  Future<double> loadFontSize();

  Future<void> saveFontSize(double fontSize);
}

class SharedPreferencesFontSizeStore implements FontSizeStore {
  static const preferenceKey = 'prayer_reader_font_size';

  @override
  Future<double> loadFontSize() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.get(preferenceKey);
    if (value is! num) {
      return FontSizeStore.defaultFontSize;
    }

    final fontSize = value.toDouble();
    if (!fontSize.isFinite ||
        fontSize < FontSizeStore.minimumFontSize ||
        fontSize > FontSizeStore.maximumFontSize) {
      return FontSizeStore.defaultFontSize;
    }
    return fontSize;
  }

  @override
  Future<void> saveFontSize(double fontSize) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(preferenceKey, fontSize);
  }
}
