import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/data/prayer_repository.dart';

class _ThrowOnceAssetBundle extends CachingAssetBundle {
  var _loadCount = 0;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (_loadCount++ == 0) {
      throw StateError('First load fails');
    }
    return rootBundle.loadString(key, cache: cache);
  }
}

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

    test('finds a category by its stable recovered slug', () async {
      final category = await PrayerRepository().findCategoryBySlug('ankizy');

      expect(category.name, 'Ankizy');
      expect(category.prayerCount, 5);
      expect(category.prayers.first.id, 'ankizy-01');
    });

    test('finds a prayer by its stable recovered ID', () async {
      final prayer = await PrayerRepository().findPrayerById('ankizy-01');

      expect(prayer, isNotNull);
      expect(prayer!.category, 'ankizy');
      expect(prayer.author, "'Abdu'l-Bahá");
      expect(prayer.paragraphs, hasLength(2));
    });

    test('retries category loading after an initial asset failure', () async {
      final repository = PrayerRepository(assetBundle: _ThrowOnceAssetBundle());

      await expectLater(repository.loadCategories(), throwsStateError);

      expect(await repository.loadCategories(), hasLength(28));
    });
  });
}
