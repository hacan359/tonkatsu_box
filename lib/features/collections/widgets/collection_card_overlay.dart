// The scrim background is NOT drawn here — that is the parent's job:
// rich cards get it from `CollectionHeroBackground`, classic cards put
// `CollectionCardBottomScrim` underneath the overlay.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class CollectionCardOverlay extends StatelessWidget {
  const CollectionCardOverlay({
    required this.name,
    required this.statsAsync,
    this.description,
    super.key,
  });

  final String name;

  /// When `null` or empty, the description line is not rendered.
  final String? description;

  final AsyncValue<CollectionStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    final bool hasDescription =
        description != null && description!.isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _OverlayMetrics m = _metricsFor(constraints.maxWidth);

        return Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(m.hPad, 0, m.hPad, m.bPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: m.nameSize,
                    height: 1.1,
                    shadows: const <Shadow>[
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasDescription) ...<Widget>[
                  SizedBox(height: m.gapDesc),
                  Text(
                    description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: m.descSize,
                      shadows: const <Shadow>[
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                    maxLines: m.descLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: m.gapStats),
                statsAsync.when(
                  data: (CollectionStats s) => Text(
                    S.of(context).collectionTileStats(
                          s.total,
                          s.completionPercentFormatted,
                        ),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: m.statsSize,
                      shadows: const <Shadow>[
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => const SizedBox(height: 14),
                  error: (Object error, StackTrace stack) => Text(
                    S.of(context).collectionTileError,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                      fontSize: m.statsSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverlayMetrics {
  const _OverlayMetrics({
    required this.nameSize,
    required this.descSize,
    required this.statsSize,
    required this.hPad,
    required this.bPad,
    required this.gapDesc,
    required this.gapStats,
    required this.descLines,
  });

  final double nameSize;
  final double descSize;
  final double statsSize;
  final double hPad;
  final double bPad;
  final double gapDesc;
  final double gapStats;
  final int descLines;
}

// Presets: xs — 3 columns on mobile, sm — 4 columns on tablet, default — desktop.
const _OverlayMetrics _metricsXs = _OverlayMetrics(
  nameSize: 13,
  descSize: 10,
  statsSize: 9,
  hPad: 10,
  bPad: 8,
  gapDesc: 2,
  gapStats: 3,
  descLines: 1,
);
const _OverlayMetrics _metricsSm = _OverlayMetrics(
  nameSize: 15,
  descSize: 11,
  statsSize: 10,
  hPad: 14,
  bPad: 12,
  gapDesc: 4,
  gapStats: 6,
  descLines: 2,
);
const _OverlayMetrics _metricsDefault = _OverlayMetrics(
  nameSize: 17,
  descSize: 12,
  statsSize: 11,
  hPad: 14,
  bPad: 12,
  gapDesc: 4,
  gapStats: 6,
  descLines: 2,
);

_OverlayMetrics _metricsFor(double cardWidth) {
  if (cardWidth < 150) return _metricsXs;
  if (cardWidth < 210) return _metricsSm;
  return _metricsDefault;
}

/// Covers the bottom ~55% of the card so the top row of mosaic posters
/// stays clean while the bottom row is dimmed for text readability.
class CollectionCardBottomScrim extends StatelessWidget {
  const CollectionCardBottomScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.transparent,
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.85),
            ],
            stops: const <double>[0.45, 0.70, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
