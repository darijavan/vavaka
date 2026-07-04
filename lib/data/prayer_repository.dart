import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/prayer.dart';
import 'models/prayer_category.dart';

class PrayerRepository {
  PrayerRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  static const indexAssetPath = 'data/index.json';

  final AssetBundle _assetBundle;

  Future<List<PrayerCategory>> loadCategories() async {
    final indexJson = await _loadJson(indexAssetPath);
    if (indexJson is! Map<String, dynamic>) {
      throw const FormatException('Prayer index must be a JSON object.');
    }

    final categoriesJson = indexJson['categories'];
    if (categoriesJson is! List<dynamic>) {
      throw const FormatException(
        'Prayer index must contain a categories array.',
      );
    }

    final categories = await Future.wait(
      List.generate(
        categoriesJson.length,
        (index) => _loadCategory(index, categoriesJson[index]),
      ),
    );

    return List.unmodifiable(categories);
  }

  Future<List<Prayer>> loadAllPrayers() async {
    final categories = await loadCategories();
    return List.unmodifiable(categories.expand((category) => category.prayers));
  }

  Future<Prayer?> findPrayerById(String id) async {
    final prayers = await loadAllPrayers();
    for (final prayer in prayers) {
      if (prayer.id == id) {
        return prayer;
      }
    }
    return null;
  }

  Future<PrayerCategory> _loadCategory(int index, Object? json) async {
    final categoryJson = _requiredMap(json, 'categories[$index]');
    final slug = _requiredString(categoryJson, 'category');
    final name = _requiredString(categoryJson, 'name');
    final categoryNumber = (index + 1).toString().padLeft(2, '0');
    final assetPath = 'data/$categoryNumber-$slug/prayers.json';

    final prayersJson = await _loadJson(assetPath);
    if (prayersJson is! List<dynamic>) {
      throw FormatException('$assetPath must contain a JSON array.');
    }

    final prayers = prayersJson
        .map((entry) {
          final prayer = Prayer.fromJson(_requiredMap(entry, assetPath));
          if (prayer.category != slug) {
            throw FormatException(
              'Prayer ${prayer.id} belongs to ${prayer.category}, expected $slug.',
            );
          }
          return prayer;
        })
        .toList(growable: false);

    _validateIndexEntries(categoryJson, prayers, assetPath);

    return PrayerCategory(slug: slug, name: name, prayers: prayers);
  }

  void _validateIndexEntries(
    Map<String, dynamic> categoryJson,
    List<Prayer> prayers,
    String assetPath,
  ) {
    final summaries = categoryJson['prayers'];
    if (summaries is! List<dynamic>) {
      throw FormatException('Index entry for $assetPath has no prayers array.');
    }
    if (summaries.length != prayers.length) {
      throw FormatException(
        'Index lists ${summaries.length} prayers for $assetPath, but the asset '
        'contains ${prayers.length}.',
      );
    }

    for (var index = 0; index < summaries.length; index++) {
      final summary = _requiredMap(summaries[index], 'index prayer $index');
      final summaryId = _requiredString(summary, 'id');
      if (summaryId != prayers[index].id) {
        throw FormatException(
          'Index prayer $summaryId does not match ${prayers[index].id} in '
          '$assetPath.',
        );
      }
    }
  }

  Future<Object?> _loadJson(String assetPath) async {
    final source = await _assetBundle.loadString(assetPath);
    try {
      return jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid JSON in $assetPath: ${error.message}');
    }
  }
}

Map<String, dynamic> _requiredMap(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected $path to be a JSON object.');
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
