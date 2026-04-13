// Анимированный «жидкий» индикатор выбранного таба.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Анимированный круглый blob, который «переливается» от одного пункта
/// к другому.
///
/// Работает поверх списка иконок через [Stack]. Используется в вертикальном
/// боковом меню ([AppSidebar]) и в горизонтальном нижнем меню ([AppBottomBar]).
///
/// При смене [selectedIndex]:
/// - blob перемещается из старой позиции в новую (`Curves.easeInOutCubic`);
/// - вытягивается по направлению движения и сжимается поперёк (squash/stretch);
/// - в финале возвращается к круглой форме с лёгким elastic-отскоком.
///
/// Цвет — [AppColors.brand] (приглушённый). Мягкое свечение через [BoxShadow].
class LiquidIndicator extends StatefulWidget {
  /// Создаёт [LiquidIndicator].
  const LiquidIndicator({
    required this.selectedIndex,
    required this.itemExtent,
    required this.crossExtent,
    this.axis = Axis.vertical,
    this.size = 40,
    super.key,
  });

  /// Индекс активного пункта (0..n-1).
  final int selectedIndex;

  /// Размер одной ячейки вдоль основной оси.
  ///
  /// - Для [Axis.vertical] — высота ячейки.
  /// - Для [Axis.horizontal] — ширина ячейки.
  final double itemExtent;

  /// Размер контейнера поперёк основной оси (для центрирования blob).
  ///
  /// - Для [Axis.vertical] — ширина бокового меню.
  /// - Для [Axis.horizontal] — высота нижнего меню.
  final double crossExtent;

  /// Направление, вдоль которого перемещается blob.
  final Axis axis;

  /// Диаметр круга в «спокойном» состоянии.
  final double size;

  @override
  State<LiquidIndicator> createState() => _LiquidIndicatorState();
}

class _LiquidIndicatorState extends State<LiquidIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _fromOffset;
  late double _toOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fromOffset = _offsetFor(widget.selectedIndex);
    _toOffset = _fromOffset;
    // Сразу в конечном состоянии (без анимации на старте).
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant LiquidIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.axis != oldWidget.axis ||
        widget.itemExtent != oldWidget.itemExtent ||
        widget.crossExtent != oldWidget.crossExtent) {
      _fromOffset = _offsetFor(oldWidget.selectedIndex);
      _toOffset = _offsetFor(widget.selectedIndex);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _offsetFor(int index) {
    return widget.itemExtent * index + (widget.itemExtent - widget.size) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;

        // Позиция: плавный ease in-out на всём протяжении.
        final double posT = Curves.easeInOutCubic.transform(t);
        final double mainOffset = _fromOffset + (_toOffset - _fromOffset) * posT;
        final double crossOffset = (widget.crossExtent - widget.size) / 2;

        // Squash/stretch: 0..0.6 — нарастание, 0.6..1.0 — возврат.
        final double squashT;
        if (t < 0.6) {
          squashT = t / 0.6;
        } else {
          squashT = 1 - ((t - 0.6) / 0.4);
        }
        final double relaxed = Curves.easeOutBack.transform(
          1 - squashT.clamp(0.0, 1.0),
        );

        // Амплитуда зависит от пройденного расстояния.
        final double distance = (_toOffset - _fromOffset).abs();
        final double amplitude =
            (distance / widget.itemExtent).clamp(0.0, 3.0) * 0.42;

        // Вдоль основной оси — растяжение, поперёк — сжатие.
        final double scaleMain = 1 + amplitude * (1 - relaxed);
        final double scaleCross = 1 - amplitude * 0.5 * (1 - relaxed);

        final bool vertical = widget.axis == Axis.vertical;
        final double top = vertical ? mainOffset : crossOffset;
        final double left = vertical ? crossOffset : mainOffset;
        final double scaleX = vertical ? scaleCross : scaleMain;
        final double scaleY = vertical ? scaleMain : scaleCross;

        return Positioned(
          top: top,
          left: left,
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brand.withAlpha(180),
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.brand.withAlpha(60),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}
