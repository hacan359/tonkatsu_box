import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/widgets/cached_image.dart';

/// Карточка игры на канвасе.
///
/// Отображает обложку, название и платформу в компактном виде.
class CanvasGameCard extends ConsumerWidget {
  /// Создаёт [CanvasGameCard].
  const CanvasGameCard({
    required this.item,
    super.key,
  });

  /// Элемент канваса с данными игры.
  final CanvasItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: coverUrl != null && item.game != null
                ? CachedImage(
                    imageType: ImageType.gameCover,
                    imageId: item.game!.id.toString(),
                    remoteUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: _buildPlaceholder(colorScheme),
                    errorWidget: _buildPlaceholder(colorScheme),
                  )
                : _buildPlaceholder(colorScheme),
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

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.videogame_asset,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
