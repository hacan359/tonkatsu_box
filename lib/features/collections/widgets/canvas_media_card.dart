// Карточка фильма/сериала на канвасе.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/widgets/cached_image.dart';

/// Карточка фильма или сериала на канвасе.
///
/// Отображает постер, название в компактном виде.
/// Аналог [CanvasGameCard] для типов [CanvasItemType.movie]
/// и [CanvasItemType.tvShow].
class CanvasMediaCard extends ConsumerWidget {
  /// Создаёт [CanvasMediaCard].
  const CanvasMediaCard({
    required this.item,
    super.key,
  });

  /// Элемент канваса с данными фильма или сериала.
  final CanvasItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final String? posterUrl = _getPosterUrl();
    final String title = _getTitle();
    final IconData placeholderIcon = _getPlaceholderIcon();

    final Color borderColor = _getBorderColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Постер
          Expanded(
            child: posterUrl != null
                ? CachedImage(
                    imageType: _getImageType(),
                    imageId: _getImageId(),
                    remoteUrl: posterUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        _buildPlaceholder(colorScheme, placeholderIcon),
                    errorWidget:
                        _buildPlaceholder(colorScheme, placeholderIcon),
                  )
                : _buildPlaceholder(colorScheme, placeholderIcon),
          ),

          // Название
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: colorScheme.surfaceContainerLow,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageType _getImageType() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return ImageType.moviePoster;
      case CanvasItemType.tvShow:
        return ImageType.tvShowPoster;
      case CanvasItemType.animation:
        return ImageType.moviePoster;
      case CanvasItemType.game:
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return ImageType.gameCover;
    }
  }

  String _getImageId() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return (item.movie?.tmdbId ?? 0).toString();
      case CanvasItemType.tvShow:
        return (item.tvShow?.tmdbId ?? 0).toString();
      case CanvasItemType.animation:
        // Animation может быть movie или tvShow
        final int id = item.movie?.tmdbId ?? item.tvShow?.tmdbId ?? 0;
        return id.toString();
      case CanvasItemType.game:
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return '0';
    }
  }

  Color _getBorderColor() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return MediaTypeTheme.colorFor(MediaType.movie);
      case CanvasItemType.tvShow:
        return MediaTypeTheme.colorFor(MediaType.tvShow);
      case CanvasItemType.animation:
        return MediaTypeTheme.colorFor(MediaType.animation);
      case CanvasItemType.game:
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return MediaTypeTheme.colorFor(MediaType.game);
    }
  }

  String? _getPosterUrl() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return item.movie?.posterThumbUrl;
      case CanvasItemType.tvShow:
        return item.tvShow?.posterThumbUrl;
      case CanvasItemType.animation:
        return item.movie?.posterThumbUrl ?? item.tvShow?.posterThumbUrl;
      case CanvasItemType.game:
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return null;
    }
  }

  String _getTitle() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return item.movie?.title ?? 'Unknown Movie';
      case CanvasItemType.tvShow:
        return item.tvShow?.title ?? 'Unknown TV Show';
      case CanvasItemType.animation:
        return item.movie?.title ?? item.tvShow?.title ?? 'Unknown Animation';
      case CanvasItemType.game:
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return 'Unknown';
    }
  }

  IconData _getPlaceholderIcon() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return Icons.movie_outlined;
      case CanvasItemType.tvShow:
        return Icons.tv_outlined;
      case CanvasItemType.animation:
        return Icons.animation;
      case CanvasItemType.game:
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return Icons.image_outlined;
    }
  }

  Widget _buildPlaceholder(ColorScheme colorScheme, IconData icon) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        icon,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
