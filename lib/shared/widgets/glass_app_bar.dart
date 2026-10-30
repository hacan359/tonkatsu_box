import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'screen_app_bar.dart';

/// Pill height plus the vertical margins; the safe area is added on top.
const double kGlassAppBarHeight = 56;

const double _pillHeight = 40;
const double _blurSigma = 14;

/// Two frosted pills floating over the body: back on the left, actions on
/// the right. Meant for a `Scaffold` with `extendBodyBehindAppBar`.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({this.actions = const <Widget>[], super.key});

  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kGlassAppBarHeight);

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: kGlassAppBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: (kGlassAppBarHeight - _pillHeight) / 2,
          ),
          child: Row(
            children: <Widget>[
              if (canPop)
                GlassPill(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        size: kScreenAppBarIconSize),
                    color: AppColors.textSecondary,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              const Spacer(),
              if (actions.isNotEmpty)
                GlassPill(
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted capsule: the backdrop blurs through a translucent surface tint.
class GlassPill extends StatelessWidget {
  const GlassPill({
    required this.child,
    this.height = _pillHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    this.borderRadius,
    this.bordered = true,
    super.key,
  });

  final Widget child;

  /// `null` lets the child decide (a frame zone sized by its parent).
  final double? height;
  final EdgeInsetsGeometry padding;

  /// Defaults to a full capsule; a zone grown out of the frame rounds only
  /// the corners that face the content.
  final BorderRadius? borderRadius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular((height ?? _pillHeight) / 2);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(150),
            borderRadius: radius,
            border: bordered
                ? Border.all(color: AppColors.surfaceBorder.withAlpha(110))
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
