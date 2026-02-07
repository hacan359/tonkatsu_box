// Карточка фильма для списка результатов поиска.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/movie.dart';

/// Карточка фильма для отображения в списке.
///
/// Показывает постер, название, год, рейтинг, жанры и длительность.
class MovieCard extends StatelessWidget {
  /// Создаёт [MovieCard].
  const MovieCard({
    required this.movie,
    this.onTap,
    this.trailing,
    super.key,
  });

  /// Фильм для отображения.
  final Movie movie;

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

    final String? thumbUrl = movie.posterThumbUrl;
    if (thumbUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: thumbUrl,
          width: posterWidth,
          height: posterHeight,
          fit: BoxFit.cover,
          memCacheWidth: 120,
          memCacheHeight: 160,
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
        Icons.movie,
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
          movie.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Год, рейтинг, длительность
        Row(
          children: <Widget>[
            if (movie.releaseYear != null) ...<Widget>[
              Text(
                movie.releaseYear.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (movie.formattedRating != null) ...<Widget>[
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber.shade600,
              ),
              const SizedBox(width: 2),
              Text(
                movie.formattedRating!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (movie.runtime != null) ...<Widget>[
              Icon(
                Icons.schedule,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
              Text(
                '${movie.runtime} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),

        // Жанры
        if (movie.genresString != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            movie.genresString!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
