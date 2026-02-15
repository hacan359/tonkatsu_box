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
///
/// Future кэшируется в State, чтобы при rebuild родителя
/// не происходило повторной загрузки (мигания placeholder → картинка).
class CachedImage extends ConsumerStatefulWidget {
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
  ConsumerState<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends ConsumerState<CachedImage> {
  Future<ImageResult>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _fetchImage();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageType != widget.imageType ||
        oldWidget.imageId != widget.imageId ||
        oldWidget.remoteUrl != widget.remoteUrl) {
      _imageFuture = _fetchImage();
      _corruptHandled = false;
    }
  }

  Future<ImageResult> _fetchImage() {
    final ImageCacheService cacheService = ref.read(imageCacheServiceProvider);
    return cacheService.getImageUri(
      type: widget.imageType,
      imageId: widget.imageId,
      remoteUrl: widget.remoteUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageResult>(
      future: _imageFuture,
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
          if (widget.autoDownload && result.uri != null) {
            final ImageCacheService cacheService =
                ref.read(imageCacheServiceProvider);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cacheService.downloadImage(
                type: widget.imageType,
                imageId: widget.imageId,
                remoteUrl: widget.remoteUrl,
              );
            });
          }
          return _buildNetworkImage(result.uri!, context);
        }

        // Локальный файл
        if (result.isLocal && result.uri != null) {
          return Image.file(
            File(result.uri!),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder:
                (BuildContext ctx, Object error, StackTrace? stack) {
              // Файл повреждён — удалить из кэша, перекачать, показать из сети
              _deleteAndRedownload();
              return _buildNetworkImage(widget.remoteUrl, context);
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

  /// Удаляет повреждённый файл из кэша и перекачивает.
  ///
  /// Защита от повторных вызовов: флаг [_corruptHandled] предотвращает
  /// множественные delete+download при rebuild виджета.
  bool _corruptHandled = false;

  void _deleteAndRedownload() {
    if (_corruptHandled) return;
    _corruptHandled = true;
    final ImageCacheService cacheService = ref.read(imageCacheServiceProvider);
    cacheService.deleteImage(widget.imageType, widget.imageId).then((_) {
      if (widget.autoDownload) {
        cacheService.downloadImage(
          type: widget.imageType,
          imageId: widget.imageId,
          remoteUrl: widget.remoteUrl,
        );
      }
    });
  }

  Widget _buildNetworkImage(String imageUrl, BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      placeholder: (BuildContext ctx, String url) => _buildPlaceholder(),
      errorWidget: (BuildContext ctx, String url, Object error) =>
          _buildError(context),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    return SizedBox(
      width: widget.width,
      height: widget.height,
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
    if (widget.errorWidget != null) return widget.errorWidget!;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.error,
        size: 24,
      ),
    );
  }
}
