import 'package:shared_preferences/shared_preferences.dart';

abstract class BookmarkStore {
  Future<Set<String>> loadBookmarkedIds();

  Future<bool> isBookmarked(String prayerId);

  Future<void> setBookmarked(String prayerId, {required bool bookmarked});
}

class SharedPreferencesBookmarkStore implements BookmarkStore {
  static const preferenceKey = 'bookmarked_prayer_ids';

  @override
  Future<Set<String>> loadBookmarkedIds() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(preferenceKey)?.toSet() ?? <String>{};
  }

  @override
  Future<bool> isBookmarked(String prayerId) async =>
      (await loadBookmarkedIds()).contains(prayerId);

  @override
  Future<void> setBookmarked(
    String prayerId, {
    required bool bookmarked,
  }) async {
    final prayerIds = await loadBookmarkedIds();

    if (bookmarked) {
      prayerIds.add(prayerId);
    } else {
      prayerIds.remove(prayerId);
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(preferenceKey, prayerIds.toList()..sort());
  }
}
