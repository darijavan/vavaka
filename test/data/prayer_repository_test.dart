import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/data/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerRepository', () {
    test('loads every recovered category and prayer asset', () async {
      final categories = await PrayerRepository().loadCategories();
      final prayers = categories
          .expand((category) => category.prayers)
          .toList();

      expect(categories, hasLength(28));
      expect(prayers, hasLength(95));
      expect(categories.first.slug, 'andro-manelanelana');
      expect(categories.first.prayerCount, 1);
      expect(categories[1].slug, 'ankizy');
      expect(categories[1].prayerCount, 5);
    });

    test('keeps IDs unique and prayer paragraphs populated', () async {
      final prayers = await PrayerRepository().loadAllPrayers();
      final ids = prayers.map((prayer) => prayer.id).toSet();

      expect(ids, hasLength(prayers.length));
      for (final prayer in prayers) {
        expect(prayer.paragraphs, isNotEmpty, reason: prayer.id);
        expect(prayer.paragraphs, everyElement(isNotEmpty), reason: prayer.id);
      }
    });

    test('finds a prayer by its stable recovered ID', () async {
      final prayer = await PrayerRepository().findPrayerById('ankizy-01');

      expect(prayer, isNotNull);
      expect(prayer!.category, 'ankizy');
      expect(prayer.author, "'Abdu'l-Bahá");
      expect(prayer.paragraphs, hasLength(2));
    });
  });
}
