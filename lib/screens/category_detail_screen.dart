import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../data/models/prayer_category.dart';
import '../data/prayer_repository.dart';
import '../widgets/error_message.dart';

class CategoryDetailScreen extends HookWidget {
  const CategoryDetailScreen({
    super.key,
    required this.repository,
    required this.slug,
  });

  final PrayerRepository repository;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(() => repository.findCategoryBySlug(slug), [
      repository,
      slug,
    ]);
    return FutureBuilder<PrayerCategory>(
      future: future,
      builder: (context, snapshot) {
        final title = snapshot.data?.name ?? 'Vavaka';
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: _buildBody(context, snapshot),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<PrayerCategory> snapshot,
  ) {
    if (snapshot.hasError) {
      return ErrorMessage(error: snapshot.error!);
    }
    if (!snapshot.hasData) {
      return const Center(child: Text('Loading…'));
    }

    final category = snapshot.data!;
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final prayer in category.prayers) ...[
            ListTile(
              title: Text(prayer.title),
              subtitle: Text(prayer.author),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/categories/$slug/prayers/${prayer.id}'),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
