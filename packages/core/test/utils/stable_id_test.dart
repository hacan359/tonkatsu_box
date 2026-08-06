import 'package:core/utils/stable_id.dart';
import 'package:core/utils/stable_id_io.dart' as io;
import 'package:core/utils/stable_id_web.dart' as web;
import 'package:test/test.dart';

void main() {
  group('fnv1a64', () {
    // Golden vectors pin the on-disk id contract: a changed hash would break
    // matching against rows written by already-released builds.
    const Map<String, int> golden = <String, int>{
      '': 5472609002491880229,
      'OL123': 7112701132336913138,
      'a1b2c3d4-e5f6-7890-abcd-ef1234567890': 58456258415466591,
      'Тонкацу': 5074763067217480705,
      'hardcover:42': 397854206870380961,
    };

    test('should match golden vectors', () {
      golden.forEach((String input, int expected) {
        expect(fnv1a64(input), expected, reason: 'input: "$input"');
      });
    });

    test('should produce identical values in the io and web variants', () {
      for (final String input in golden.keys) {
        expect(io.fnv1a64(input), web.fnv1a64(input),
            reason: 'input: "$input"');
      }
    });

    test('should stay non-negative for SQLite signed INTEGER', () {
      for (final String input in golden.keys) {
        expect(fnv1a64(input), isNonNegative);
      }
    });
  });
}
