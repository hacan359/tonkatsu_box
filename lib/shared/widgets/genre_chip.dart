import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_panel.dart';

/// Genre pill; [accent] tints it with the media type's color, otherwise it
/// sits quietly on the surface tone.
class GenreChip extends StatelessWidget {
  const GenreChip(this.label, {this.accent, super.key});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color? accent = this.accent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: glassChipColor(tint: accent, tintAlpha: 60),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: accent ?? AppColors.textSecondary,
          fontWeight: accent != null ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}
