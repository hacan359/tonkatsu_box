import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../sources/search_sources.dart';
import '../utils/filter_ui.dart';

/// First segment of the filter bar: what the user is looking for. Replaces the
/// old per-provider source picker — providers are now chosen below, if at all.
class MediaTypeChevron extends StatelessWidget {
  const MediaTypeChevron({
    required this.mediaType,
    required this.accentColor,
    required this.isLast,
    required this.onChanged,
    super.key,
  });

  final MediaType mediaType;
  final Color accentColor;
  final bool isLast;
  final ValueChanged<MediaType> onChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return DropdownChevronSegment<MediaType>(
      label: mediaType.localizedPluralLabel(l),
      subtitle: l.searchWhatToFind,
      icon: Icons.category_outlined,
      selected: true,
      accentColor: accentColor,
      isFirst: true,
      isLast: isLast,
      menuBuilder: (BuildContext _) => <PopupMenuEntry<MediaType>>[
        for (final MediaType type in searchableMediaTypes)
          PopupMenuItem<MediaType>(
            value: type,
            height: 36,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    type.localizedPluralLabel(l),
                    style: AppTypography.body.copyWith(
                      color: type == mediaType
                          ? filterAccentForType(type)
                          : AppColors.textPrimary,
                      fontWeight: type == mediaType
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${searchSourcesFor(type).length}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
      ],
      onSelected: (MediaType? value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
