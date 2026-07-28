// Pure word-cloud layout: places facet words on a canvas with no overlaps.
//
// Kept free of Flutter widget code so it can be unit-tested with an injected
// text measurement function. Words are placed largest-first along an
// Archimedean spiral; if not everything fits, the size scale is shrunk and the
// layout is retried (auto-fit). Whatever still cannot be placed is reported via
// [hidden].
//
// Two entry points share the same placement code: [layoutGenreCloud] runs
// synchronously (export views, tests) and [layoutGenreCloudAsync] yields to the
// event loop between words so the UI thread keeps pumping frames (the loading
// indicator keeps animating) while a large cloud is being placed.

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

/// Time budget a chunked (async) pass may spend before yielding to the event
/// loop. Word costs vary wildly (spiral search), so the yield is elapsed-time
/// gated rather than per-N-words — this also keeps the pass fast on web,
/// where a zero-delay timer still costs ~4ms.
const int _yieldBudgetMs = 8;

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
  final _Prepared? prep = _prepare(words, canvasSize);
  if (prep == null) return _emptyLayout(canvasSize);

  double scaleMax = maxFontSize;
  _Attempt attempt = _placeAll(
    prep, canvasSize, measure, minFontSize, scaleMax, maxTiers,
  );
  // Auto-fit: shrink the top of the scale until everything fits or we hit the
  // floor (then [hidden] carries whatever still does not fit).
  while (attempt.hidden > 0 && scaleMax > minFontSize + 1) {
    scaleMax = math.max(minFontSize, scaleMax * 0.85);
    attempt = _placeAll(
      prep, canvasSize, measure, minFontSize, scaleMax, maxTiers,
    );
  }

  return GenreCloudLayout(
    placed: attempt.placed,
    hidden: attempt.hidden,
    size: canvasSize,
  );
}

/// Same layout as [layoutGenreCloud], but yields to the event loop every few
/// words so long computations don't freeze the UI thread. The result is
/// identical to the synchronous version (placement is deterministic).
Future<GenreCloudLayout> layoutGenreCloudAsync({
  required List<FacetValue> words,
  required Size canvasSize,
  required MeasureWord measure,
  double minFontSize = _defaultMinFontSize,
  double maxFontSize = _defaultMaxFontSize,
  int maxTiers = _defaultMaxTiers,
}) async {
  final _Prepared? prep = _prepare(words, canvasSize);
  if (prep == null) return _emptyLayout(canvasSize);

  double scaleMax = maxFontSize;
  _Attempt attempt = await _placeAllChunked(
    prep, canvasSize, measure, minFontSize, scaleMax, maxTiers,
  );
  while (attempt.hidden > 0 && scaleMax > minFontSize + 1) {
    scaleMax = math.max(minFontSize, scaleMax * 0.85);
    attempt = await _placeAllChunked(
      prep, canvasSize, measure, minFontSize, scaleMax, maxTiers,
    );
  }

  return GenreCloudLayout(
    placed: attempt.placed,
    hidden: attempt.hidden,
    size: canvasSize,
  );
}

GenreCloudLayout _emptyLayout(Size canvasSize) => GenreCloudLayout(
      placed: const <PlacedWord>[],
      hidden: 0,
      size: canvasSize,
    );

/// Sorted words plus count-rank data shared by every placement pass, or `null`
/// when there is nothing to lay out.
class _Prepared {
  const _Prepared(this.sorted, this.rankByCount);

  final List<FacetValue> sorted;
  final Map<int, int> rankByCount;

  int get distinct => rankByCount.length;
}

_Prepared? _prepare(List<FacetValue> words, Size canvasSize) {
  if (words.isEmpty || canvasSize.width <= 0 || canvasSize.height <= 0) {
    return null;
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
  return _Prepared(sorted, rankByCount);
}

/// One placement pass at a given [scaleMax].
_Attempt _placeAll(
  _Prepared prep,
  Size size,
  MeasureWord measure,
  double minFont,
  double scaleMax,
  int maxTiers,
) {
  final _Attempt attempt = _Attempt();
  for (int i = 0; i < prep.sorted.length; i++) {
    _placeWord(attempt, prep, i, size, measure, minFont, scaleMax, maxTiers);
  }
  return attempt;
}

/// One placement pass at a given [scaleMax], yielding to the event loop (so
/// animation frames can run) whenever [_yieldBudgetMs] of work accumulates.
Future<_Attempt> _placeAllChunked(
  _Prepared prep,
  Size size,
  MeasureWord measure,
  double minFont,
  double scaleMax,
  int maxTiers,
) async {
  final _Attempt attempt = _Attempt();
  final Stopwatch sinceYield = Stopwatch()..start();
  for (int i = 0; i < prep.sorted.length; i++) {
    _placeWord(attempt, prep, i, size, measure, minFont, scaleMax, maxTiers);
    if (sinceYield.elapsedMilliseconds >= _yieldBudgetMs) {
      await Future<void>.delayed(Duration.zero);
      sinceYield.reset();
    }
  }
  return attempt;
}

/// Places the word at [index] into [attempt] (or counts it as hidden).
void _placeWord(
  _Attempt attempt,
  _Prepared prep,
  int index,
  Size size,
  MeasureWord measure,
  double minFont,
  double scaleMax,
  int maxTiers,
) {
  const double pad = 4;
  const double margin = 6;
  const double aspect = 1.7; // spread wider than tall, like a real cloud
  final double cx = size.width / 2;
  final double cy = size.height / 2;

  final FacetValue word = prep.sorted[index];
  final double fontSize = _fontForRank(
    prep.rankByCount[word.count] ?? 0, prep.distinct, maxTiers, minFont,
    scaleMax,
  );
  final Size raw = measure(word, fontSize);
  final bool rotated = rotatedAtIndex(index);
  final double w = rotated ? raw.height : raw.width;
  final double h = rotated ? raw.width : raw.height;

  // Word too large for the canvas at this scale -> defer to a smaller scale.
  if (w > size.width - margin * 2 || h > size.height - margin * 2) {
    attempt.hidden++;
    return;
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
    for (final Rect other in attempt.occupied) {
      if (other.overlaps(rect)) {
        collides = true;
        break;
      }
    }
    if (!collides) {
      center = Offset(x, y);
      attempt.occupied.add(rect);
      break;
    }
  }

  if (center == null) {
    attempt.hidden++;
    return;
  }
  attempt.placed.add(
    PlacedWord(
      word: word,
      fontSize: fontSize,
      center: center,
      rotated: rotated,
    ),
  );
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

/// Accumulating state of a single placement pass.
class _Attempt {
  _Attempt();

  final List<PlacedWord> placed = <PlacedWord>[];
  final List<Rect> occupied = <Rect>[];
  int hidden = 0;
}
