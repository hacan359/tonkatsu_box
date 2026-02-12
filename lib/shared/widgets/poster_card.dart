// Вертикальная постерная карточка для сеток.

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'rating_badge.dart';

/// Вертикальная карточка с постером и информацией.
///
/// Ключевой компонент для отображения медиа в сетке.
/// Постер в соотношении 2:3, под ним — название, год, жанр.
class PosterCard extends StatelessWidget {
  /// Создаёт постерную карточку.
  const PosterCard({
    required this.title,
    required this.imageUrl,
    required this.cacheImageType,
    required this.cacheImageId,
    this.rating,
    this.year,
    this.subtitle,
    this.isInCollection = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Название элемента.
  final String title;

  /// URL изображения постера.
  final String imageUrl;

  /// Тип изображения для кэширования.
  final ImageType cacheImageType;

  /// ID изображения для кэширования.
  final String cacheImageId;

  /// Рейтинг (0.0–10.0). Если null — бейдж не показывается.
  final double? rating;

  /// Год выпуска. Если null — не показывается.
  final int? year;

  /// Подзаголовок (жанр, платформа и т.д.).
  final String? subtitle;

  /// Находится ли элемент в коллекции.
  final bool isInCollection;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Обработчик долгого нажатия.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Постер с overlay-элементами
          AspectRatio(
            aspectRatio: AppSpacing.posterAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Постер
                  CachedImage(
                    imageType: cacheImageType,
                    imageId: cacheImageId,
                    remoteUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(color: AppColors.surfaceLight),
                    errorWidget: Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textTertiary,
                        size: 32,
                      ),
                    ),
                  ),

                  // Рейтинг badge (top-left)
                  if (rating != null && rating! > 0)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: RatingBadge(rating: rating!),
                    ),

                  // Отметка "в коллекции" (top-right)
                  if (isInCollection)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Название
          Text(
            title,
            style: AppTypography.posterTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Подзаголовок (год + жанр)
          if (year != null || subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _buildSubtitleText(),
                style: AppTypography.posterSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  String _buildSubtitleText() {
    final List<String> parts = <String>[];
    if (year != null) parts.add(year.toString());
    if (subtitle != null) parts.add(subtitle!);
    return parts.join(' · ');
  }
}
