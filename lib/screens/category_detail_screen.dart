import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../data/models/prayer_category.dart';
import '../data/prayer_lists.dart';
import '../data/prayer_repository.dart';
import '../theme.dart';
import '../widgets/error_message.dart';
import '../widgets/prayer_row.dart';
import '../widgets/section_label.dart';
import '../widgets/split_view.dart';
import '../widgets/vavaka_app_bar.dart';

class CategoryDetailScreen extends HookWidget {
  const CategoryDetailScreen({
    super.key,
    required this.repository,
    required this.bookmarks,
    required this.slug,
  });

  final PrayerRepository repository;
  final Bookmarks bookmarks;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(() => repository.findCategoryBySlug(slug), [
      repository,
      slug,
    ]);
    final snapshot = useFuture(future);
    final category = snapshot.data;
    void back() => Navigator.maybePop(context);

    return Scaffold(
      // The tablet master pane shows the category in its header instead of
      // the brand, like the Figma "ipad-prayer-list" frames.
      appBar: isInMasterPane(context)
          ? VavakaAppBar(
              title: BackAction(label: category?.name, onPressed: back),
              actions: [
                if (category != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SectionLabel('${category.prayerCount} vavaka'),
                  ),
              ],
            )
          : VavakaAppBar(leading: BackAction(onPressed: back)),
      body: switch (snapshot) {
        AsyncSnapshot(:final error?) => ErrorMessage(error: error),
        AsyncSnapshot(data: final PrayerCategory category) => _CategoryBody(
          category: category,
          bookmarks: bookmarks,
          showHeader: !isInMasterPane(context),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _CategoryBody extends StatelessWidget {
  const _CategoryBody({
    required this.category,
    required this.bookmarks,
    required this.showHeader,
  });

  final PrayerCategory category;
  final Bookmarks bookmarks;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, showHeader ? 0 : 8, 16, 16),
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('${category.prayerCount} vavaka · Malagasy'),
                const SizedBox(height: 10),
                Text(
                  category.name,
                  style: VavakaText.title.copyWith(color: colors.text),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.dividerStrong),
        ],
        for (final (index, prayer) in category.prayers.indexed) ...[
          if (index > 0) const Divider(height: 1, indent: 8, endIndent: 8),
          PrayerRow(
            prayer: prayer,
            bookmarks: bookmarks,
            onTap: () => openPrayer(context, prayer.id),
          ),
        ],
      ],
    );
  }
}
