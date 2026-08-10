import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../data/models/prayer.dart';
import '../data/prayer_repository.dart';
import '../widgets/error_message.dart';

class SearchScreen extends HookWidget {
  const SearchScreen({super.key, required this.repository});

  final PrayerRepository repository;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final query = useState('');
    final debouncedQuery = useState('');
    final future = useMemoized(repository.loadAllPrayers, [repository]);
    useEffect(() {
      final timer = Timer(
        const Duration(milliseconds: 300),
        () => debouncedQuery.value = query.value,
      );
      return timer.cancel;
    }, [query.value]);

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
                  return ErrorMessage(error: snapshot.error!);
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Loading…'));
                }

                final normalizedQuery = debouncedQuery.value
                    .trim()
                    .toLowerCase();
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
                      title: _HighlightedText(
                        text: prayer.title,
                        query: normalizedQuery,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HighlightedText(
                            text: prayer.author,
                            query: normalizedQuery,
                          ),
                          _HighlightedText(
                            text: prayer.plainText,
                            query: normalizedQuery,
                            maxLines: 2,
                          ),
                        ],
                      ),
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

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.maxLines,
  });

  final String text;
  final String query;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final normalizedText = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final match = normalizedText.indexOf(query, start);
      if (match == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (match > start) {
        spans.add(TextSpan(text: text.substring(start, match)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match, match + query.length),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = match + query.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
