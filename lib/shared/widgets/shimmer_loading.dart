// Shimmer-эффект загрузки без внешних зависимостей.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Базовый shimmer-блок с анимированным градиентом.
///
/// Используется как строительный блок для заглушек загрузки.
class ShimmerBox extends StatefulWidget {
  /// Создаёт shimmer-блок.
  const ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
    super.key,
  });

  /// Ширина блока.
  final double width;

  /// Высота блока.
  final double height;

  /// Радиус скругления углов.
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: const <Color>[
                AppColors.surface,
                AppColors.surfaceLight,
                AppColors.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Заглушка для постерной карточки (shimmer).
///
/// Прямоугольник 2:3 + две строки текста снизу.
class ShimmerPosterCard extends StatelessWidget {
  /// Создаёт shimmer-заглушку постерной карточки.
  const ShimmerPosterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: AppSpacing.radiusMd,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        ShimmerBox(width: 100, height: 14),
        SizedBox(height: AppSpacing.xs),
        ShimmerBox(width: 60, height: 11),
      ],
    );
  }
}

/// Заглушка для горизонтальной карточки списка (shimmer).
///
/// Квадрат-постер слева + три строки текста справа.
class ShimmerListTile extends StatelessWidget {
  /// Создаёт shimmer-заглушку горизонтальной карточки.
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          ShimmerBox(
            width: 64,
            height: 96,
            borderRadius: AppSpacing.radiusSm,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(width: 160, height: 16),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 120, height: 12),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
