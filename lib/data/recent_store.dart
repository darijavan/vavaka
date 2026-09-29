import 'package:shared_preferences/shared_preferences.dart';

abstract class RecentStore {
  static const maximumLength = 20;

  /// Prayer ids, most recently opened first.
  Future<List<String>> loadRecentIds();

  Future<void> saveRecentIds(List<String> prayerIds);
}

class SharedPreferencesRecentStore implements RecentStore {
  static const preferenceKey = 'recent_prayer_ids';

  @override
  Future<List<String>> loadRecentIds() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(preferenceKey) ?? const [];
  }

  @override
  Future<void> saveRecentIds(List<String> prayerIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(preferenceKey, prayerIds);
  }
}
