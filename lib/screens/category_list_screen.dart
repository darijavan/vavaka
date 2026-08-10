import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../data/font_size_store.dart';
import '../data/models/prayer_category.dart';
import '../data/prayer_repository.dart';
import '../widgets/error_message.dart';

class CategoryListScreen extends HookWidget {
  const CategoryListScreen({
    super.key,
    required this.repository,
    this.fontSizeStore,
  });

  final PrayerRepository repository;
  final FontSizeStore? fontSizeStore;

  @override
  Widget build(BuildContext context) {
    final retryAttempt = useState(0);
    final future = useMemoized(repository.loadCategories, [
      repository,
      retryAttempt.value,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vavaka'),
        actions: [
          IconButton(
            tooltip: 'Search prayers',
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
          ),
          if (fontSizeStore != null)
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings),
            ),
        ],
      ),
      body: FutureBuilder<List<PrayerCategory>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorMessage(
              error: snapshot.error!,
              onRetry: () => retryAttempt.value++,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Loading…'));
          }

          final categories = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                for (final category in categories) ...[
                  ListTile(
                    title: Text(category.name),
                    subtitle: Text('${category.prayerCount} vavaka'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/categories/${category.slug}'),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
