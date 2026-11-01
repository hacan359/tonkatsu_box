import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'screen_app_bar.dart';

/// Pill height plus the vertical margins; the safe area is added on top.
const double kGlassAppBarHeight = 56;

const double _pillHeight = 40;
const double _blurSigma = 14;
const double _pillPadding = AppSpacing.xs;

/// Same footprint as a padded pill around one icon button.
const double _backPillWidth = _pillHeight + _pillPadding * 2;

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
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        size: kScreenAppBarIconSize),
                    color: AppColors.textSecondary,
                    // The button is the whole pill, so hover and press tint
                    // the capsule edge to edge instead of a circle inside it.
                    style: IconButton.styleFrom(
                      shape: const StadiumBorder(),
                      fixedSize: const Size(_backPillWidth, _pillHeight),
                      padding: EdgeInsets.zero,
                    ),
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
    this.padding = const EdgeInsets.symmetric(horizontal: _pillPadding),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_pillHeight / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          height: _pillHeight,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(150),
            borderRadius: BorderRadius.circular(_pillHeight / 2),
            border: Border.all(color: AppColors.surfaceBorder.withAlpha(110)),
          ),
          child: child,
        ),
      ),
    );
  }
}
