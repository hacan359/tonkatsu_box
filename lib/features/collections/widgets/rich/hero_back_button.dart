import 'package:flutter/material.dart';

/// Back control for the rich hero banners; each style passes its own
/// decoration so the arrow matches the banner's look.
class HeroBackButton extends StatelessWidget {
  const HeroBackButton({
    required this.onTap,
    required this.decoration,
    required this.iconColor,
    this.angle = 0,
    this.size = defaultSize,
    super.key,
  });

  static const double defaultSize = 36;

  final VoidCallback onTap;
  final BoxDecoration decoration;
  final Color iconColor;

  /// Rotation in radians, for the hand-placed comic/sticker looks.
  final double angle;

  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder:
            decoration.shape == BoxShape.circle ? const CircleBorder() : null,
        borderRadius:
            decoration.borderRadius?.resolve(Directionality.maybeOf(context)),
        child: Container(
          width: size,
          height: size,
          decoration: decoration,
          child: Center(
            child: Icon(Icons.arrow_back, size: size * 0.5, color: iconColor),
          ),
        ),
      ),
    );
    final Widget rotated =
        angle == 0 ? button : Transform.rotate(angle: angle, child: button);
    return Tooltip(
      message: MaterialLocalizations.of(context).backButtonTooltip,
      child: rotated,
    );
  }
}
