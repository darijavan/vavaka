import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../data/models/prayer_category.dart';
import '../data/prayer_lists.dart';
import '../data/prayer_repository.dart';
import '../theme.dart';
import '../widgets/error_message.dart';
import '../widgets/prayer_row.dart';
import '../widgets/section_label.dart';
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

    return Scaffold(
      appBar: VavakaAppBar(
        leading: BackAction(onPressed: () => Navigator.maybePop(context)),
      ),
      body: switch (snapshot) {
        AsyncSnapshot(:final error?) => ErrorMessage(error: error),
        AsyncSnapshot(data: final PrayerCategory category) => _CategoryBody(
          category: category,
          bookmarks: bookmarks,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _CategoryBody extends StatelessWidget {
  const _CategoryBody({required this.category, required this.bookmarks});

  final PrayerCategory category;
  final Bookmarks bookmarks;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
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
        for (final (index, prayer) in category.prayers.indexed) ...[
          if (index > 0) const Divider(height: 1, indent: 8, endIndent: 8),
          PrayerRow(
            prayer: prayer,
            bookmarks: bookmarks,
            onTap: () => context.push('/prayers/${prayer.id}'),
          ),
        ],
      ],
    );
  }
}
