import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'data/bookmark_store.dart';
import 'data/font_size_store.dart';
import 'data/prayer_lists.dart';
import 'data/prayer_repository.dart';
import 'data/prayer_sharer.dart';
import 'data/recent_store.dart';
import 'data/theme_mode_store.dart';
import 'screens/category_detail_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/prayer_detail_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/saved_prayers_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';
import 'widgets/vavaka_tab_bar.dart';

class MyApp extends HookWidget {
  const MyApp({
    super.key,
    this.repository,
    this.bookmarkStore,
    this.recentStore,
    this.fontSizeStore,
    this.themeModeStore,
    this.prayerSharer,
    this.initialLocation = '/',
  });

  final PrayerRepository? repository;
  final BookmarkStore? bookmarkStore;
  final RecentStore? recentStore;
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
    final bookmarks = useMemoized(
      () => Bookmarks(bookmarkStore ?? SharedPreferencesBookmarkStore()),
      [bookmarkStore],
    );
    useEffect(() => bookmarks.dispose, [bookmarks]);
    final recentPrayers = useMemoized(
      () => RecentPrayers(recentStore ?? SharedPreferencesRecentStore()),
      [recentStore],
    );
    useEffect(() => recentPrayers.dispose, [recentPrayers]);
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
        if (active) themeMode.value = value;
      });
      return () => active = false;
    }, [resolvedThemeModeStore]);
    final resolvedPrayerSharer = useMemoized(
      () => prayerSharer ?? const PlatformPrayerSharer(),
      [prayerSharer],
    );
    final router = useMemoized(
      () => GoRouter(
        initialLocation: initialLocation,
        overridePlatformDefaultLocation: true,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(
              body: shell,
              bottomNavigationBar: VavakaTabBar(
                currentIndex: shell.currentIndex,
                onSelected: (index) => shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                ),
              ),
            ),
            branches: [
              StatefulShellBranch(
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
                          bookmarks: bookmarks,
                          slug: state.pathParameters['slug']!,
                        ),
                      ),
                      GoRoute(
                        path: 'search',
                        builder: (context, state) => SearchScreen(
                          repository: resolvedRepository,
                          bookmarks: bookmarks,
                        ),
                      ),
                      GoRoute(
                        path: 'settings',
                        builder: (context, state) => SettingsScreen(
                          fontSizeStore: resolvedFontSizeStore,
                          themeMode: themeMode,
                          onThemeModeChanged: (value) {
                            themeMode.value = value;
                            resolvedThemeModeStore.saveThemeMode(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/favorites',
                    builder: (context, state) => FavoritesScreen(
                      repository: resolvedRepository,
                      bookmarks: bookmarks,
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/recent',
                    builder: (context, state) => RecentScreen(
                      repository: resolvedRepository,
                      bookmarks: bookmarks,
                      recentPrayers: recentPrayers,
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/reminders',
                    builder: (context, state) => const RemindersScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Outside the shell: the reader replaces the tab bar with its own
          // font-size bar, as in the Figma "Prayer Reader" frames.
          GoRoute(
            path: '/prayers/:id',
            builder: (context, state) => PrayerDetailScreen(
              repository: resolvedRepository,
              bookmarks: bookmarks,
              recentPrayers: recentPrayers,
              fontSizeStore: resolvedFontSizeStore,
              prayerSharer: resolvedPrayerSharer,
              prayerId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      [
        resolvedRepository,
        bookmarks,
        recentPrayers,
        resolvedFontSizeStore,
        resolvedThemeModeStore,
        resolvedPrayerSharer,
        initialLocation,
      ],
    );
    useEffect(() => router.dispose, [router]);
    final lightTheme = useMemoized(() => buildVavakaTheme(Brightness.light));
    final darkTheme = useMemoized(() => buildVavakaTheme(Brightness.dark));

    return MaterialApp.router(
      title: 'Vavaka',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode.value,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: router,
    );
  }
}
