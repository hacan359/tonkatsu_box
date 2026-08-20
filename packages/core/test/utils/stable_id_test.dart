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

  group('fnv1a53', () {
    // Golden vectors pin the on-disk id contract, same as fnv1a64 above.
    const Map<String, int> golden = <String, int>{
      '': 5239054864097658,
      'OL123': 6020920346270183,
      'a1b2c3d4-e5f6-7890-abcd-ef1234567890': 4413062887020633,
      'Тонкацу': 3709886798302770,
      'hardcover:42': 1537439661777293,
      'b1a9c0e4-1f0e-4c6b-8e2a-77e5b3b9f2f1': 381424520416013,
    };

    test('should match golden vectors', () {
      golden.forEach((String input, int expected) {
        expect(fnv1a53(input), expected, reason: 'input: "$input"');
      });
    });

    test('should produce identical values in the io and web variants', () {
      for (final String input in golden.keys) {
        expect(io.fnv1a53(input), web.fnv1a53(input),
            reason: 'input: "$input"');
      }
    });

    test('should fit a JS double exactly (below 2^53)', () {
      for (final String input in golden.keys) {
        expect(fnv1a53(input), lessThan(1 << 53), reason: 'input: "$input"');
        expect(fnv1a53(input), isNonNegative);
      }
    });
  });
}
