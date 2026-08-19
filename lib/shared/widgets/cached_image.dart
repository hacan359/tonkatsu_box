import 'dart:io';

import 'package:core/api/image_proxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/selfhost/server_origin.dart';
import '../../core/services/image_cache_service.dart';
import '../constants/platform_features.dart';

/// The fetch [Future] is held in [State] so a parent rebuild does not restart
/// the load and flicker the placeholder.
class CachedImage extends ConsumerStatefulWidget {
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

  /// Image category — routes to the right sub-folder of the local cache.
  final ImageType imageType;

  /// Cache key — typically the upstream entity id.
  final String imageId;

  final String remoteUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// When the cache misses, pull the file into the local cache in the
  /// background instead of leaving subsequent renders to refetch.
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

        if (snapshot.hasError) {
          return _buildError(context);
        }

        final ImageResult? result = snapshot.data;
        if (result == null) {
          return _buildError(context);
        }

        if (result.isMissing) {
          // Cache enabled but file missing — render from network, refill in background.
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

        if (result.isLocal && result.uri != null) {
          final File localFile = File(result.uri!);
          // The file may have been deleted/truncated between getImageUri and
          // render (clearCache or parallel re-download race).
          if (!localFile.existsSync() || localFile.lengthSync() == 0) {
            _deleteAndRedownload();
            return _buildNetworkImage(widget.remoteUrl, context);
          }
          return Image.file(
            localFile,
            // A replaced cover can land back on the same path; keying by the
            // source makes the widget resolve it again instead of reusing it.
            key: ValueKey<String>(widget.remoteUrl),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            cacheWidth: widget.memCacheWidth,
            cacheHeight: widget.memCacheHeight,
            errorBuilder:
                (BuildContext ctx, Object error, StackTrace? stack) {
              // Local file is corrupt — evict, redownload, render from network.
              _deleteAndRedownload();
              return _buildNetworkImage(widget.remoteUrl, context);
            },
          );
        }

        if (result.uri != null) {
          return _buildNetworkImage(result.uri!, context);
        }

        return _buildError(context);
      },
    );
  }

  /// Re-entry guard so a corrupt-cache eviction fires once per mount, not
  /// per rebuild.
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
    if (imageUrl.isEmpty) {
      return _buildError(context);
    }
    // CanvasKit fetches bytes over XHR and the provider CDNs answer without a
    // CORS header; our own origin sidesteps that and fills the server cache.
    final String url = kIsWebBuild
        ? imageProxyUrl(
            baseUrl: serverBaseUrl(),
            type: widget.imageType,
            imageId: widget.imageId,
            sourceUrl: imageUrl,
          )
        : imageUrl;
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.memCacheWidth,
      cacheHeight: widget.memCacheHeight,
      frameBuilder: (
        BuildContext ctx,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildPlaceholder();
      },
      errorBuilder: (BuildContext ctx, Object error, StackTrace? stack) {
        return _buildError(context);
      },
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
