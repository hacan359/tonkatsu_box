// Карточка с постером для grid-отображения.

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';

/// Карточка с постером/обложкой для grid-отображения.
///
/// Показывает изображение на весь размер карточки, название внизу
/// с градиентным overlay, опциональный бейдж статуса и акцентную полоску.
///
/// Используется в коллекциях (grid view) и результатах поиска.
class PosterCard extends StatelessWidget {
  /// Создаёт [PosterCard].
  const PosterCard({
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.accentColor,
    this.statusLabel,
    this.statusColor,
    this.onTap,
    this.placeholderIcon = Icons.image,
    this.cacheImageType,
    this.cacheImageId,
    super.key,
  });

  /// Название элемента.
  final String title;

  /// URL изображения (постер, обложка).
  final String? imageUrl;

  /// Подзаголовок (год, жанр, платформа).
  final String? subtitle;

  /// Цвет акцента (полоска снизу по типу медиа).
  final Color? accentColor;

  /// Текст бейджа статуса (например, "Playing", "Completed").
  final String? statusLabel;

  /// Цвет бейджа статуса.
  final Color? statusColor;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Иконка-заглушка при отсутствии изображения.
  final IconData placeholderIcon;

  /// Тип изображения для локального кэширования.
  final ImageType? cacheImageType;

  /// ID изображения для локального кэширования.
  final String? cacheImageId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Постер
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _buildImage(),
                  // Градиент для текста
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: <Color>[
                            Colors.black87,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Название и подзаголовок
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Бейдж статуса
                  if (statusLabel != null)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (statusColor ?? AppColors.textTertiary)
                              .withAlpha(200),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          statusLabel!,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Акцентная полоска
            if (accentColor != null)
              Container(
                height: 3,
                color: accentColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final bool useLocalCache =
        cacheImageType != null && cacheImageId != null && imageUrl != null;

    if (imageUrl != null) {
      if (useLocalCache) {
        return CachedImage(
          imageType: cacheImageType!,
          imageId: cacheImageId!,
          remoteUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: _buildPlaceholder(),
          errorWidget: _buildPlaceholder(),
        );
      }
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          placeholderIcon,
          color: AppColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}
