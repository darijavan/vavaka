import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'data/bookmark_store.dart';
import 'data/font_size_store.dart';
import 'data/prayer_repository.dart';
import 'data/prayer_sharer.dart';
import 'data/theme_mode_store.dart';
import 'screens/category_detail_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/prayer_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';

class MyApp extends HookWidget {
  const MyApp({
    super.key,
    this.repository,
    this.bookmarkStore,
    this.fontSizeStore,
    this.themeModeStore,
    this.prayerSharer,
    this.initialLocation = '/',
  });

  final PrayerRepository? repository;
  final BookmarkStore? bookmarkStore;
  final FontSizeStore? fontSizeStore;
  final ThemeModeStore? themeModeStore;
  final PrayerSharer? prayerSharer;
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
    final resolvedFontSizeStore = useMemoized(
      () => fontSizeStore ?? SharedPreferencesFontSizeStore(),
      [fontSizeStore],
    );
    final resolvedThemeModeStore = useMemoized(
      () => themeModeStore ?? SharedPreferencesThemeModeStore(),
      [themeModeStore],
    );
    final themeMode = useState(ThemeMode.light);
    useEffect(() {
      var active = true;
      resolvedThemeModeStore.loadThemeMode().then((value) {
        if (active) {
          themeMode.value = value;
        }
      });
      return () => active = false;
    }, [resolvedThemeModeStore]);
    final resolvedPrayerSharer = useMemoized(
      () => prayerSharer ?? PlatformPrayerSharer(),
      [prayerSharer],
    );
    final router = useMemoized(
      () => GoRouter(
        initialLocation: initialLocation,
        overridePlatformDefaultLocation: true,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => CategoryListScreen(
              repository: resolvedRepository,
              fontSizeStore: resolvedFontSizeStore,
            ),
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
                      fontSizeStore: resolvedFontSizeStore,
                      prayerSharer: resolvedPrayerSharer,
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
          GoRoute(
            path: '/settings',
            builder: (context, state) => SettingsScreen(
              fontSizeStore: resolvedFontSizeStore,
              themeMode: themeMode.value,
              onThemeModeChanged: (value) {
                themeMode.value = value;
                resolvedThemeModeStore.saveThemeMode(value);
              },
            ),
          ),
        ],
      ),
      [
        resolvedRepository,
        resolvedBookmarkStore,
        resolvedFontSizeStore,
        resolvedThemeModeStore,
        resolvedPrayerSharer,
        initialLocation,
      ],
    );
    useEffect(() => router.dispose, [router]);

    return MaterialApp.router(
      title: 'Vavaka',
      themeMode: themeMode.value,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }
}
