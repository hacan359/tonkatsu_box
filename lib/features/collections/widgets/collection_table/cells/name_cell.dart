import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_typography.dart';

/// Name + genres cell; tapping the name opens the item (the grid itself opens
/// items on double tap, this keeps single-tap-on-name working too).
class NameCell extends StatelessWidget {
  const NameCell({
    required this.name,
    required this.genres,
    required this.onTap,
    super.key,
  });

  final String name;
  final String? genres;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            name,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (genres != null && genres!.isNotEmpty)
            Text(
              genres!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
