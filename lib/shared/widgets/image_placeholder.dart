import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'glass_panel.dart';

/// What shows where a picture is still loading or missing: the same faint
/// glass tile as the cards, so nothing flashes a solid colour.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    this.icon = Icons.image_outlined,
    this.iconSize = 32,
    this.showIcon = true,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    // A Container with no child fills bounded space and collapses in an
    // unbounded row, which a SizedBox.expand would not.
    return Container(
      color: glassTileColor(),
      child: showIcon
          ? Center(
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.textTertiary.withAlpha(160),
              ),
            )
          : null,
    );
  }
}
