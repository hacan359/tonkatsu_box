// Дропдаун выбора источника данных (Movies, TV, Anime, Games).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/search_source.dart';
import '../sources/search_sources.dart';

/// Дропдаун для выбора источника поиска.
class SourceDropdown extends StatelessWidget {
  /// Создаёт [SourceDropdown].
  const SourceDropdown({
    required this.current,
    required this.onChanged,
    super.key,
  });

  /// Текущий источник.
  final SearchSource current;

  /// Callback при выборе нового источника.
  final ValueChanged<SearchSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return PopupMenuButton<String>(
      onSelected: (String id) {
        final SearchSource source = getSearchSourceById(id);
        if (source.id != current.id) {
          onChanged(source);
        }
      },
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      color: AppColors.surface,
      itemBuilder: (BuildContext context) {
        return searchSources.map((SearchSource source) {
          final bool isSelected = source.id == current.id;
          return PopupMenuItem<String>(
            value: source.id,
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  source.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.brand
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  source.label(l),
                  style: AppTypography.body.copyWith(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(current.icon, size: 16, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              current.label(l),
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
