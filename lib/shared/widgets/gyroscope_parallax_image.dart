// Изображение с параллакс-эффектом на основе гироскопа (только Android).

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Максимальное смещение параллакса в пикселях.
const double _kMaxOffset = 20.0;

/// Коэффициент сглаживания (lerp) — чем меньше, тем плавнее.
const double _kSmoothing = 0.08;

/// Изображение с параллакс-эффектом при наклоне устройства.
///
/// На Android подписывается на гироскоп и слегка сдвигает изображение
/// в противоположную сторону наклона, создавая иллюзию глубины.
/// На других платформах рендерит обычное [CachedNetworkImage].
class GyroscopeParallaxImage extends StatefulWidget {
  /// Создаёт [GyroscopeParallaxImage].
  const GyroscopeParallaxImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorWidget,
    super.key,
  });

  /// URL изображения.
  final String imageUrl;

  /// Как изображение вписывается в доступное пространство.
  final BoxFit fit;

  /// Выравнивание изображения.
  final Alignment alignment;

  /// Виджет при ошибке загрузки.
  final Widget Function(BuildContext, String, Object)? errorWidget;

  @override
  State<GyroscopeParallaxImage> createState() =>
      _GyroscopeParallaxImageState();
}

class _GyroscopeParallaxImageState extends State<GyroscopeParallaxImage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _subscription;
  late final AnimationController _ticker;

  // Целевое смещение (из гироскопа)
  double _targetX = 0;
  double _targetY = 0;

  // Текущее смещение (сглаженное)
  double _currentX = 0;
  double _currentY = 0;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid) return;

    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
    _ticker.animateTo(1, duration: Duration.zero);

    _subscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 16),
    ).listen(_onGyroscope);
  }

  void _onGyroscope(GyroscopeEvent event) {
    // Гироскоп отдаёт угловую скорость (рад/с).
    // Интегрируем в смещение и кламплим.
    _targetX = (_targetX + event.y * 1.5).clamp(-_kMaxOffset, _kMaxOffset);
    _targetY = (_targetY - event.x * 1.5).clamp(-_kMaxOffset, _kMaxOffset);

    // Запускаем тикер если остановлен
    if (!_ticker.isAnimating) {
      _ticker.animateTo(
        _ticker.value + 1,
        duration: const Duration(seconds: 10),
      );
    }
  }

  void _onTick() {
    // Плавное сглаживание через lerp
    final double newX = _currentX + (_targetX - _currentX) * _kSmoothing;
    final double newY = _currentY + (_targetY - _currentY) * _kSmoothing;

    if ((newX - _currentX).abs() < 0.01 && (newY - _currentY).abs() < 0.01) {
      // Достаточно близко — остановить тикер
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
    if (Platform.isAndroid) {
      _ticker.dispose();
    }
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

    if (!Platform.isAndroid) return image;

    // Масштабируем чуть больше чтобы при смещении не было видно краёв
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
