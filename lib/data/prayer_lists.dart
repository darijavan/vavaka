import 'package:flutter/foundation.dart';

import 'bookmark_store.dart';
import 'recent_store.dart';

/// Bookmarked prayer ids shared by every screen showing a star.
/// `null` until the store has loaded.
class Bookmarks extends ValueNotifier<Set<String>?> {
  Bookmarks(this._store) : super(null) {
    _store.loadBookmarkedIds().then(
      (ids) => value = Set.unmodifiable(ids),
      onError: (Object _) => value = const {},
    );
  }

  final BookmarkStore _store;

  bool contains(String prayerId) => value?.contains(prayerId) ?? false;

  /// Persists first so a failed save leaves the visible state untouched.
  Future<void> toggle(String prayerId) async {
    final bookmarked = !contains(prayerId);
    await _store.setBookmarked(prayerId, bookmarked: bookmarked);
    final ids = {...?value};
    bookmarked ? ids.add(prayerId) : ids.remove(prayerId);
    value = Set.unmodifiable(ids);
  }
}

/// Recently opened prayer ids, most recent first.
class RecentPrayers extends ValueNotifier<List<String>?> {
  RecentPrayers(this._store) : super(null) {
    _loaded = _store.loadRecentIds().then(
      (ids) => value = List.unmodifiable(ids),
      onError: (Object _) => value = const <String>[],
    );
  }

  final RecentStore _store;
  late final Future<void> _loaded;

  Future<void> add(String prayerId) async {
    await _loaded;
    final ids = [
      prayerId,
      ...value!.where((id) => id != prayerId),
    ].take(RecentStore.maximumLength).toList(growable: false);
    value = ids;
    await _store.saveRecentIds(ids);
  }
}
