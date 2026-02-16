// Вертикальная постерная карточка для сеток.

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../models/item_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'rating_badge.dart';

/// Вертикальная карточка с постером и информацией.
///
/// Ключевой компонент для отображения медиа в сетке.
/// Постер занимает всё доступное пространство, под ним — название и подзаголовок.
/// При наведении мыши — лёгкое увеличение и подсветка рамки.
class PosterCard extends StatefulWidget {
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
    this.status,
    this.compact = false,
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

  /// Статус элемента. Если задан и != notStarted — показывается бейдж.
  final ItemStatus? status;

  /// Компактный режим (уменьшенные размеры для ландшафта).
  final bool compact;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Обработчик долгого нажатия.
  final VoidCallback? onLongPress;

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _scaleAnimation;

  /// Масштаб при наведении.
  static const double _hoverScale = 1.04;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: _hoverScale).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Постер с overlay-элементами
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    widget.compact
                        ? AppSpacing.radiusSm
                        : AppSpacing.radiusMd,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      // Постер
                      CachedImage(
                        imageType: widget.cacheImageType,
                        imageId: widget.cacheImageId,
                        remoteUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: AppColors.surfaceLight,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textTertiary,
                              size: widget.compact ? 16 : 32,
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          color: AppColors.surfaceLight,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textTertiary,
                            size: widget.compact ? 16 : 32,
                          ),
                        ),
                      ),

                      // Затемнение постера
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x30000000),
                        ),
                      ),

                      // Hover-подсветка
                      AnimatedBuilder(
                        animation: _hoverController,
                        builder:
                            (BuildContext context, Widget? child) {
                          if (_hoverController.value == 0) {
                            return const SizedBox.shrink();
                          }
                          return Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.textPrimary
                                      .withAlpha(
                                        (40 * _hoverController.value)
                                            .round(),
                                      ),
                                ),
                                borderRadius: BorderRadius.circular(
                                  widget.compact
                                      ? AppSpacing.radiusSm
                                      : AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Рейтинг badge (top-left)
                      if (widget.rating != null && widget.rating! > 0)
                        Positioned(
                          top: widget.compact ? 2 : AppSpacing.xs,
                          left: widget.compact ? 2 : AppSpacing.xs,
                          child: RatingBadge(
                            rating: widget.rating!,
                            compact: widget.compact,
                          ),
                        ),

                      // Отметка "в коллекции" (top-right)
                      if (widget.isInCollection)
                        Positioned(
                          top: widget.compact ? 2 : AppSpacing.xs,
                          right: widget.compact ? 2 : AppSpacing.xs,
                          child: Container(
                            padding: EdgeInsets.all(
                              widget.compact ? 2 : 4,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: widget.compact ? 8 : 12,
                            ),
                          ),
                        ),

                      // Статус-бейдж (bottom-left)
                      if (widget.status != null &&
                          widget.status != ItemStatus.notStarted)
                        Positioned(
                          bottom: widget.compact ? 2 : AppSpacing.xs,
                          left: widget.compact ? 2 : AppSpacing.xs,
                          child: Container(
                            padding: EdgeInsets.all(
                              widget.compact ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.status!.color,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              widget.status!.icon,
                              style: TextStyle(
                                fontSize: widget.compact ? 7 : 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: widget.compact ? 2 : AppSpacing.xs),

              // Название
              Text(
                widget.title,
                style: widget.compact
                    ? AppTypography.posterTitle.copyWith(fontSize: 9)
                    : AppTypography.posterTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Подзаголовок (год + жанр)
              if (widget.year != null || widget.subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: widget.compact ? 1 : 2),
                  child: Text(
                    _buildSubtitleText(),
                    style: widget.compact
                        ? AppTypography.posterSubtitle
                            .copyWith(fontSize: 7)
                        : AppTypography.posterSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitleText() {
    final List<String> parts = <String>[];
    if (widget.year != null) parts.add(widget.year.toString());
    if (widget.subtitle != null) parts.add(widget.subtitle!);
    return parts.join(' · ');
  }
}
