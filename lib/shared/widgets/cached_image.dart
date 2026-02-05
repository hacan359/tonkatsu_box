import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/image_cache_service.dart';

/// Виджет для отображения кэшированных изображений.
///
/// Автоматически определяет источник изображения:
/// - Если кэширование выключено: загружает из сети
/// - Если кэширование включено: показывает локальный файл
/// - Если файл отсутствует при включённом кэше: показывает ошибку
class CachedImage extends ConsumerWidget {
  /// Создаёт [CachedImage].
  const CachedImage({
    required this.imageType,
    required this.imageId,
    required this.remoteUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.onMissingCache,
    super.key,
  });

  /// Тип изображения (платформа или обложка).
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

  /// Виджет-заглушка при загрузке.
  final Widget? placeholder;

  /// Виджет при ошибке.
  final Widget? errorWidget;

  /// Callback при отсутствии локального файла (кэш повреждён).
  final VoidCallback? onMissingCache;

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

        // Кэш повреждён - показываем ошибку и уведомляем
        if (result.isMissing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onMissingCache?.call();
          });
          return _buildMissingCacheError(context);
        }

        // Локальный файл
        if (result.isLocal && result.uri != null) {
          return Image.file(
            File(result.uri!),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (BuildContext ctx, Object error, StackTrace? stack) {
              return _buildError(context);
            },
          );
        }

        // Удалённый URL
        if (result.uri != null) {
          return CachedNetworkImage(
            imageUrl: result.uri!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (BuildContext ctx, String url) => _buildPlaceholder(),
            errorWidget: (BuildContext ctx, String url, Object error) =>
                _buildError(context),
          );
        }

        return _buildError(context);
      },
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

  Widget _buildMissingCacheError(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.cloud_off,
        color: Theme.of(context).colorScheme.error,
        size: 24,
      ),
    );
  }
}
