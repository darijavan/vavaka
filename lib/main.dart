import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'data/models/prayer.dart';
import 'data/models/prayer_category.dart';
import 'data/prayer_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository, this.initialLocation = '/'});

  final PrayerRepository? repository;
  final String initialLocation;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PrayerRepository _repository =
      widget.repository ?? PrayerRepository();
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    overridePlatformDefaultLocation: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            CategoryListScreen(repository: _repository),
        routes: [
          GoRoute(
            path: 'categories/:slug',
            builder: (context, state) => CategoryDetailScreen(
              repository: _repository,
              slug: state.pathParameters['slug']!,
            ),
            routes: [
              GoRoute(
                path: 'prayers/:id',
                builder: (context, state) => PrayerDetailScreen(
                  repository: _repository,
                  prayerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vavaka',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: _router,
    );
  }
}

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key, required this.repository});

  final PrayerRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vavaka')),
      body: FutureBuilder<List<PrayerCategory>>(
        future: repository.loadCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorMessage(error: snapshot.error!);
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
      return _ErrorMessage(error: snapshot.error!);
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

class PrayerDetailScreen extends HookWidget {
  const PrayerDetailScreen({
    super.key,
    required this.repository,
    required this.prayerId,
  });

  final PrayerRepository repository;
  final String prayerId;

  static const _minimumFontSize = 14.0;
  static const _maximumFontSize = 32.0;
  static const _fontSizeStep = 2.0;

  @override
  Widget build(BuildContext context) {
    final fontSize = useState(18.0);
    final future = useMemoized(() => repository.findPrayerById(prayerId), [
      repository,
      prayerId,
    ]);
    return FutureBuilder<Prayer?>(
      future: future,
      builder: (context, snapshot) {
        final prayer = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              prayer?.title ?? 'Vavaka',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: _buildBody(snapshot, fontSize: fontSize.value),
          bottomNavigationBar: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Decrease text size',
                  onPressed: prayer != null && fontSize.value > _minimumFontSize
                      ? () => fontSize.value -= _fontSizeStep
                      : null,
                  icon: const Icon(Icons.text_decrease),
                ),
                IconButton(
                  tooltip: 'Increase text size',
                  onPressed: prayer != null && fontSize.value < _maximumFontSize
                      ? () => fontSize.value += _fontSizeStep
                      : null,
                  icon: const Icon(Icons.text_increase),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<Prayer?> snapshot, {
    required double fontSize,
  }) {
    if (snapshot.hasError) {
      return _ErrorMessage(error: snapshot.error!);
    }
    if (!snapshot.hasData) {
      return const Center(child: Text('Loading…'));
    }

    final prayer = snapshot.data;
    if (prayer == null) {
      return const Center(child: Text('Prayer not found.'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(prayer.title, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          prayer.author,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        for (final paragraph in prayer.paragraphs) ...[
          Text(paragraph, style: TextStyle(fontSize: fontSize, height: 1.5)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Could not load prayers: $error'),
      ),
    );
  }
}
