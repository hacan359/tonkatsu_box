// Карточка сериала для списка результатов поиска.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/tv_show.dart';

/// Карточка сериала для отображения в списке.
///
/// Показывает постер, название, год, рейтинг, жанры, сезоны и статус.
class TvShowCard extends StatelessWidget {
  /// Создаёт [TvShowCard].
  const TvShowCard({
    required this.tvShow,
    this.onTap,
    this.trailing,
    super.key,
  });

  /// Сериал для отображения.
  final TvShow tvShow;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  /// Виджет справа (например, кнопка добавления).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildPoster(colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfo(theme, colorScheme),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(ColorScheme colorScheme) {
    const double posterWidth = 60;
    const double posterHeight = 80;

    if (tvShow.posterUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: tvShow.posterUrl!,
          width: posterWidth,
          height: posterHeight,
          fit: BoxFit.cover,
          placeholder: (BuildContext context, String url) => Container(
            width: posterWidth,
            height: posterHeight,
            color: colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (BuildContext context, String url, Object error) =>
              _buildPlaceholder(colorScheme, posterWidth, posterHeight),
        ),
      );
    }

    return _buildPlaceholder(colorScheme, posterWidth, posterHeight);
  }

  Widget _buildPlaceholder(
    ColorScheme colorScheme,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.tv,
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Название
        Text(
          tvShow.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Год и рейтинг
        Row(
          children: <Widget>[
            if (tvShow.firstAirYear != null) ...<Widget>[
              Text(
                tvShow.firstAirYear.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (tvShow.formattedRating != null) ...<Widget>[
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber.shade600,
              ),
              const SizedBox(width: 2),
              Text(
                tvShow.formattedRating!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        // Жанры
        if (tvShow.genresString != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            tvShow.genresString!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Сезоны и статус
        if (tvShow.totalSeasons != null || tvShow.status != null) ...<Widget>[
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              if (tvShow.totalSeasons != null) ...<Widget>[
                Icon(
                  Icons.video_library,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatSeasons(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
              if (tvShow.totalSeasons != null &&
                  tvShow.status != null) ...<Widget>[
                const SizedBox(width: 12),
              ],
              if (tvShow.status != null) ...<Widget>[
                Text(
                  tvShow.status!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  String _formatSeasons() {
    final int seasons = tvShow.totalSeasons ?? 0;
    final int? episodes = tvShow.totalEpisodes;

    final String seasonsText =
        '$seasons season${seasons != 1 ? 's' : ''}';

    if (episodes != null) {
      return '$seasonsText \u2022 $episodes ep.';
    }

    return seasonsText;
  }
}
