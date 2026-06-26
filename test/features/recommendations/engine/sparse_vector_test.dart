import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/engine/sparse_vector.dart';

void main() {
  group('SparseVector', () {
    group('isEmpty', () {
      test('is true for an empty map and the empty constructor', () {
        expect(const SparseVector(<String, double>{}).isEmpty, isTrue);
        expect(const SparseVector.empty().isEmpty, isTrue);
      });

      test('is false when there is at least one component', () {
        expect(const SparseVector(<String, double>{'a': 1}).isEmpty, isFalse);
      });
    });

    group('norm', () {
      test('is the euclidean length', () {
        expect(
          const SparseVector(<String, double>{'a': 3, 'b': 4}).norm,
          closeTo(5, 1e-9),
        );
      });

      test('is zero for the empty vector', () {
        expect(const SparseVector.empty().norm, 0);
      });
    });

    group('dot', () {
      test('sums the products over shared keys only', () {
        const SparseVector a = SparseVector(<String, double>{'x': 2, 'y': 3});
        const SparseVector b = SparseVector(<String, double>{'y': 4, 'z': 5});
        expect(a.dot(b), 12); // only y: 3 * 4
      });

      test('is zero for disjoint vectors', () {
        const SparseVector a = SparseVector(<String, double>{'x': 1});
        const SparseVector b = SparseVector(<String, double>{'y': 1});
        expect(a.dot(b), 0);
      });

      test('is symmetric regardless of which vector is larger', () {
        const SparseVector a = SparseVector(<String, double>{'x': 2});
        const SparseVector b =
            SparseVector(<String, double>{'x': 3, 'y': 9, 'z': 9});
        expect(a.dot(b), b.dot(a));
      });
    });

    group('cosine', () {
      test('is 1 for a vector with itself', () {
        const SparseVector v = SparseVector(<String, double>{'a': 3, 'b': 4});
        expect(v.cosine(v), closeTo(1, 1e-9));
      });

      test('is 0 for orthogonal vectors', () {
        const SparseVector a = SparseVector(<String, double>{'a': 1});
        const SparseVector b = SparseVector(<String, double>{'b': 1});
        expect(a.cosine(b), 0);
      });

      test('is -1 for opposite vectors', () {
        const SparseVector a = SparseVector(<String, double>{'a': 1});
        const SparseVector b = SparseVector(<String, double>{'a': -1});
        expect(a.cosine(b), closeTo(-1, 1e-9));
      });

      test('is 0 when either vector is all-zero', () {
        const SparseVector v = SparseVector(<String, double>{'a': 1});
        expect(v.cosine(const SparseVector.empty()), 0);
        expect(const SparseVector.empty().cosine(v), 0);
      });
    });

    group('normalized', () {
      test('returns a unit-norm copy', () {
        final SparseVector n =
            const SparseVector(<String, double>{'a': 3, 'b': 4}).normalized();
        expect(n.norm, closeTo(1, 1e-9));
        expect(n.values['a'], closeTo(0.6, 1e-9));
        expect(n.values['b'], closeTo(0.8, 1e-9));
      });

      test('returns the empty vector when all-zero', () {
        expect(const SparseVector.empty().normalized().isEmpty, isTrue);
      });
    });

    group('weightedSum', () {
      test('accumulates each vector scaled by its weight', () {
        final SparseVector sum = SparseVector.weightedSum(
          <SparseVector>[
            const SparseVector(<String, double>{'a': 1}),
            const SparseVector(<String, double>{'a': 1, 'b': 1}),
          ],
          <double>[2, 3],
        );
        expect(sum.values['a'], closeTo(5, 1e-9)); // 1*2 + 1*3
        expect(sum.values['b'], closeTo(3, 1e-9)); // 1*3
      });

      test('returns an empty vector for empty input', () {
        expect(
          SparseVector.weightedSum(<SparseVector>[], <double>[]).isEmpty,
          isTrue,
        );
      });

      test('normalizing the weighted sum yields a unit vector', () {
        final SparseVector sum = SparseVector.weightedSum(
          <SparseVector>[const SparseVector(<String, double>{'a': 1, 'b': 1})],
          <double>[2],
        ).normalized();
        expect(sum.norm, closeTo(1, 1e-9));
        expect(sum.values['a'], closeTo(1 / math.sqrt(2), 1e-9));
      });
    });
  });
}
