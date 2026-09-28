import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../copy.dart';
import '../data/models/prayer.dart';
import '../data/models/prayer_category.dart';
import '../data/prayer_lists.dart';
import '../data/prayer_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_message.dart';
import '../widgets/prayer_row.dart';
import '../widgets/section_label.dart';
import '../widgets/split_view.dart';
import '../widgets/vavaka_app_bar.dart';

/// "Tiana" tab: bookmarked prayers in dataset order.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.repository,
    required this.bookmarks,
  });

  final PrayerRepository repository;
  final Bookmarks bookmarks;

  @override
  Widget build(BuildContext context) {
    return _PrayerIdList(
      repository: repository,
      bookmarks: bookmarks,
      ids: bookmarks,
      select: (categories, ids) => [
        for (final category in categories)
          for (final prayer in category.prayers)
            if (ids.contains(prayer.id)) (prayer, null),
      ],
      label: (count) => '$count vavaka voatahiry',
      empty: const EmptyState(
        icon: Icons.star_border,
        message: Copy.favoritesEmpty,
      ),
    );
  }
}

/// "Vao haingana" tab: recently opened prayers, newest first.
class RecentScreen extends StatelessWidget {
  const RecentScreen({
    super.key,
    required this.repository,
    required this.bookmarks,
    required this.recentPrayers,
  });

  final PrayerRepository repository;
  final Bookmarks bookmarks;
  final RecentPrayers recentPrayers;

  @override
  Widget build(BuildContext context) {
    return _PrayerIdList(
      repository: repository,
      bookmarks: bookmarks,
      ids: recentPrayers,
      select: (categories, ids) {
        final byId = {
          for (final category in categories)
            for (final prayer in category.prayers)
              prayer.id: (prayer, category.name),
        };
        return [for (final id in ids) ?byId[id]];
      },
      empty: const EmptyState(
        icon: Icons.schedule,
        message: 'Eto no hisehoan’ny vavaka novakinao farany.',
      ),
    );
  }
}

class _PrayerIdList<T extends Iterable<String>> extends HookWidget {
  const _PrayerIdList({
    required this.repository,
    required this.bookmarks,
    required this.ids,
    required this.select,
    required this.empty,
    this.label,
  });

  final PrayerRepository repository;
  final Bookmarks bookmarks;
  final ValueNotifier<T?> ids;
  final List<(Prayer, String?)> Function(List<PrayerCategory>, T) select;
  final String Function(int count)? label;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final snapshot = useFuture(
      useMemoized(repository.loadCategories, [repository]),
    );
    final currentIds = useValueListenable(ids);

    return Scaffold(
      appBar: const VavakaAppBar(),
      body: switch (snapshot) {
        AsyncSnapshot(:final error?) => ErrorMessage(error: error),
        AsyncSnapshot(data: final List<PrayerCategory> categories)
            when currentIds != null =>
          _buildList(context, select(categories, currentIds)),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildList(BuildContext context, List<(Prayer, String?)> rows) {
    final header = label == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: SectionLabel(label!(rows.length)),
          );
    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: header,
            ),
          Expanded(child: empty),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ?header,
        for (final (index, (prayer, categoryName)) in rows.indexed) ...[
          if (index > 0) const Divider(height: 1, indent: 8, endIndent: 8),
          PrayerRow(
            prayer: prayer,
            bookmarks: bookmarks,
            categoryName: categoryName,
            onTap: () => openPrayer(context, prayer.id),
          ),
        ],
      ],
    );
  }
}
