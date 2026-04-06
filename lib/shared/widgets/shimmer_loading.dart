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

/// Заглушка для карточки тир-листа в списке (shimmer).
///
/// Иконка слева + две строки текста + chevron справа.
/// Повторяет структуру _TierListCard.
class ShimmerTierListCard extends StatelessWidget {
  /// Создаёт shimmer-заглушку карточки тир-листа.
  const ShimmerTierListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: AppColors.surfaceLight,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            ShimmerBox(width: 32, height: 32, borderRadius: AppSpacing.radiusSm),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 160, height: 16),
                  SizedBox(height: AppSpacing.xs),
                  ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            ShimmerBox(width: 24, height: 24, borderRadius: AppSpacing.radiusSm),
          ],
        ),
      ),
    );
  }
}

/// Заглушка для экрана деталей тир-листа (shimmer).
///
/// Несколько тир-рядов (цветная полоска + карточки-заглушки).
class ShimmerTierListDetail extends StatelessWidget {
  /// Создаёт shimmer-заглушку деталей тир-листа.
  const ShimmerTierListDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const <Widget>[
        _ShimmerTierRow(width: 80),
        SizedBox(height: AppSpacing.sm),
        _ShimmerTierRow(width: 120),
        SizedBox(height: AppSpacing.sm),
        _ShimmerTierRow(width: 60),
        SizedBox(height: AppSpacing.sm),
        _ShimmerTierRow(width: 100),
        SizedBox(height: AppSpacing.lg),
        // Unranked pool header
        ShimmerBox(width: 140, height: 16),
        SizedBox(height: AppSpacing.sm),
        // Unranked items grid
        _ShimmerUnrankedPool(),
      ],
    );
  }
}

class _ShimmerTierRow extends StatelessWidget {
  const _ShimmerTierRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Tier label
        ShimmerBox(
          width: width,
          height: 56,
          borderRadius: AppSpacing.radiusSm,
        ),
        const SizedBox(width: AppSpacing.sm),
        // Item placeholders
        const ShimmerBox(width: 48, height: 56, borderRadius: AppSpacing.radiusSm),
        const SizedBox(width: AppSpacing.xs),
        const ShimmerBox(width: 48, height: 56, borderRadius: AppSpacing.radiusSm),
        const SizedBox(width: AppSpacing.xs),
        const ShimmerBox(width: 48, height: 56, borderRadius: AppSpacing.radiusSm),
      ],
    );
  }
}

class _ShimmerUnrankedPool extends StatelessWidget {
  const _ShimmerUnrankedPool();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: List<Widget>.generate(
        6,
        (_) => const ShimmerBox(
          width: 48,
          height: 56,
          borderRadius: AppSpacing.radiusSm,
        ),
      ),
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
