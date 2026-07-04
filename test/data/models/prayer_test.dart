import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/data/models/prayer.dart';

void main() {
  group('Prayer', () {
    test('parses DAST paragraphs without losing boundaries', () {
      final prayer = Prayer.fromJson({
        'id': 'ankizy-01',
        'title': 'Ry Andriamanitro!',
        'category': 'ankizy',
        'author': "'Abdu'l-Bahá",
        'notes': null,
        'transliteration': null,
        'content': {
          'schema': 'dast',
          'document': {
            'type': 'root',
            'children': [
              {
                'type': 'paragraph',
                'children': [
                  {'type': 'span', 'value': 'Andalana voalohany.'},
                ],
              },
              {
                'type': 'paragraph',
                'children': [
                  {'type': 'span', 'value': 'Andalana faharoa.'},
                ],
              },
            ],
          },
        },
      });

      expect(prayer.paragraphs, ['Andalana voalohany.', 'Andalana faharoa.']);
      expect(prayer.plainText, 'Andalana voalohany.\n\nAndalana faharoa.');
    });

    test('rejects unsupported content schemas', () {
      expect(
        () => PrayerContent.fromJson({
          'schema': 'html',
          'document': {'type': 'root', 'children': <Object>[]},
        }),
        throwsFormatException,
      );
    });
  });
}
