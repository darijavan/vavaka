class Prayer {
  Prayer({
    required this.id,
    required this.title,
    required this.category,
    required this.author,
    required this.content,
    this.notes,
    this.transliteration,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      category: _requiredString(json, 'category'),
      author: _requiredString(json, 'author'),
      notes: _optionalString(json, 'notes'),
      transliteration: _optionalString(json, 'transliteration'),
      content: PrayerContent.fromJson(json['content']),
    );
  }

  final String id;
  final String title;
  final String category;
  final String author;
  final String? notes;
  final String? transliteration;
  final PrayerContent content;

  List<String> get paragraphs => content.paragraphs;

  String get plainText => content.plainText;
}

class PrayerContent {
  PrayerContent({required this.schema, required List<String> paragraphs})
    : paragraphs = List.unmodifiable(paragraphs);

  factory PrayerContent.fromJson(Object? json) {
    final content = _requiredMap(json, 'content');
    final schema = _requiredString(content, 'schema');
    if (schema != 'dast') {
      throw FormatException('Unsupported prayer content schema: $schema');
    }

    final document = _requiredMap(content['document'], 'content.document');
    if (document['type'] != 'root') {
      throw FormatException(
        'Expected content.document.type to be "root", got '
        '${document['type']}.',
      );
    }

    final children = _requiredList(
      document['children'],
      'content.document.children',
    );
    final paragraphs = <String>[];

    for (
      var paragraphIndex = 0;
      paragraphIndex < children.length;
      paragraphIndex++
    ) {
      final paragraph = _requiredMap(
        children[paragraphIndex],
        'content.document.children[$paragraphIndex]',
      );
      if (paragraph['type'] != 'paragraph') {
        throw FormatException(
          'Expected a paragraph at index $paragraphIndex, got '
          '${paragraph['type']}.',
        );
      }

      final spans = _requiredList(
        paragraph['children'],
        'content.document.children[$paragraphIndex].children',
      );
      final buffer = StringBuffer();

      for (var spanIndex = 0; spanIndex < spans.length; spanIndex++) {
        final span = _requiredMap(
          spans[spanIndex],
          'content.document.children[$paragraphIndex].children[$spanIndex]',
        );
        if (span['type'] != 'span') {
          throw FormatException(
            'Expected a span at paragraph $paragraphIndex, index $spanIndex, '
            'got ${span['type']}.',
          );
        }
        buffer.write(_requiredString(span, 'value'));
      }

      final paragraphText = buffer.toString();
      if (paragraphText.isEmpty) {
        throw FormatException('Prayer paragraph $paragraphIndex is empty.');
      }
      paragraphs.add(paragraphText);
    }

    if (paragraphs.isEmpty) {
      throw const FormatException('Prayer content must contain a paragraph.');
    }

    return PrayerContent(schema: schema, paragraphs: paragraphs);
  }

  final String schema;
  final List<String> paragraphs;

  String get plainText => paragraphs.join('\n\n');
}

Map<String, dynamic> _requiredMap(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected $path to be a JSON object.');
  }
  return value;
}

List<dynamic> _requiredList(Object? value, String path) {
  if (value is! List<dynamic>) {
    throw FormatException('Expected $path to be a JSON array.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Expected "$key" to be a non-empty string.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Expected "$key" to be a string or null.');
  }
  return value;
}
