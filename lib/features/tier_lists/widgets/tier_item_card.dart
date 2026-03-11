// Карточка элемента в тир-листе (обложка с drag-and-drop).

import 'package:flutter/material.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/cached_image.dart';

/// Размеры обложки тир-листа.
const double _kDesktopWidth = 60;
const double _kDesktopHeight = 82;

/// Карточка элемента в тир-листе.
///
/// Маленькая обложка с Tooltip. Поддерживает drag-and-drop.
class TierItemCard extends StatelessWidget {
  /// Создаёт [TierItemCard].
  const TierItemCard({
    required this.item,
    this.isDraggable = false,
    this.width = _kDesktopWidth,
    this.height = _kDesktopHeight,
    super.key,
  });

  /// Элемент коллекции.
  final CollectionItem item;

  /// Включить drag-and-drop.
  final bool isDraggable;

  /// Ширина.
  final double width;

  /// Высота.
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
      child: ClipRRect(
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
          size: 20,
        ),
      ),
    );
  }
}
