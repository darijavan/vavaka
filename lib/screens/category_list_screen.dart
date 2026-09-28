import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../data/models/prayer_category.dart';
import '../data/prayer_repository.dart';
import '../theme.dart';
import '../widgets/error_message.dart';
import '../widgets/vavaka_app_bar.dart';

class CategoryListScreen extends HookWidget {
  const CategoryListScreen({super.key, required this.repository});

  final PrayerRepository repository;

  @override
  Widget build(BuildContext context) {
    final retryAttempt = useState(0);
    final future = useMemoized(repository.loadCategories, [
      repository,
      retryAttempt.value,
    ]);
    final snapshot = useFuture(future);
    final colors = VavakaColors.of(context);

    return Scaffold(
      appBar: VavakaAppBar(
        leading: IconButton(
          tooltip: 'Settings',
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Search prayers',
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search, size: 22),
          ),
        ],
      ),
      body: switch (snapshot) {
        AsyncSnapshot(:final error?) => ErrorMessage(
          error: error,
          onRetry: () => retryAttempt.value++,
        ),
        AsyncSnapshot(data: final List<PrayerCategory> categories) =>
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 8, endIndent: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () => context.go('/categories/${category.slug}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VavakaText.callout.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${category.prayerCount}',
                        style: VavakaText.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
