import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// One door of the personalization hub: a header that names the section and a
/// live preview underneath, the whole card opening the full screen.
class HubSectionCard extends StatelessWidget {
  const HubSectionCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.preview,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  /// Live content under the header; taps inside it still open the section.
  final Widget? preview;

  static const double _iconBox = 36;

  @override
  Widget build(BuildContext context) {
    final Widget? preview = this.preview;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: _iconBox,
                    height: _iconBox,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withAlpha(24),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: AppColors.brand),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          hint,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (preview != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                // The card is the one tap target; a poster or tile inside
                // must not swallow the press and go nowhere.
                IgnorePointer(child: preview),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
