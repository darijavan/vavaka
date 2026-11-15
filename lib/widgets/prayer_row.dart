import 'package:flutter/material.dart';

import '../copy.dart';
import '../data/models/prayer.dart';
import '../data/prayer_lists.dart';
import '../theme.dart';
import 'split_view.dart';

/// Prayer list row: title, "author · N teny" metadata and a bookmark star.
class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.prayer,
    required this.bookmarks,
    required this.onTap,
    this.categoryName,
    this.highlight = '',
  });

  final Prayer prayer;
  final Bookmarks bookmarks;
  final VoidCallback onTap;

  /// Prefixed to the metadata when rows from several categories are mixed.
  final String? categoryName;

  /// Lower-case query to emphasise in the title.
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    final meta = [
      ?categoryName,
      prayer.author,
      '${prayer.wordCount} teny',
    ].join(' · ');

    final selected = PrayerSelection.maybeOf(context)?.value == prayer.id;

    return Material(
      color: selected ? colors.surfaceRaised : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      text: prayer.title,
                      query: highlight,
                      maxLines: 2,
                      style: VavakaText.rowTitle.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VavakaText.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              BookmarkStar(bookmarks: bookmarks, prayerId: prayer.id, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class BookmarkStar extends StatelessWidget {
  const BookmarkStar({
    super.key,
    required this.bookmarks,
    required this.prayerId,
    this.size = 24,
  });

  final Bookmarks bookmarks;
  final String prayerId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return ValueListenableBuilder(
      valueListenable: bookmarks,
      builder: (context, ids, _) {
        final bookmarked = ids?.contains(prayerId) ?? false;
        return IconButton(
          tooltip: bookmarked ? Copy.removeBookmark : Copy.bookmark,
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tight(Size.square(size + 12)),
          padding: EdgeInsets.zero,
          iconSize: size,
          onPressed: ids == null
              ? null
              : () => bookmarks.toggle(prayerId).catchError((Object _) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(Copy.bookmarkFailed)),
                    );
                  }
                }),
          icon: Icon(
            bookmarked ? Icons.star : Icons.star_border,
            color: bookmarked ? colors.accent : colors.textMuted,
          ),
        );
      },
    );
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    var start = 0;
    while (query.isNotEmpty) {
      final match = lowerText.indexOf(query, start);
      if (match == -1) break;
      spans
        ..add(TextSpan(text: text.substring(start, match)))
        ..add(
          TextSpan(
            text: text.substring(match, match + query.length),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      start = match + query.length;
    }
    spans.add(TextSpan(text: text.substring(start)));

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
