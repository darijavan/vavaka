import 'prayer.dart';

class PrayerCategory {
  PrayerCategory({
    required this.slug,
    required this.name,
    required List<Prayer> prayers,
  }) : prayers = List.unmodifiable(prayers);

  final String slug;
  final String name;
  final List<Prayer> prayers;

  int get prayerCount => prayers.length;
}
