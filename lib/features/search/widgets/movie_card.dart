// Карточка фильма для списка результатов поиска.

import 'package:flutter/material.dart';

import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/source_badge.dart';

/// Карточка фильма для отображения в списке.
///
/// Показывает постер, название, год, рейтинг, жанры и длительность.
/// Построена на основе [MediaCard].
class MovieCard extends StatelessWidget {
  /// Создаёт [MovieCard].
  const MovieCard({
    required this.movie,
    this.onTap,
    this.trailing,
    this.collectionName,
    super.key,
  });

  /// Фильм для отображения.
  final Movie movie;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  /// Виджет справа (например, кнопка добавления).
  final Widget? trailing;

  /// Название коллекции, в которой фильм находится.
  final String? collectionName;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: movie.title,
      imageUrl: movie.posterThumbUrl,
      placeholderIcon: Icons.movie,
      mediaType: MediaType.movie,
      source: DataSource.tmdb,
      year: movie.releaseYear,
      rating: movie.formattedRating,
      genres: movie.genresString,
      onTap: onTap,
      trailing: trailing,
      memCacheWidth: 120,
      memCacheHeight: 160,
      additionalInfo: _buildRuntime(context),
      collectionName: collectionName,
    );
  }

  Widget? _buildRuntime(BuildContext context) {
    if (movie.runtime == null) {
      return null;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
    );
  }
}
