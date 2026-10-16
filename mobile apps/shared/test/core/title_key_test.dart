import 'dart:io';

import 'package:autolinky/core/utils/title_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cases the backend and the SQL rule are checked on (tests/title_key_cases.py): the app gives the same keys.
List<(String, String?)> sharedCases() {
  final source = File('test/fixtures/title_key_cases.py').readAsStringSync();
  final row = RegExp(r'\(\s*"((?:[^"\\]|\\.)*)"(?:\s*\*\s*(\d+))?\s*,\s*(None|"((?:[^"\\]|\\.)*)")\s*\)');
  return [
    for (final m in row.allMatches(source))
      (
        m.group(2) == null ? m.group(1)! : m.group(1)! * int.parse(m.group(2)!),
        m.group(3) == 'None' ? null : m.group(4),
      ),
  ];
}

void main() {
  test('the same keys as the backend and the collector', () {
    final cases = sharedCases();
    expect(cases.length, greaterThan(30));
    for (final (title, key) in cases) {
      expect(titleKey(title), key, reason: title);
    }
  });
}
