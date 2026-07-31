import 'package:shared_preferences/shared_preferences.dart';

abstract class BookmarkStore {
  Future<bool> isBookmarked(String prayerId);

  Future<void> setBookmarked(String prayerId, {required bool bookmarked});
}

class SharedPreferencesBookmarkStore implements BookmarkStore {
  static const preferenceKey = 'bookmarked_prayer_ids';

  @override
  Future<bool> isBookmarked(String prayerId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(preferenceKey)?.contains(prayerId) ??
        false;
  }

  @override
  Future<void> setBookmarked(
    String prayerId, {
    required bool bookmarked,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final prayerIds =
        preferences.getStringList(preferenceKey)?.toSet() ?? <String>{};

    if (bookmarked) {
      prayerIds.add(prayerId);
    } else {
      prayerIds.remove(prayerId);
    }

    await preferences.setStringList(
      preferenceKey,
      prayerIds.toList()..sort(),
    );
  }
}
