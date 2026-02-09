import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/source_badge.dart';

/// Карточка игры для отображения в списке.
///
/// Показывает обложку, название, год релиза, рейтинг, жанры и платформы.
/// Построена на основе [MediaCard].
class GameCard extends StatelessWidget {
  /// Создаёт [GameCard].
  const GameCard({
    required this.game,
    this.onTap,
    this.trailing,
    this.platformNames,
    this.collectionName,
    super.key,
  });

  /// Игра для отображения.
  final Game game;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  /// Виджет справа (например, кнопка добавления).
  final Widget? trailing;

  /// Названия платформ для отображения.
  final List<String>? platformNames;

  /// Название коллекции, в которой игра находится.
  final String? collectionName;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: game.name,
      imageUrl: game.coverUrl,
      placeholderIcon: Icons.videogame_asset,
      mediaType: MediaType.game,
      source: DataSource.igdb,
      year: game.releaseYear,
      rating: game.formattedRating,
      genres: game.genresString,
      onTap: onTap,
      trailing: trailing,
      memCacheWidth: 120,
      memCacheHeight: 160,
      additionalInfo: _buildPlatforms(context),
      collectionName: collectionName,
    );
  }

  Widget? _buildPlatforms(BuildContext context) {
    if (platformNames == null || platformNames!.isEmpty) {
      return null;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Text(
      platformNames!.join(' \u2022 '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.primary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Компактная карточка игры для grid-отображения.
class GameGridCard extends StatelessWidget {
  /// Создаёт [GameGridCard].
  const GameGridCard({
    required this.game,
    this.onTap,
    super.key,
  });

  /// Игра для отображения.
  final Game game;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Обложка
            Expanded(
              child: _buildCover(colorScheme),
            ),

            // Название
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    game.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (game.releaseYear != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      game.releaseYear.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme colorScheme) {
    if (game.coverUrl != null) {
      return _buildCoverImage(colorScheme);
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildCoverImage(ColorScheme colorScheme) {
    return CachedNetworkImage(
      imageUrl: game.coverUrl!,
      fit: BoxFit.cover,
      placeholder: (BuildContext context, String url) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (BuildContext context, String url, Object error) =>
          _buildPlaceholder(colorScheme),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.videogame_asset,
        color: colorScheme.onSurfaceVariant,
        size: 48,
      ),
    );
  }
}
