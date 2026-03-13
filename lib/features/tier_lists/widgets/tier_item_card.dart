// Карточка элемента в тир-листе (обложка с drag-and-drop).

import 'package:flutter/material.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/cached_image.dart';

/// Размеры обложки тир-листа.
const double kTierItemWidth = 90;
const double kTierItemImageHeight = 120;

/// Минимальная высота строки подписи.
const double kTierItemMinLabelHeight = 32;

/// Минимальная полная высота карточки (картинка + подпись).
const double kTierItemMinTotalHeight = kTierItemImageHeight + kTierItemMinLabelHeight;

/// Карточка элемента в тир-листе.
///
/// Обложка с текстовой подписью снизу. Поддерживает drag-and-drop.
class TierItemCard extends StatelessWidget {
  /// Создаёт [TierItemCard].
  const TierItemCard({
    required this.item,
    this.isDraggable = false,
    this.showLabel = true,
    this.width = kTierItemWidth,
    this.height = kTierItemImageHeight,
    super.key,
  });

  /// Элемент коллекции.
  final CollectionItem item;

  /// Включить drag-and-drop.
  final bool isDraggable;

  /// Показывать текстовую подпись под картинкой.
  final bool showLabel;

  /// Ширина обложки.
  final double width;

  /// Высота обложки.
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget card = _buildCard();
    if (!isDraggable) return card;

    return Draggable<int>(
      data: item.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: _buildCard(),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: card,
      ),
      child: card,
    );
  }

  Widget _buildCard() {
    return Tooltip(
      message: item.itemName,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Обложка
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: SizedBox(
                width: width,
                height: height,
                child: item.thumbnailUrl != null
                    ? CachedImage(
                        imageType: item.imageType,
                        imageId: item.externalId.toString(),
                        remoteUrl: item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: (width * 2).toInt(),
                        memCacheHeight: (height * 2).toInt(),
                        placeholder: _buildPlaceholder(),
                        errorWidget: _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Подпись
            if (showLabel)
              Container(
                width: width,
                constraints: const BoxConstraints(
                  minHeight: kTierItemMinLabelHeight,
                ),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppSpacing.radiusXs),
                    bottomRight: Radius.circular(AppSpacing.radiusXs),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 2,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      item.itemName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    if (item.mediaType == MediaType.game &&
                        item.platform != null)
                      Text(
                        item.platform!.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          height: 1.2,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
