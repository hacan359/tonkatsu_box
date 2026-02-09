import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/canvas_item.dart';

/// Карточка игры на канвасе.
///
/// Отображает обложку, название и платформу в компактном виде.
class CanvasGameCard extends StatelessWidget {
  /// Создаёт [CanvasGameCard].
  const CanvasGameCard({
    required this.item,
    super.key,
  });

  /// Элемент канваса с данными игры.
  final CanvasItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String? coverUrl = item.game?.coverUrl;
    final String gameName = item.game?.name ?? 'Unknown Game';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: MediaTypeTheme.gameColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Обложка
          Expanded(
            child: coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
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
                            Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.videogame_asset,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.videogame_asset,
                      size: 32,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),

          // Название
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: colorScheme.surfaceContainerLow,
            child: Text(
              gameName,
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
}
