// Image with a gyroscope-driven parallax effect (Android only).

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../constants/platform_features.dart';

/// Max parallax offset in pixels.
const double _kMaxOffset = 20.0;

/// Lerp smoothing factor — lower is smoother.
const double _kSmoothing = 0.08;

/// Image that shifts slightly with device tilt to fake depth.
///
/// Subscribes to the gyroscope where available; otherwise (no sensor, or a
/// non-Android platform) it renders a plain [CachedNetworkImage].
class GyroscopeParallaxImage extends StatefulWidget {
  /// Creates a [GyroscopeParallaxImage].
  const GyroscopeParallaxImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorWidget,
    this.gyroscopeStream,
    super.key,
  });

  /// Image URL.
  final String imageUrl;

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
    final Stream<GyroscopeEvent>? stream = widget.gyroscopeStream ??
        (!kIsWebBuild && Platform.isAndroid
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

  @override
  Widget build(BuildContext context) {
    final Widget image = CachedNetworkImage(
      imageUrl: widget.imageUrl,
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
