import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/game.dart';

/// Карточка игры для отображения в списке.
///
/// Показывает обложку, название, год релиза, рейтинг, жанры и платформы.
class GameCard extends StatelessWidget {
  /// Создаёт [GameCard].
  const GameCard({
    required this.game,
    this.onTap,
    this.trailing,
    this.platformNames,
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
              // Обложка
              _buildCover(colorScheme),
              const SizedBox(width: 12),

              // Информация
              Expanded(
                child: _buildInfo(theme, colorScheme),
              ),

              // Trailing widget
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

  Widget _buildCover(ColorScheme colorScheme) {
    const double coverWidth = 60;
    const double coverHeight = 80;

    if (game.coverUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: game.coverUrl!,
          width: coverWidth,
          height: coverHeight,
          fit: BoxFit.cover,
          placeholder: (BuildContext context, String url) => Container(
            width: coverWidth,
            height: coverHeight,
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
              _buildPlaceholder(colorScheme, coverWidth, coverHeight),
        ),
      );
    }

    return _buildPlaceholder(colorScheme, coverWidth, coverHeight);
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
        Icons.videogame_asset,
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
          game.name,
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
            if (game.releaseYear != null) ...<Widget>[
              Text(
                game.releaseYear.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (game.formattedRating != null) ...<Widget>[
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber.shade600,
              ),
              const SizedBox(width: 2),
              Text(
                game.formattedRating!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        // Жанры
        if (game.genresString != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            game.genresString!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Платформы
        if (platformNames != null && platformNames!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            platformNames!.join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
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

    return _buildPlaceholder(colorScheme);
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
