import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every locale file must carry exactly the template's key set with matching
// placeholders, so a translation MR cannot silently drop or misspell a key.
void main() {
  final Directory l10nDir = Directory('lib/l10n');
  final List<File> arbFiles = l10nDir
      .listSync()
      .whereType<File>()
      .where((File f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
      .toList();

  final Map<String, Map<String, dynamic>> byLocale = <String, Map<String, dynamic>>{
    for (final File f in arbFiles)
      f.uri.pathSegments.last:
          json.decode(f.readAsStringSync()) as Map<String, dynamic>,
  };

  Set<String> keysOf(Map<String, dynamic> arb) =>
      arb.keys.where((String k) => !k.startsWith('@')).toSet();

  // Read from the template's @key metadata: ICU plural branch text like
  // `=1{day}` is indistinguishable from a placeholder by syntax alone.
  Set<String> declaredPlaceholders(Map<String, dynamic> arb, String key) {
    final Object? meta = arb['@$key'];
    if (meta is! Map<String, dynamic>) return <String>{};
    final Object? placeholders = meta['placeholders'];
    return placeholders is Map<String, dynamic>
        ? placeholders.keys.toSet()
        : <String>{};
  }

  group('ARB parity', () {
    test('template and locale files are present', () {
      expect(byLocale.keys, contains('app_en.arb'));
      expect(byLocale.length, greaterThanOrEqualTo(2));
    });

    test('every locale has exactly the template key set', () {
      final Set<String> template = keysOf(byLocale['app_en.arb']!);
      for (final MapEntry<String, Map<String, dynamic>> e
          in byLocale.entries) {
        final Set<String> keys = keysOf(e.value);
        expect(template.difference(keys), isEmpty,
            reason: '${e.key} is missing keys present in app_en.arb');
        expect(keys.difference(template), isEmpty,
            reason: '${e.key} has keys absent from app_en.arb');
      }
    });

    test('every declared placeholder is used in every locale', () {
      final Map<String, dynamic> en = byLocale['app_en.arb']!;
      for (final String key in keysOf(en)) {
        final Set<String> declared = declaredPlaceholders(en, key);
        if (declared.isEmpty) continue;
        for (final MapEntry<String, Map<String, dynamic>> e
            in byLocale.entries) {
          final Object? value = e.value[key];
          expect(value, isA<String>(),
              reason: '"$key" is not a string in ${e.key}');
          for (final String name in declared) {
            expect(RegExp('\\{$name\\b').hasMatch(value! as String), isTrue,
                reason: '"$key" in ${e.key} does not use {$name}');
          }
        }
      }
    });

    test('metadata entries refer to existing keys', () {
      for (final MapEntry<String, Map<String, dynamic>> e
          in byLocale.entries) {
        final Set<String> keys = keysOf(e.value);
        final Iterable<String> metaKeys = e.value.keys.where(
            (String k) => k.startsWith('@') && !k.startsWith('@@'));
        for (final String meta in metaKeys) {
          expect(keys, contains(meta.substring(1)),
              reason: '$meta in ${e.key} has no matching key');
        }
      }
    });
  });
}
