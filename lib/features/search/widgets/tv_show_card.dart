// Карточка сериала для списка результатов поиска.

import 'package:flutter/material.dart';

import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/source_badge.dart';

/// Карточка сериала для отображения в списке.
///
/// Показывает постер, название, год, рейтинг, жанры, сезоны и статус.
/// Построена на основе [MediaCard].
class TvShowCard extends StatelessWidget {
  /// Создаёт [TvShowCard].
  const TvShowCard({
    required this.tvShow,
    this.onTap,
    this.trailing,
    this.collectionName,
    super.key,
  });

  /// Сериал для отображения.
  final TvShow tvShow;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  /// Виджет справа (например, кнопка добавления).
  final Widget? trailing;

  /// Название коллекции, в которой сериал находится.
  final String? collectionName;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: tvShow.title,
      imageUrl: tvShow.posterThumbUrl,
      placeholderIcon: Icons.tv,
      mediaType: MediaType.tvShow,
      source: DataSource.tmdb,
      year: tvShow.firstAirYear,
      rating: tvShow.formattedRating,
      genres: tvShow.genresString,
      onTap: onTap,
      trailing: trailing,
      memCacheWidth: 120,
      memCacheHeight: 160,
      additionalInfo: _buildSeasonsAndStatus(context),
      collectionName: collectionName,
    );
  }

  Widget? _buildSeasonsAndStatus(BuildContext context) {
    if (tvShow.totalSeasons == null && tvShow.status == null) {
      return null;
    }

    return Row(
      children: <Widget>[
        if (tvShow.totalSeasons != null) ...<Widget>[
          const Icon(
            Icons.video_library,
            size: 14,
            color: AppColors.gameAccent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _formatSeasons(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gameAccent,
            ),
          ),
        ],
        if (tvShow.totalSeasons != null && tvShow.status != null) ...<Widget>[
          const SizedBox(width: 12),
        ],
        if (tvShow.status != null) ...<Widget>[
          Text(
            tvShow.status!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _formatSeasons() {
    final int seasons = tvShow.totalSeasons ?? 0;
    final int? episodes = tvShow.totalEpisodes;

    final String seasonsText = '$seasons season${seasons != 1 ? 's' : ''}';

    if (episodes != null) {
      return '$seasonsText \u2022 $episodes ep.';
    }

    return seasonsText;
  }
}
