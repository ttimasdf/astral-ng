import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English, Chinese, and generated locale keys stay synchronized', () {
    final english = _translationKeys('assets/translations/en.json');
    final chinese = _translationKeys('assets/translations/zh.json');
    final generated =
        RegExp(r"static const \w+ = '([^']+)';")
            .allMatches(
              File('lib/generated/locale_keys.g.dart').readAsStringSync(),
            )
            .map((match) => match.group(1)!)
            .toSet();

    expect(chinese, english, reason: 'English and Chinese keys differ');
    expect(
      generated,
      english,
      reason: 'Regenerate lib/generated/locale_keys.g.dart',
    );
  });
}

Set<String> _translationKeys(String path) {
  final translations = jsonDecode(File(path).readAsStringSync());
  return (translations as Map<String, dynamic>).keys.toSet();
}
