import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../providers/browse_provider.dart';
import 'filter_sheet.dart';
import 'media_type_chevron.dart';

/// Deliberately two segments: a phone already spends ~82px of chrome above the
/// grid, so sources are picked in the sheet instead of a row of their own.
class CompactFilterBar extends ConsumerWidget {
  const CompactFilterBar({
    required this.state,
    required this.accent,
    super.key,
  });

  final BrowseState state;
  final Color accent;

  static const double _kTypeWidth = 128;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final int activeFilters = state.activeFilterCount;
    final bool multiSource = state.sources.length > 1;

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _kTypeWidth,
              child: MediaTypeChevron(
                mediaType: state.mediaType,
                accentColor: accent,
                isLast: false,
                onChanged: (MediaType type) =>
                    ref.read(browseProvider.notifier).setMediaType(type),
              ),
            ),
            Expanded(
              child: ChevronSegment(
                label: activeFilters > 0
                    ? '${l.collectionFilterFilters} ($activeFilters)'
                    : l.collectionFilterFilters,
                subtitle: multiSource
                    ? '${state.activeSources.length}/${state.sources.length}'
                        ' ${l.searchSourcesLabel}'
                    : null,
                icon: Icons.tune,
                selected: activeFilters > 0,
                accentColor: accent,
                isFirst: false,
                isLast: true,
                onTap: () => showFilterSheet(context),
                tintWhenInactive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
