// Centre navigation button: the app logo. Sits inline in the nav row/rail.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

/// The app logo as a nav item. Fills the `width × height` cell it is given
/// (matching [NavIconButton]) and is focusable for gamepad via [InkResponse].
class NavCenterButton extends StatelessWidget {
  /// Creates a [NavCenterButton].
  const NavCenterButton({
    required this.onTap,
    required this.tooltip,
    required this.width,
    required this.height,
    super.key,
  });

  /// Tap callback.
  final VoidCallback onTap;

  /// Tooltip / accessibility label.
  final String tooltip;

  /// Cell width.
  final double width;

  /// Cell height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final double cell = math.min(width, height);
    final double logoSize = math.min(cell * 0.78, 36);

    return SizedBox(
      width: width,
      height: height,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: InkResponse(
          onTap: onTap,
          radius: cell * 0.5,
          containedInkWell: false,
          highlightShape: BoxShape.circle,
          child: Center(
            child: Image.asset(
              AppAssets.logo,
              width: logoSize,
              height: logoSize,
            ),
          ),
        ),
      ),
    );
  }
}
