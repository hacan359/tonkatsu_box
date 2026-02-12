// Базовая карточка для отображения медиа-элементов в списке.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../constants/media_type_theme.dart';
import '../models/media_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'media_type_badge.dart';
import 'source_badge.dart';

/// Единая карточка для отображения игр, фильмов и сериалов в списке.
///
/// Обеспечивает единый стиль: изображение → название → метаданные → кнопки.
/// Тип-специфичная информация передаётся через [additionalInfo].
class MediaCard extends StatelessWidget {
  /// Создаёт [MediaCard].
  const MediaCard({
    required this.title,
    required this.placeholderIcon,
    this.mediaType,
    this.source,
    this.imageUrl,
    this.year,
    this.rating,
    this.genres,
    this.additionalInfo,
    this.trailing,
    this.onTap,
    this.memCacheWidth,
    this.memCacheHeight,
    this.collectionName,
    this.cacheImageType,
    this.cacheImageId,
    super.key,
  });

  /// Название элемента.
  final String title;

  /// Иконка-заглушка при отсутствии изображения.
  final IconData placeholderIcon;

  /// Тип медиа для цветового бейджа. Если null — бейдж не показывается.
  final MediaType? mediaType;

  /// Источник данных (IGDB, TMDB и т.д.). Если null — бейдж не показывается.
  final DataSource? source;

  /// URL изображения (обложка, постер).
  final String? imageUrl;

  /// Год выпуска / премьеры.
  final int? year;

  /// Отформатированный рейтинг (например, "8.5").
  final String? rating;

  /// Жанры одной строкой (например, "Action, RPG").
  final String? genres;

  /// Виджет с дополнительной информацией (платформы, длительность, сезоны).
  final Widget? additionalInfo;

  /// Виджет справа (например, кнопка добавления).
  final Widget? trailing;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  /// Ширина кэша изображения в памяти.
  final int? memCacheWidth;

  /// Высота кэша изображения в памяти.
  final int? memCacheHeight;

  /// Название коллекции, в которой элемент находится.
  ///
  /// Если не null — показывает маркировку "In: name" с галочкой.
  final String? collectionName;

  /// Тип изображения для локального кэширования.
  ///
  /// Если задан вместе с [cacheImageId], используется [CachedImage]
  /// вместо [CachedNetworkImage] для поддержки оффлайн-режима.
  final ImageType? cacheImageType;

  /// ID изображения для локального кэширования.
  final String? cacheImageId;

  /// Ширина постера/обложки.
  static const double posterWidth = 64;

  /// Высота постера/обложки.
  static const double posterHeight = 96;

  /// Радиус скругления постера.
  static const double posterBorderRadius = 4;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildImage(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildInfo(),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final bool useLocalCache =
        cacheImageType != null && cacheImageId != null && imageUrl != null;

    final Widget image = imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(posterBorderRadius),
            child: useLocalCache
                ? CachedImage(
                    imageType: cacheImageType!,
                    imageId: cacheImageId!,
                    remoteUrl: imageUrl!,
                    width: posterWidth,
                    height: posterHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: memCacheWidth,
                    memCacheHeight: memCacheHeight,
                    placeholder: _buildLoadingPlaceholder(),
                    errorWidget: _buildPlaceholder(),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: posterWidth,
                    height: posterHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: memCacheWidth,
                    memCacheHeight: memCacheHeight,
                    placeholder: (BuildContext context, String url) =>
                        _buildLoadingPlaceholder(),
                    errorWidget:
                        (BuildContext context, String url, Object error) =>
                            _buildPlaceholder(),
                  ),
          )
        : _buildPlaceholder();

    if (mediaType == null) {
      return image;
    }

    final Color typeColor = MediaTypeTheme.colorFor(mediaType!);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: typeColor, width: 2),
        borderRadius: BorderRadius.circular(posterBorderRadius + 1),
      ),
      child: Stack(
        children: <Widget>[
          image,
          Positioned(
            right: 0,
            bottom: 0,
            child: MediaTypeBadge(mediaType: mediaType!),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: posterWidth,
      height: posterHeight,
      color: AppColors.surfaceLight,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: posterWidth,
      height: posterHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(posterBorderRadius),
      ),
      child: Icon(
        placeholderIcon,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Название
        Text(
          title,
          style: AppTypography.h3,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppSpacing.xs),

        // Год, рейтинг и источник
        Row(
          children: <Widget>[
            if (source != null) ...<Widget>[
              SourceBadge(source: source!),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (year != null) ...<Widget>[
              Text(
                year.toString(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            if (rating != null) ...<Widget>[
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber.shade600,
              ),
              const SizedBox(width: 2),
              Text(
                rating!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        // Жанры
        if (genres != null && genres!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            genres!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Дополнительная информация (платформы, длительность, сезоны)
        if (additionalInfo != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          additionalInfo!,
        ],

        // Маркировка коллекции
        if (collectionName != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle,
                size: 14,
                color: AppColors.gameAccent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'In: $collectionName',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gameAccent,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
