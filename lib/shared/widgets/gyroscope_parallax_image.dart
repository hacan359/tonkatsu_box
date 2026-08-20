import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/api/image_proxy.dart';
import 'package:core/models/image_type.dart';
import 'package:core/utils/stable_id.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/selfhost/server_origin.dart';
import '../constants/platform_features.dart';
import 'cached_image.dart';

/// Max parallax offset in pixels.
const double _kMaxOffset = 20.0;

/// Lerp smoothing factor — lower is smoother.
const double _kSmoothing = 0.08;

/// Shifts with device tilt to fake depth; falls back to a plain
/// [CachedNetworkImage] with no sensor or off Android.
class GyroscopeParallaxImage extends StatefulWidget {
  const GyroscopeParallaxImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorWidget,
    this.enabled = true,
    this.gyroscopeStream,
    this.imageType,
    this.imageId,
    super.key,
  });

  final String imageUrl;

  /// When both are set, the picture renders through the app's cover cache
  /// (CachedImage) instead of a second network fetch of an already-cached file.
  final ImageType? imageType;
  final String? imageId;

  /// When false, skips the sensor and renders the plain static image — for
  /// hosts where the motion is invisible (e.g. under a heavy blur).
  final bool enabled;

  /// How the image fits the available space.
  final BoxFit fit;

  /// Image alignment.
  final Alignment alignment;

  /// Widget shown on load error.
  final Widget Function(BuildContext, String, Object)? errorWidget;

  /// Gyroscope event source. Defaults to the system gyroscope (Android only);
  /// overridden in tests.
  @visibleForTesting
  final Stream<GyroscopeEvent>? gyroscopeStream;

  @override
  State<GyroscopeParallaxImage> createState() =>
      _GyroscopeParallaxImageState();
}

class _GyroscopeParallaxImageState extends State<GyroscopeParallaxImage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _subscription;
  AnimationController? _ticker;

  // Target offset (raw from gyroscope).
  double _targetX = 0;
  double _targetY = 0;

  // Current offset (smoothed toward target).
  double _currentX = 0;
  double _currentY = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    final Stream<GyroscopeEvent>? stream = widget.gyroscopeStream ??
        (kIsMobile
            ? gyroscopeEventStream(
                samplingPeriod: const Duration(milliseconds: 16),
              )
            : null);
    if (stream == null) return;

    final AnimationController ticker =
        AnimationController.unbounded(vsync: this)..addListener(_onTick);
    ticker.animateTo(1, duration: Duration.zero);
    _ticker = ticker;

    _subscription = stream.listen(
      _onGyroscope,
      onError: _onGyroscopeError,
      cancelOnError: true,
    );
  }

  void _onGyroscopeError(Object error) {
    // No gyroscope (PlatformException NO_SENSOR) — drop the parallax and fall
    // back to a plain static image instead of letting the error surface.
    _subscription?.cancel();
    _subscription = null;
    _ticker?.dispose();
    _ticker = null;
    if (mounted) {
      setState(() {});
    }
  }

  void _onGyroscope(GyroscopeEvent event) {
    final AnimationController? ticker = _ticker;
    if (ticker == null) return;

    // Gyroscope reports angular velocity (rad/s) — integrate into an offset
    // and clamp.
    _targetX = (_targetX + event.y).clamp(-_kMaxOffset, _kMaxOffset);
    _targetY = (_targetY - event.x).clamp(-_kMaxOffset, _kMaxOffset);

    if (!ticker.isAnimating) {
      ticker.animateTo(
        ticker.value + 1,
        duration: const Duration(seconds: 10),
      );
    }
  }

  void _onTick() {
    final double newX = _currentX + (_targetX - _currentX) * _kSmoothing;
    final double newY = _currentY + (_targetY - _currentY) * _kSmoothing;

    // Close enough to the target — skip the rebuild.
    if ((newX - _currentX).abs() < 0.01 && (newY - _currentY).abs() < 0.01) {
      return;
    }

    setState(() {
      _currentX = newX;
      _currentY = newY;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.dispose();
    super.dispose();
  }

  /// Provider CDNs answer CanvasKit's XHR without a CORS header, so on web
  /// the bytes come through the server's image cache, keyed by the URL hash.
  static String _proxiedUrl(String sourceUrl) {
    final String path = Uri.tryParse(sourceUrl)?.path ?? '';
    final int dot = path.lastIndexOf('.');
    final String ext = dot == -1 ? '' : path.substring(dot).toLowerCase();
    const Set<String> known = <String>{'.jpg', '.jpeg', '.png', '.webp', '.gif'};
    return imageProxyUrl(
      baseUrl: serverBaseUrl(),
      type: ImageType.backdrop,
      imageId: '${fnv1a53(sourceUrl)}${known.contains(ext) ? ext : ''}',
      sourceUrl: sourceUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageType? cacheType = widget.imageType;
    final String? cacheId = widget.imageId;
    final Widget image = (cacheType != null && cacheId != null)
        ? CachedImage(
            imageType: cacheType,
            imageId: cacheId,
            remoteUrl: widget.imageUrl,
            fit: widget.fit,
            alignment: widget.alignment,
            errorWidget: const SizedBox.shrink(),
          )
        : CachedNetworkImage(
            imageUrl:
                kIsWebBuild ? _proxiedUrl(widget.imageUrl) : widget.imageUrl,
            fit: widget.fit,
            alignment: widget.alignment,
            errorWidget: widget.errorWidget ??
                (BuildContext context, String url, Object error) =>
                    const SizedBox.shrink(),
          );

    // No active gyroscope (no sensor / not Android) — render the static image.
    if (_ticker == null) return image;

    // Scale up slightly so the edges stay hidden as the image shifts.
    return ClipRect(
      child: Transform.translate(
        offset: Offset(_currentX, _currentY),
        child: Transform.scale(
          scale: 1.1,
          child: image,
        ),
      ),
    );
  }
}
