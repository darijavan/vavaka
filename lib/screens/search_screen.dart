import 'dart:async';

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

class SearchScreen extends HookWidget {
  const SearchScreen({
    super.key,
    required this.repository,
    required this.bookmarks,
  });

  final PrayerRepository repository;
  final Bookmarks bookmarks;

  @override
  Widget build(BuildContext context) {
    final query = useState('');
    final debouncedQuery = useState('');
    final snapshot = useFuture(
      useMemoized(repository.loadCategories, [repository]),
    );
    useEffect(() {
      final timer = Timer(
        const Duration(milliseconds: 300),
        () => debouncedQuery.value = query.value,
      );
      return timer.cancel;
    }, [query.value]);
    final colors = VavakaColors.of(context);

    return Scaffold(
      appBar: VavakaAppBar(
        leading: BackAction(onPressed: () => Navigator.maybePop(context)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              style: VavakaText.callout.copyWith(color: colors.text),
              decoration: InputDecoration(
                hintText: 'Search prayers',
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(Icons.search, color: colors.textMuted),
                filled: true,
                fillColor: colors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => query.value = value,
            ),
          ),
          Expanded(
            child: switch (snapshot) {
              AsyncSnapshot(:final error?) => ErrorMessage(error: error),
              AsyncSnapshot(data: final List<PrayerCategory> categories) =>
                _Results(
                  categories: categories,
                  bookmarks: bookmarks,
                  query: debouncedQuery.value.trim().toLowerCase(),
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.categories,
    required this.bookmarks,
    required this.query,
  });

  final List<PrayerCategory> categories;
  final Bookmarks bookmarks;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a word or phrase to search prayers.'),
      );
    }

    final matches = [
      for (final category in categories)
        for (final prayer in category.prayers)
          if (prayer.title.toLowerCase().contains(query) ||
              prayer.author.toLowerCase().contains(query) ||
              prayer.plainText.toLowerCase().contains(query))
            (prayer, category.name),
    ];
    if (matches.isEmpty) {
      return const Center(child: Text('No prayers found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: matches.length + 1,
      separatorBuilder: (context, index) => index == 0
          ? const SizedBox(height: 8)
          : const Divider(height: 1, indent: 8, endIndent: 8),
      itemBuilder: (context, index) {
        if (index == 0) return SectionLabel('Valiny ${matches.length}');
        final (prayer, categoryName) = matches[index - 1];
        return PrayerRow(
          prayer: prayer,
          bookmarks: bookmarks,
          categoryName: categoryName,
          highlight: query,
          onTap: () => openPrayer(context, prayer.id),
        );
      },
    );
  }
}
