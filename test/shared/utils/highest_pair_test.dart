import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/utils/highest_pair.dart';

void main() {
  group('highestPair', () {
    test('returns null for an empty input', () {
      expect(highestPair(const <(int, int)>[]), isNull);
    });

    test('picks the highest fine number within one coarse group', () {
      expect(highestPair(const <(int, int)>[(1, 2), (1, 7), (1, 4)]), (1, 7));
    });

    test('a later coarse number beats a higher fine one', () {
      expect(highestPair(const <(int, int)>[(1, 12), (2, 1)]), (2, 1));
    });
  });
}
