import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Step header: a glowing emblem (logo [asset] or [icon]) over a radial halo,
/// then a title and optional subtitle.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({
    required this.title,
    this.asset,
    this.icon,
    this.subtitle,
    this.accent = AppColors.brand,
    this.compact = false,
    super.key,
  }) : assert(asset != null || icon != null, 'provide an asset or an icon');

  final String? asset;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double emblem = compact ? 56 : 76;
    final double halo = emblem * 2.0;

    return Column(
      children: <Widget>[
        SizedBox(
          width: halo,
          height: halo,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[accent.withAlpha(70), accent.withAlpha(0)],
                  ),
                ),
                child: SizedBox(width: halo, height: halo),
              ),
              if (asset != null)
                Image.asset(asset!, width: emblem, height: emblem)
              else
                Icon(icon, size: emblem * 0.7, color: accent),
            ],
          ),
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          title,
          style: AppTypography.h1.copyWith(fontSize: compact ? 20 : 24),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: compact ? 12 : 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
