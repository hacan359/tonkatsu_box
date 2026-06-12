// Shimmer loading effect without external dependencies.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Base shimmer block with an animated gradient.
///
/// Building block for loading placeholders.
class ShimmerBox extends StatefulWidget {
  /// Creates a shimmer block.
  const ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
    super.key,
  });

  /// Block width.
  final double width;

  /// Block height.
  final double height;

  /// Corner radius.
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

/// Poster card placeholder (shimmer).
///
/// A 2:3 rectangle plus two text lines below.
class ShimmerPosterCard extends StatelessWidget {
  /// Creates a poster card shimmer placeholder.
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

/// Tier list card placeholder (shimmer).
///
/// Icon on the left, two text lines, chevron on the right.
/// Mirrors the _TierListCard structure.
class ShimmerTierListCard extends StatelessWidget {
  /// Creates a tier list card shimmer placeholder.
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

/// Tier list detail screen placeholder (shimmer).
///
/// A few tier rows (colored label strip plus card placeholders).
class ShimmerTierListDetail extends StatelessWidget {
  /// Creates a tier list detail shimmer placeholder.
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

/// List screen placeholder: a column of [ShimmerListTile]s.
class ShimmerList extends StatelessWidget {
  /// Creates a list shimmer placeholder.
  const ShimmerList({this.itemCount = 3, super.key});

  /// Number of placeholder tiles.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const ShimmerListTile(),
    );
  }
}

/// Poster grid placeholder: a grid of [ShimmerPosterCard]s.
///
/// The max-extent delegate adapts the column count to the available
/// width on its own, so the skeleton stays close to the real grid
/// without mirroring its breakpoint logic.
class ShimmerPosterGrid extends StatelessWidget {
  /// Creates a poster grid shimmer placeholder.
  const ShimmerPosterGrid({this.itemCount = 12, super.key});

  /// Number of placeholder cards.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        crossAxisSpacing: AppSpacing.gridGap,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.55,
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const ShimmerPosterCard(),
    );
  }
}

/// Horizontal list tile placeholder (shimmer).
///
/// Poster on the left plus three text lines on the right.
class ShimmerListTile extends StatelessWidget {
  /// Creates a horizontal list tile shimmer placeholder.
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
