import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/screens/settings_screen.dart';

void main() {
  test('settings shows the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });
}
