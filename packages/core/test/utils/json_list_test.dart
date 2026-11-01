import 'package:core/utils/json_list.dart';
import 'package:test/test.dart';

void main() {
  group('decodeJsonStringList', () {
    test('decodes a JSON array and tolerates junk', () {
      expect(decodeJsonStringList('["a","b"]'), <String>['a', 'b']);
      expect(decodeJsonStringList('not json'), isEmpty);
      expect(decodeJsonStringList(null), isEmpty);
      expect(decodeJsonStringList('{"a":1}'), isEmpty);
    });
  });

  group('decodeJsonStringListOrNull', () {
    test('is null for absent or empty lists', () {
      expect(decodeJsonStringListOrNull(null), isNull);
      expect(decodeJsonStringListOrNull('[]'), isNull);
      expect(decodeJsonStringListOrNull('["a"]'), <String>['a']);
    });
  });

  group('encodeJsonStringList', () {
    test('is null for null and empty, JSON otherwise', () {
      expect(encodeJsonStringList(null), isNull);
      expect(encodeJsonStringList(<String>[]), isNull);
      expect(encodeJsonStringList(<String>['a']), '["a"]');
    });
  });

  group('distinctNames', () {
    test('trims, drops blanks and non-strings, keeps first order', () {
      expect(
        distinctNames(<Object?>[' b ', 'a', '', null, 3, 'b']),
        <String>['b', 'a'],
      );
    });

    test('is null when nothing is left', () {
      expect(distinctNames(<Object?>[]), isNull);
      expect(distinctNames(<Object?>['  ', null]), isNull);
    });
  });

  group('distinctEntryNames', () {
    test('reads the name of each map entry', () {
      expect(
        distinctEntryNames(<dynamic>[
          <String, dynamic>{'name': 'HBO'},
          'skip',
          <String, dynamic>{'name': 'HBO'},
          <String, dynamic>{'id': 1},
        ]),
        <String>['HBO'],
      );
    });

    test('is null for a non-list', () {
      expect(distinctEntryNames(null), isNull);
      expect(distinctEntryNames(<String, dynamic>{}), isNull);
    });
  });
}
