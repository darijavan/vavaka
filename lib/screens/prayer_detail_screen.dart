import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../data/bookmark_store.dart';
import '../data/font_size_store.dart';
import '../data/models/prayer.dart';
import '../data/prayer_repository.dart';
import '../data/prayer_sharer.dart';
import '../widgets/error_message.dart';

class PrayerDetailScreen extends HookWidget {
  const PrayerDetailScreen({
    super.key,
    required this.repository,
    required this.bookmarkStore,
    required this.fontSizeStore,
    this.prayerSharer = const PlatformPrayerSharer(),
    required this.prayerId,
  });

  final PrayerRepository repository;
  final BookmarkStore bookmarkStore;
  final FontSizeStore fontSizeStore;
  final PrayerSharer prayerSharer;
  final String prayerId;

  static const _fontSizeStep = 2.0;

  @override
  Widget build(BuildContext context) {
    final fontSize = useState<double?>(null);
    final isBookmarked = useState<bool?>(null);
    final isSavingBookmark = useState(false);
    final isSharing = useState(false);
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
    useEffect(() {
      var active = true;
      fontSizeStore.loadFontSize().then((value) {
        if (active) {
          fontSize.value = value;
        }
      });
      return () => active = false;
    }, [fontSizeStore]);

    return FutureBuilder<Prayer?>(
      future: future,
      builder: (context, snapshot) {
        final prayer = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(prayer?.title ?? 'Vavaka'),
            actions: [
              IconButton(
                tooltip: 'Share prayer',
                onPressed: prayer == null || isSharing.value
                    ? null
                    : () async {
                        isSharing.value = true;
                        try {
                          await prayerSharer.share(
                            [
                              prayer.title,
                              prayer.author,
                              ...prayer.paragraphs,
                            ].join('\n\n'),
                          );
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not share prayer.'),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            isSharing.value = false;
                          }
                        }
                      },
                icon: const Icon(Icons.share),
              ),
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
                        try {
                          await bookmarkStore.setBookmarked(
                            prayerId,
                            bookmarked: nextValue,
                          );
                          if (context.mounted) {
                            isBookmarked.value = nextValue;
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not update bookmark.'),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            isSavingBookmark.value = false;
                          }
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
                  onPressed:
                      prayer != null &&
                          fontSize.value != null &&
                          fontSize.value! > FontSizeStore.minimumFontSize
                      ? () {
                          final nextValue = fontSize.value! - _fontSizeStep;
                          fontSize.value = nextValue;
                          fontSizeStore.saveFontSize(nextValue);
                        }
                      : null,
                  icon: const Icon(Icons.text_decrease),
                ),
                IconButton(
                  tooltip: 'Increase text size',
                  onPressed:
                      prayer != null &&
                          fontSize.value != null &&
                          fontSize.value! < FontSizeStore.maximumFontSize
                      ? () {
                          final nextValue = fontSize.value! + _fontSizeStep;
                          fontSize.value = nextValue;
                          fontSizeStore.saveFontSize(nextValue);
                        }
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
    required double? fontSize,
  }) {
    if (snapshot.hasError) {
      return ErrorMessage(error: snapshot.error!);
    }
    if (!snapshot.hasData || fontSize == null) {
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
