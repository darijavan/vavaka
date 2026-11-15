import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../copy.dart';
import '../data/font_size_store.dart';
import '../data/models/prayer.dart';
import '../data/prayer_lists.dart';
import '../data/prayer_repository.dart';
import '../data/prayer_sharer.dart';
import '../theme.dart';
import '../widgets/error_message.dart';
import '../widgets/prayer_row.dart';
import '../widgets/vavaka_app_bar.dart';

class PrayerDetailScreen extends HookWidget {
  const PrayerDetailScreen({
    super.key,
    required this.repository,
    required this.bookmarks,
    required this.recentPrayers,
    required this.fontSizeStore,
    this.sharedFontSize,
    this.prayerSharer = const PlatformPrayerSharer(),
    required this.prayerId,
    this.embedded = false,
  });

  final PrayerRepository repository;
  final Bookmarks bookmarks;
  final RecentPrayers recentPrayers;
  final FontSizeStore fontSizeStore;
  final ValueNotifier<double?>? sharedFontSize;
  final PrayerSharer prayerSharer;
  final String prayerId;

  /// Shown in the tablet detail pane: no back navigation, category as title.
  final bool embedded;

  static const _fontSizeStep = 2.0;

  @override
  Widget build(BuildContext context) {
    final localFontSize = useState<double?>(null);
    final fontSize = sharedFontSize ?? localFontSize;
    useValueListenable(fontSize);
    final isSharing = useState(false);
    final future = useMemoized(() => repository.findPrayerById(prayerId), [
      repository,
      prayerId,
    ]);
    final snapshot = useFuture(future);
    final prayer = snapshot.data;
    final categoryName = useFuture(
      useMemoized(
        () => prayer == null
            ? Future<String?>.value()
            : repository
                  .findCategoryBySlug(prayer.category)
                  .then<String?>((category) => category.name)
                  .catchError((Object _) => null),
        [prayer],
      ),
    ).data;
    useEffect(() {
      if (prayer != null) recentPrayers.add(prayer.id).ignore();
      return null;
    }, [prayer]);
    useEffect(() {
      if (sharedFontSize != null) return null;
      var active = true;
      fontSizeStore.loadFontSize().then((value) {
        if (active) fontSize.value = value;
      });
      return () => active = false;
    }, [fontSizeStore, sharedFontSize]);

    Future<void> share(Prayer prayer) async {
      isSharing.value = true;
      try {
        await prayerSharer.share(
          [prayer.title, prayer.author, ...prayer.paragraphs].join('\n\n'),
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(Copy.shareFailed)));
        }
      } finally {
        if (context.mounted) isSharing.value = false;
      }
    }

    void changeFontSize(double delta) {
      final nextValue = (fontSize.value! + delta)
          .clamp(FontSizeStore.minimumFontSize, FontSizeStore.maximumFontSize)
          .toDouble();
      fontSize.value = nextValue;
      fontSizeStore.saveFontSize(nextValue);
    }

    final canResize = prayer != null && fontSize.value != null;
    final inset = embedded ? 40.0 : 16.0;
    final colors = VavakaColors.of(context);

    return Scaffold(
      appBar: VavakaAppBar(
        leading: embedded
            ? null
            : BackAction(
                label: categoryName,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(
                        prayer == null ? '/' : '/categories/${prayer.category}',
                      ),
              ),
        title: embedded
            ? Text(
                categoryName == null ? '' : 'Sokajy: $categoryName',
                style: VavakaText.action.copyWith(color: colors.textSecondary),
              )
            : const BrandLockup(),
        actions: [
          if (prayer != null ||
              snapshot.connectionState != ConnectionState.done)
            BookmarkStar(bookmarks: bookmarks, prayerId: prayerId),
          PopupMenuButton<void>(
            tooltip: Copy.moreOptions,
            enabled: prayer != null,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: !isSharing.value,
                onTap: () => share(prayer!),
                child: const ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Zarao'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: switch (snapshot) {
        AsyncSnapshot(:final error?) => ErrorMessage(error: error),
        AsyncSnapshot(connectionState: ConnectionState.done)
            when prayer == null =>
          const Center(child: Text(Copy.prayerNotFound)),
        _ when prayer == null || fontSize.value == null =>
          const SizedBox.shrink(),
        _ => ListView(
          padding: EdgeInsets.fromLTRB(inset, embedded ? 48 : 16, inset, 16),
          children: [_PrayerCard(prayer: prayer, fontSize: fontSize.value!)],
        ),
      },
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(inset, 0, inset, 20),
        child: _FontSizeBar(
          fontSize: fontSize.value,
          onDecrease:
              canResize && fontSize.value! > FontSizeStore.minimumFontSize
              ? () => changeFontSize(-_fontSizeStep)
              : null,
          onIncrease:
              canResize && fontSize.value! < FontSizeStore.maximumFontSize
              ? () => changeFontSize(_fontSizeStep)
              : null,
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.prayer, required this.fontSize});

  final Prayer prayer;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    final paragraphStyle = TextStyle(
      fontFamily: readingFont,
      fontSize: fontSize,
      height: 1.7,
      color: colors.readerText,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, paragraph) in prayer.paragraphs.indexed)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 18),
                child: Text(paragraph, style: paragraphStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '— ${prayer.author}',
                textAlign: TextAlign.right,
                style: VavakaText.attribution.copyWith(color: colors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeBar extends StatelessWidget {
  const _FontSizeBar({
    required this.fontSize,
    required this.onDecrease,
    required this.onIncrease,
  });

  final double? fontSize;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    TextStyle labelStyle(VoidCallback? onPressed) => TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: onPressed == null ? colors.textMuted : colors.text,
    );

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: Copy.decreaseTextSize,
            onPressed: onDecrease,
            icon: Text('A−', style: labelStyle(onDecrease)),
          ),
          Text(
            fontSize?.round().toString() ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.accent,
            ),
          ),
          IconButton(
            tooltip: Copy.increaseTextSize,
            onPressed: onIncrease,
            icon: Text('A+', style: labelStyle(onIncrease)),
          ),
        ],
      ),
    );
  }
}
