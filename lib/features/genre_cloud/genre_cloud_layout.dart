// Pure word-cloud layout: places facet words on a canvas with no overlaps.
//
// Kept free of Flutter widget code so it can be unit-tested with an injected
// text measurement function. Words are placed largest-first along an
// Archimedean spiral; if not everything fits, the size scale is shrunk and the
// layout is retried (auto-fit). Whatever still cannot be placed is reported via
// [hidden].

import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'facet_value.dart';

/// Measures the unrotated pixel size of [word] rendered at [fontSize]
/// (including any count suffix the renderer draws).
typedef MeasureWord = Size Function(FacetValue word, double fontSize);

/// A facet word positioned on the cloud canvas.
class PlacedWord {
  /// Creates a [PlacedWord].
  const PlacedWord({
    required this.word,
    required this.fontSize,
    required this.center,
    required this.rotated,
  });

  /// The facet value this word represents.
  final FacetValue word;

  /// Font size the word is drawn at.
  final double fontSize;

  /// Centre of the word's bounding box, in canvas coordinates.
  final Offset center;

  /// Whether the word is rotated 90° (drawn vertically).
  final bool rotated;
}

/// Result of laying out a cloud.
class GenreCloudLayout {
  /// Creates a [GenreCloudLayout].
  const GenreCloudLayout({
    required this.placed,
    required this.hidden,
    required this.size,
  });

  /// Words that were placed, in descending frequency order.
  final List<PlacedWord> placed;

  /// How many words could not be placed (safeguard for pathological inputs).
  final int hidden;

  /// Canvas size the layout was computed for.
  final Size size;

  /// Whether nothing was placed.
  bool get isEmpty => placed.isEmpty;
}

/// Largest font tried before auto-fit shrinking, and the floor it shrinks to.
const double _defaultMaxFontSize = 64;
const double _defaultMinFontSize = 13;

/// Maximum number of distinct size tiers.
///
/// Sizing is rank-based: words are sized by where their *count* ranks among the
/// distinct counts, not by the raw count. Equal counts share a size; any
/// difference in count moves a word to a different tier. When there are more
/// distinct counts than this cap, adjacent ranks are grouped so the geometric
/// step between tiers stays clearly visible instead of collapsing.
const int _defaultMaxTiers = 10;

/// Decides whether the word at [index] (descending frequency) is rotated.
///
/// The most frequent word (index 0) always stays horizontal for readability;
/// roughly every third word after it is rotated, giving the classic tag-cloud
/// look without randomness (keeps exports reproducible).
bool rotatedAtIndex(int index) => index > 0 && index % 3 == 1;

/// Lays out [words] inside [canvasSize], measuring text via [measure].
GenreCloudLayout layoutGenreCloud({
  required List<FacetValue> words,
  required Size canvasSize,
  required MeasureWord measure,
  double minFontSize = _defaultMinFontSize,
  double maxFontSize = _defaultMaxFontSize,
  int maxTiers = _defaultMaxTiers,
}) {
  if (words.isEmpty || canvasSize.width <= 0 || canvasSize.height <= 0) {
    return GenreCloudLayout(
      placed: const <PlacedWord>[],
      hidden: 0,
      size: canvasSize,
    );
  }

  final List<FacetValue> sorted = List<FacetValue>.of(words)
    ..sort((FacetValue a, FacetValue b) {
      final int byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });

  // Rank distinct counts (highest = rank 0). Equal counts -> same rank.
  final List<int> distinctCounts = sorted
      .map((FacetValue w) => w.count)
      .toSet()
      .toList()
    ..sort((int a, int b) => b.compareTo(a));
  final Map<int, int> rankByCount = <int, int>{
    for (int i = 0; i < distinctCounts.length; i++) distinctCounts[i]: i,
  };
  final int distinct = distinctCounts.length;

  double scaleMax = maxFontSize;
  _Attempt attempt = _placeAll(
    sorted, canvasSize, measure, minFontSize, scaleMax,
    rankByCount, distinct, maxTiers,
  );
  // Auto-fit: shrink the top of the scale until everything fits or we hit the
  // floor (then [hidden] carries whatever still does not fit).
  while (attempt.hidden > 0 && scaleMax > minFontSize + 1) {
    scaleMax = math.max(minFontSize, scaleMax * 0.85);
    attempt = _placeAll(
      sorted, canvasSize, measure, minFontSize, scaleMax,
      rankByCount, distinct, maxTiers,
    );
  }

  return GenreCloudLayout(
    placed: attempt.placed,
    hidden: attempt.hidden,
    size: canvasSize,
  );
}

/// One placement pass at a given [scaleMax].
_Attempt _placeAll(
  List<FacetValue> sorted,
  Size size,
  MeasureWord measure,
  double minFont,
  double scaleMax,
  Map<int, int> rankByCount,
  int distinct,
  int maxTiers,
) {
  final List<PlacedWord> placed = <PlacedWord>[];
  final List<Rect> occupied = <Rect>[];
  int hidden = 0;

  final double cx = size.width / 2;
  final double cy = size.height / 2;
  const double pad = 4;
  const double margin = 6;
  const double aspect = 1.7; // spread wider than tall, like a real cloud

  for (int i = 0; i < sorted.length; i++) {
    final FacetValue word = sorted[i];
    final double fontSize = _fontForRank(
      rankByCount[word.count] ?? 0, distinct, maxTiers, minFont, scaleMax,
    );
    final Size raw = measure(word, fontSize);
    final bool rotated = rotatedAtIndex(i);
    final double w = rotated ? raw.height : raw.width;
    final double h = rotated ? raw.width : raw.height;

    // Word too large for the canvas at this scale -> defer to a smaller scale.
    if (w > size.width - margin * 2 || h > size.height - margin * 2) {
      hidden++;
      continue;
    }

    Offset? center;
    double t = 0;
    for (int step = 0; step < 6000; step++) {
      final double r = 3.0 * t;
      final double x = cx + r * math.cos(t) * aspect;
      final double y = cy + r * math.sin(t);
      t += 0.2;

      final Rect rect = Rect.fromCenter(
        center: Offset(x, y),
        width: w + pad,
        height: h + pad,
      );
      if (rect.left < margin ||
          rect.top < margin ||
          rect.right > size.width - margin ||
          rect.bottom > size.height - margin) {
        if (r > size.width + size.height) break; // spiral left the canvas
        continue;
      }

      bool collides = false;
      for (final Rect other in occupied) {
        if (other.overlaps(rect)) {
          collides = true;
          break;
        }
      }
      if (!collides) {
        center = Offset(x, y);
        occupied.add(rect);
        break;
      }
    }

    if (center == null) {
      hidden++;
      continue;
    }
    placed.add(
      PlacedWord(
        word: word,
        fontSize: fontSize,
        center: center,
        rotated: rotated,
      ),
    );
  }

  return _Attempt(placed, hidden);
}

/// Maps a count [rank] (0 = most frequent) to a font size along a geometric
/// ladder from [scaleMax] down to [minFont].
double _fontForRank(
  int rank,
  int distinct,
  int maxTiers,
  double minFont,
  double scaleMax,
) {
  final int tiers = math.min(distinct, maxTiers);
  if (tiers <= 1 || distinct <= 1) return scaleMax;
  final int tier = ((rank / (distinct - 1)) * (tiers - 1)).round();
  final double tNorm = tier / (tiers - 1);
  return scaleMax * math.pow(minFont / scaleMax, tNorm).toDouble();
}

/// Outcome of a single [_placeAll] pass.
class _Attempt {
  const _Attempt(this.placed, this.hidden);

  final List<PlacedWord> placed;
  final int hidden;
}
