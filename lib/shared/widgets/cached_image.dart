// Виджет для отображения кэшированных изображений.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/image_cache_service.dart';

/// Виджет для отображения кэшированных изображений.
///
/// Автоматически определяет источник изображения:
/// - Если кэширование выключено: загружает из сети
/// - Если кэширование включено и файл есть: показывает локальный файл
/// - Если кэширование включено, но файл отсутствует: загружает из сети
///   и скачивает в кэш в фоне (при [autoDownload] = true)
class CachedImage extends ConsumerWidget {
  /// Создаёт [CachedImage].
  const CachedImage({
    required this.imageType,
    required this.imageId,
    required this.remoteUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.autoDownload = true,
    super.key,
  });

  /// Тип изображения (платформа, обложка, постер).
  final ImageType imageType;

  /// ID изображения для кэша.
  final String imageId;

  /// URL для загрузки из сети.
  final String remoteUrl;

  /// Ширина изображения.
  final double? width;

  /// Высота изображения.
  final double? height;

  /// Способ масштабирования.
  final BoxFit fit;

  /// Ширина кэша изображения в памяти.
  final int? memCacheWidth;

  /// Высота кэша изображения в памяти.
  final int? memCacheHeight;

  /// Виджет-заглушка при загрузке.
  final Widget? placeholder;

  /// Виджет при ошибке.
  final Widget? errorWidget;

  /// Автоматически скачивать в локальный кэш при отсутствии файла.
  final bool autoDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ImageCacheService cacheService = ref.read(imageCacheServiceProvider);

    return FutureBuilder<ImageResult>(
      future: cacheService.getImageUri(
        type: imageType,
        imageId: imageId,
        remoteUrl: remoteUrl,
      ),
      builder: (BuildContext context, AsyncSnapshot<ImageResult> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        final ImageResult? result = snapshot.data;
        if (result == null) {
          return _buildError(context);
        }

        // Кэш включён, но файл отсутствует — показать из сети + скачать
        if (result.isMissing) {
          if (autoDownload && result.uri != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cacheService.downloadImage(
                type: imageType,
                imageId: imageId,
                remoteUrl: remoteUrl,
              );
            });
          }
          return _buildNetworkImage(result.uri!, context);
        }

        // Локальный файл
        if (result.isLocal && result.uri != null) {
          return Image.file(
            File(result.uri!),
            width: width,
            height: height,
            fit: fit,
            errorBuilder:
                (BuildContext ctx, Object error, StackTrace? stack) {
              return _buildError(context);
            },
          );
        }

        // Удалённый URL (кэш выключен)
        if (result.uri != null) {
          return _buildNetworkImage(result.uri!, context);
        }

        return _buildError(context);
      },
    );
  }

  Widget _buildNetworkImage(String imageUrl, BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (BuildContext ctx, String url) => _buildPlaceholder(),
      errorWidget: (BuildContext ctx, String url, Object error) =>
          _buildError(context),
    );
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.error,
        size: 24,
      ),
    );
  }
}
