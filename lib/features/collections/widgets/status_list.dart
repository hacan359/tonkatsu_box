import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/item_status_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Vertical status picker with labels, for the desktop card's side column
/// where an icon-only row would leave the meaning to tooltips.
class StatusList extends StatelessWidget {
  const StatusList({
    required this.status,
    required this.mediaType,
    required this.onChanged,
    super.key,
  });

  final ItemStatus status;
  final MediaType mediaType;
  final void Function(ItemStatus) onChanged;

  static const int _selectedAlpha = 46;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ItemStatus s in ItemStatus.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Material(
              color: s == status
                  ? s.color.withAlpha(_selectedAlpha)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                onTap: () => onChanged(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(s.materialIcon, size: 18, color: s.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.localizedLabel(l, mediaType),
                          style: AppTypography.bodySmall.copyWith(
                            color: s == status
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: s == status
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (s == status)
                        Icon(Icons.check, size: 16, color: s.color),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
