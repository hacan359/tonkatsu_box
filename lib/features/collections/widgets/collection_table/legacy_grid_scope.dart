// trina_grid still renders the in-SDK Material, which has no replacement here.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

/// The in-SDK Material ancestor and checkbox theme trina's own widgets look
/// up; the app's material_ui Material and Theme are invisible to them.
class LegacyGridScope extends StatelessWidget {
  const LegacyGridScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return legacy.Theme(
      data: legacy.Theme.of(context).copyWith(
        checkboxTheme: legacy.CheckboxThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          side: BorderSide(color: AppColors.textTertiary, width: 1.5),
          visualDensity: legacy.VisualDensity.compact,
          materialTapTargetSize: legacy.MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: legacy.Material(
        type: legacy.MaterialType.transparency,
        child: child,
      ),
    );
  }
}
