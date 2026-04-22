// Общий text-overlay для карточек коллекций в home-гриде.
//
// Выводит имя → описание → статистику в левом-нижнем углу карточки.
// Используется и в rich-карточке (на hero), и в classic-карточке (на мозаике
// поверх bottom-scrim'а). Scrim-фон здесь НЕ рисуется — это ответственность
// родителя:
//   • rich → scrim от `CollectionHeroBackground`;
//   • classic → `CollectionCardBottomScrim` перед overlay'ем.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

/// Text-блок карточки коллекции: имя + описание + статистика в углу.
class CollectionCardOverlay extends StatelessWidget {
  /// Создаёт [CollectionCardOverlay].
  const CollectionCardOverlay({
    required this.name,
    required this.statsAsync,
    this.description,
    super.key,
  });

  /// Имя коллекции.
  final String name;

  /// Описание (или `null`/пусто — строка не выводится).
  final String? description;

  /// Асинхронная статистика (total, completion%).
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

/// Метрики overlay'я — шрифты, отступы, межстрочные интервалы для трёх
/// размеров карточек (xs / sm / default).
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

// Пресеты: xs — 3 колонки на mobile, sm — 4 колонки на tablet, default — ПК.
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

/// Нижний scrim-градиент для classic-карточки (прозрачный сверху → тёмный
/// снизу), чтобы text-overlay был читаем поверх мозаики.
///
/// Занимает нижние ~55% карточки — верхний ряд постеров мозаики остаётся
/// чистым, нижний ряд приглушается.
class CollectionCardBottomScrim extends StatelessWidget {
  /// Создаёт [CollectionCardBottomScrim].
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
