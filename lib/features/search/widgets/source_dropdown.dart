import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/search_source.dart';
import '../sources/search_sources.dart';

/// Search source dropdown with options grouped by provider
/// (TMDB, IGDB, AniList, VNDB).
class SourceDropdown extends StatelessWidget {
  const SourceDropdown({
    required this.current,
    required this.onChanged,
    super.key,
  });

  final SearchSource current;

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
      itemBuilder: (BuildContext context) => _buildGroupedItems(l),
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
            _sourceGlyph(
              asset: current.iconAsset,
              icon: current.groupIcon,
              size: 22,
              color: AppColors.brand,
            ),
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

  List<PopupMenuEntry<String>> _buildGroupedItems(S l) {
    final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];

    for (final SourceGroupEntry group in groupedSearchSources) {
      // Divider between groups, but not before the first one.
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider(height: 8));
      }

      // Group header, not selectable.
      items.add(PopupMenuItem<String>(
        enabled: false,
        height: 28,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _sourceGlyph(
              asset: group.groupIconAsset,
              icon: group.groupIcon,
              size: 20,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              group.groupName,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ));

      for (final SearchSource source in group.sources) {
        final bool isSelected = source.id == current.id;
        items.add(PopupMenuItem<String>(
          value: source.id,
          height: 36,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              source.label(l),
              style: AppTypography.body.copyWith(
                color: isSelected
                    ? AppColors.brand
                    : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ));
      }
    }

    return items;
  }
}

/// Renders the brand PNG when [asset] is set, falling back to a Material icon.
Widget _sourceGlyph({
  required String? asset,
  required IconData icon,
  required double size,
  required Color color,
}) {
  if (asset != null) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
  return Icon(icon, size: size, color: color);
}
