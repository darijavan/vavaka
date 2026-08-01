import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'data/bookmark_store.dart';
import 'data/models/prayer.dart';
import 'data/models/prayer_category.dart';
import 'data/prayer_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends HookWidget {
  const MyApp({
    super.key,
    this.repository,
    this.bookmarkStore,
    this.initialLocation = '/',
  });

  final PrayerRepository? repository;
  final BookmarkStore? bookmarkStore;
  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    final resolvedRepository = useMemoized(
      () => repository ?? PrayerRepository(),
      [repository],
    );
    final resolvedBookmarkStore = useMemoized(
      () => bookmarkStore ?? SharedPreferencesBookmarkStore(),
      [bookmarkStore],
    );
    final router = useMemoized(
      () => GoRouter(
        initialLocation: initialLocation,
        overridePlatformDefaultLocation: true,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                CategoryListScreen(repository: resolvedRepository),
            routes: [
              GoRoute(
                path: 'categories/:slug',
                builder: (context, state) => CategoryDetailScreen(
                  repository: resolvedRepository,
                  slug: state.pathParameters['slug']!,
                ),
                routes: [
                  GoRoute(
                    path: 'prayers/:id',
                    builder: (context, state) => PrayerDetailScreen(
                      repository: resolvedRepository,
                      bookmarkStore: resolvedBookmarkStore,
                      prayerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) =>
                SearchScreen(repository: resolvedRepository),
          ),
        ],
      ),
      [resolvedRepository, resolvedBookmarkStore, initialLocation],
    );
    useEffect(() => router.dispose, [router]);

    return MaterialApp.router(
      title: 'Vavaka',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vavaka'),
        actions: [
          IconButton(
            tooltip: 'Search prayers',
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: FutureBuilder<List<PrayerCategory>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorMessage(
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

class SearchScreen extends HookWidget {
  const SearchScreen({super.key, required this.repository});

  final PrayerRepository repository;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final query = useState('');
    final future = useMemoized(repository.loadAllPrayers, [repository]);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search prayers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => query.value = value,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Prayer>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorMessage(error: snapshot.error!);
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Loading…'));
                }

                final normalizedQuery = query.value.trim().toLowerCase();
                if (normalizedQuery.isEmpty) {
                  return const Center(
                    child: Text('Enter a word or phrase to search prayers.'),
                  );
                }

                final matches = snapshot.data!.where((prayer) {
                  return prayer.title.toLowerCase().contains(normalizedQuery) ||
                      prayer.author.toLowerCase().contains(normalizedQuery) ||
                      prayer.plainText.toLowerCase().contains(normalizedQuery);
                }).toList();
                if (matches.isEmpty) {
                  return const Center(child: Text('No prayers found.'));
                }

                return ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final prayer = matches[index];
                    return ListTile(
                      title: Text(prayer.title),
                      subtitle: Text(prayer.author),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(
                        '/categories/${prayer.category}/prayers/${prayer.id}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
    required this.bookmarkStore,
    required this.prayerId,
  });

  final PrayerRepository repository;
  final BookmarkStore bookmarkStore;
  final String prayerId;

  static const _minimumFontSize = 14.0;
  static const _maximumFontSize = 32.0;
  static const _fontSizeStep = 2.0;

  @override
  Widget build(BuildContext context) {
    final fontSize = useState(18.0);
    final isBookmarked = useState<bool?>(null);
    final isSavingBookmark = useState(false);
    final future = useMemoized(() => repository.findPrayerById(prayerId), [
      repository,
      prayerId,
    ]);
    useEffect(() {
      var active = true;
      bookmarkStore.isBookmarked(prayerId).then((value) {
        if (active) {
          isBookmarked.value = value;
        }
      });
      return () => active = false;
    }, [bookmarkStore, prayerId]);

    return FutureBuilder<Prayer?>(
      future: future,
      builder: (context, snapshot) {
        final prayer = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(prayer?.title ?? 'Vavaka'),
            actions: [
              IconButton(
                tooltip: isBookmarked.value == true
                    ? 'Remove bookmark'
                    : 'Bookmark prayer',
                onPressed:
                    prayer == null ||
                        isBookmarked.value == null ||
                        isSavingBookmark.value
                    ? null
                    : () async {
                        final nextValue = !isBookmarked.value!;
                        isSavingBookmark.value = true;
                        await bookmarkStore.setBookmarked(
                          prayerId,
                          bookmarked: nextValue,
                        );
                        if (context.mounted) {
                          isBookmarked.value = nextValue;
                          isSavingBookmark.value = false;
                        }
                      },
                icon: Icon(
                  isBookmarked.value == true
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
              ),
            ],
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

class _ErrorMessage extends HookWidget {
  const _ErrorMessage({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load prayers: $error'),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
