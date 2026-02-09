// Карточка фильма/сериала на канвасе.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/media_type.dart';

/// Карточка фильма или сериала на канвасе.
///
/// Отображает постер, название в компактном виде.
/// Аналог [CanvasGameCard] для типов [CanvasItemType.movie]
/// и [CanvasItemType.tvShow].
class CanvasMediaCard extends StatelessWidget {
  /// Создаёт [CanvasMediaCard].
  const CanvasMediaCard({
    required this.item,
    super.key,
  });

  /// Элемент канваса с данными фильма или сериала.
  final CanvasItem item;

  @override
  Widget build(BuildContext context) {
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
                ? CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (BuildContext ctx, String url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget:
                        (BuildContext ctx, String url, Object error) =>
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

  Color _getBorderColor() {
    switch (item.itemType) {
      case CanvasItemType.movie:
        return MediaTypeTheme.colorFor(MediaType.movie);
      case CanvasItemType.tvShow:
        return MediaTypeTheme.colorFor(MediaType.tvShow);
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
