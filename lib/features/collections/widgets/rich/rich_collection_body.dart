import 'package:core/models/collection.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../hero_image.dart';
import 'default_hero_assets.dart';
import 'hero_back_button.dart';

/// When [heroAbsolutePath] is not set, falls back to a bundled default
/// image, and to a transparent backdrop when none are bundled.
class RichHeroBanner extends StatelessWidget {
  const RichHeroBanner({
    required this.collection,
    this.heroAbsolutePath,
    this.onBack,
    super.key,
  });

  final Collection collection;

  final String? heroAbsolutePath;

  /// When set, the banner carries the screen's back control.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool isCompact = screen.width < 720;
    final double height = isCompact
        ? (screen.height * 0.24).clamp(180, 260)
        : (screen.height * 0.36).clamp(280, 400);

    final String? hero = heroAbsolutePath;
    final String? defaultHeroAsset =
        hero == null ? defaultHeroAssetForCollection(collection.id) : null;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (hero != null) ...<Widget>[
            HeroCoverImage(provider: heroImageProviderFor(hero)),
            const _LeftScrim(),
          ] else if (defaultHeroAsset != null) ...<Widget>[
            HeroCoverImage(provider: AssetImage(defaultHeroAsset)),
            const _LeftScrim(),
          ] else
            const _EmptyHeroBackground(),
          const _BottomFade(),
          Align(
            alignment: Alignment.centerLeft,
            child: _HeroContent(
              collection: collection,
              isCompact: isCompact,
            ),
          ),
          if (onBack != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: HeroBackButton(
                onTap: onBack!,
                decoration: BoxDecoration(
                  color: AppColors.scrim.withAlpha(0x99),
                  shape: BoxShape.circle,
                ),
                iconColor: AppColors.onOverlay,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fully transparent on purpose: the banner blends with whatever is painted
/// behind it while the banner height and text position stay stable.
class _EmptyHeroBackground extends StatelessWidget {
  const _EmptyHeroBackground();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Left-side gradient that keeps the text readable over the image.
class _LeftScrim extends StatelessWidget {
  const _LeftScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              AppColors.scrim.withAlpha(0xEB),
              AppColors.scrim.withAlpha(0xBF),
              AppColors.scrim.withAlpha(0x66),
              AppColors.scrim.withAlpha(0x00),
            ],
            stops: const <double>[0.0, 0.28, 0.50, 0.72],
          ),
        ),
      ),
    );
  }
}

/// Vertical fade over the bottom ~18%: smooth boundary with the plain grid.
class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.transparent,
              AppColors.background.withValues(alpha: 0.4),
              AppColors.background,
            ],
            stops: const <double>[0.82, 0.93, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.collection, required this.isCompact});

  final Collection collection;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final String? description = collection.description;
    final bool hasDescription = description != null && description.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? AppSpacing.md : AppSpacing.xl,
        0,
        isCompact ? AppSpacing.md : AppSpacing.xl,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? screen.width : 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              collection.name,
              style: AppTypography.h1.copyWith(
                color: AppColors.textPrimary,
                fontSize: isCompact ? 24 : 44,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: isCompact ? -0.4 : -0.8,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasDescription) ...<Widget>[
              SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
              Text(
                description,
                style: (isCompact ? AppTypography.bodySmall : AppTypography.body)
                    .copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
                maxLines: isCompact ? 3 : 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
