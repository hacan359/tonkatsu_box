import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/genre_cloud/facet.dart';
import 'package:tonkatsu_box/features/genre_cloud/facet_value.dart';
import 'package:tonkatsu_box/features/genre_cloud/genre_cloud_layout.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

FacetValue _w(String label, int count) => FacetValue(
      facet: Facet.genre,
      label: label,
      count: count,
      type: MediaType.game,
    );

// Deterministic stand-in for real text metrics: width scales with label length
// and font size, height with font size. Keeps the layout test font-independent.
Size _fakeMeasure(FacetValue word, double fontSize) =>
    Size(word.label.length * fontSize * 0.5, fontSize * 1.2);

void main() {
  group('rotatedAtIndex', () {
    test('keeps the most frequent word horizontal', () {
      expect(rotatedAtIndex(0), isFalse);
    });

    test('rotates roughly every third word', () {
      expect(rotatedAtIndex(1), isTrue);
      expect(rotatedAtIndex(2), isFalse);
      expect(rotatedAtIndex(3), isFalse);
      expect(rotatedAtIndex(4), isTrue);
    });
  });

  group('layoutGenreCloud', () {
    test('returns empty layout for no words', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: const <FacetValue>[],
        canvasSize: const Size(500, 500),
        measure: _fakeMeasure,
      );
      expect(layout.isEmpty, isTrue);
      expect(layout.hidden, 0);
    });

    test('returns empty layout for a zero-area canvas', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[_w('Action', 5)],
        canvasSize: Size.zero,
        measure: _fakeMeasure,
      );
      expect(layout.isEmpty, isTrue);
    });

    test('places a single word at the canvas centre', () {
      const Size canvas = Size(400, 300);
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[_w('Action', 5)],
        canvasSize: canvas,
        measure: _fakeMeasure,
      );
      expect(layout.placed, hasLength(1));
      final PlacedWord placed = layout.placed.first;
      expect(placed.center.dx, closeTo(canvas.width / 2, 0.001));
      expect(placed.center.dy, closeTo(canvas.height / 2, 0.001));
      expect(layout.hidden, 0);
    });

    test('places every word when they fit', () {
      final List<FacetValue> words = <FacetValue>[
        _w('Action', 50),
        _w('RPG', 40),
        _w('Indie', 30),
        _w('Shooter', 20),
        _w('Puzzle', 10),
      ];
      final GenreCloudLayout layout = layoutGenreCloud(
        words: words,
        canvasSize: const Size(1600, 1200),
        measure: _fakeMeasure,
      );
      expect(layout.placed, hasLength(words.length));
      expect(layout.hidden, 0);
    });

    test('font size grows with frequency', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[
          _w('Big', 100),
          _w('Mid', 50),
          _w('Small', 5),
        ],
        canvasSize: const Size(1600, 1200),
        measure: _fakeMeasure,
      );
      expect(
        layout.placed.first.fontSize,
        greaterThan(layout.placed.last.fontSize),
      );
    });

    test('biggest word stays horizontal, the next is rotated', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[
          _w('Big', 100),
          _w('Second', 80),
          _w('Third', 60),
        ],
        canvasSize: const Size(1600, 1200),
        measure: _fakeMeasure,
      );
      expect(layout.placed[0].rotated, isFalse);
      expect(layout.placed[1].rotated, isTrue);
    });

    test('clustered but unequal counts still get distinct sizes', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[_w('A', 50), _w('B', 49), _w('C', 48)],
        canvasSize: const Size(4000, 3000),
        measure: _fakeMeasure,
        minFontSize: 10,
        maxFontSize: 110,
      );
      final Set<double> sizes =
          layout.placed.map((PlacedWord w) => w.fontSize).toSet();
      expect(sizes, hasLength(3));
      final double top =
          layout.placed.map((PlacedWord w) => w.fontSize).reduce(math.max);
      final double bottom =
          layout.placed.map((PlacedWord w) => w.fontSize).reduce(math.min);
      expect(top / bottom, greaterThan(3));
    });

    test('equal counts share the same size', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[_w('A', 50), _w('B', 50), _w('C', 10)],
        canvasSize: const Size(4000, 3000),
        measure: _fakeMeasure,
        minFontSize: 10,
        maxFontSize: 110,
      );
      final double a = layout.placed
          .firstWhere((PlacedWord w) => w.word.label == 'A')
          .fontSize;
      final double b = layout.placed
          .firstWhere((PlacedWord w) => w.word.label == 'B')
          .fontSize;
      final double c = layout.placed
          .firstWhere((PlacedWord w) => w.word.label == 'C')
          .fontSize;
      expect(a, b);
      expect(a, isNot(c));
    });

    test('reports hidden words when nothing fits the canvas', () {
      final GenreCloudLayout layout = layoutGenreCloud(
        words: <FacetValue>[_w('Adventure', 5)],
        canvasSize: const Size(40, 40),
        measure: _fakeMeasure,
      );
      expect(layout.placed, isEmpty);
      expect(layout.hidden, 1);
    });
  });
}
