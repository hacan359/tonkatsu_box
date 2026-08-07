import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../models/common_filter.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../providers/discover_provider.dart';
import '../utils/filter_ui.dart';
import 'filter_bar_compact.dart';
import 'filter_control.dart';
import 'media_type_chevron.dart';
import 'filter_sheet.dart';

/// Pinned so the row doesn't jiggle when the media-type label width changes.
const double kMediaTypeSegmentWidth = 160;

const double _kCustomizeWidth = 44;

/// Media-type-first filter bar. Narrow screens get a separate layout — see
/// [CompactFilterBar].
class FilterBar extends ConsumerWidget {
  const FilterBar({
    this.onBeforeFilterChange,
    this.onDiscoverCustomize,
    super.key,
  });

  final VoidCallback? onBeforeFilterChange;

  /// Opens Discover Customize (TMDB feeds, no active query). Hidden when null.
  final VoidCallback? onDiscoverCustomize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState state = ref.watch(browseProvider);
    final Color accent = filterAccentForType(state.mediaType);
    final bool showCustomize = onDiscoverCustomize != null &&
        !state.hasSearchQuery &&
        discoverMediaTypes.contains(state.mediaType);

    if (isCompactScreen(context)) {
      return CompactFilterBar(
        state: state,
        accent: accent,
        onDiscoverCustomize: showCustomize ? onDiscoverCustomize : null,
      );
    }

    final MediaTypeFilters filters = state.filters;
    final bool single = state.sources.length == 1;
    final List<SearchFilter> barFilters = single
        ? filters.own[state.sources.first.id] ?? const <SearchFilter>[]
        : filters.common;
    final bool showSheetButton = !single && filters.ownCount > 0;
    // Options must come from the provider the sort applies to: `SCORE_DESC`
    // means nothing to MangaDex.
    final List<BrowseSortOption> sortOptions =
        state.sortSource?.sortOptions ?? const <BrowseSortOption>[];

    int trailingCount = 0;
    if (sortOptions.isNotEmpty) trailingCount++;
    if (showSheetButton) trailingCount++;
    if (showCustomize) trailingCount++;

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: kMediaTypeSegmentWidth,
              child: MediaTypeChevron(
                mediaType: state.mediaType,
                accentColor: accent,
                isLast: barFilters.isEmpty && trailingCount == 0,
                onChanged: (MediaType type) =>
                    ref.read(browseProvider.notifier).setMediaType(type),
              ),
            ),
            for (int i = 0; i < barFilters.length; i++)
              Expanded(
                child: FilterChevron(
                  key: ValueKey<String>(
                    '${state.mediaType.name}_${barFilters[i].cacheKey}',
                  ),
                  filter: barFilters[i],
                  value: _valueOf(state, barFilters[i]),
                  accentColor: accent,
                  isLast: trailingCount == 0 && i == barFilters.length - 1,
                  onPick: (Object? value, CommonSelection? selection) {
                    onBeforeFilterChange?.call();
                    _apply(ref, state, barFilters[i], value, selection);
                  },
                ),
              ),
            if (showSheetButton)
              SizedBox(
                width: 132,
                child: _SheetButton(
                  accent: accent,
                  count: state.ownFilterCount,
                  total: filters.ownCount,
                  isLast: sortOptions.isEmpty && !showCustomize,
                  onTap: () => showFilterSheet(context),
                ),
              ),
            if (sortOptions.isNotEmpty)
              Expanded(
                child: _SortChevron(
                  options: sortOptions,
                  current: state.effectiveSortBy,
                  disabledReason: _sortDisabledReason(state, S.of(context)),
                  accentColor: accent,
                  isLast: !showCustomize,
                  onChanged: (String sortBy) =>
                      ref.read(browseProvider.notifier).setSort(sortBy),
                ),
              ),
            if (showCustomize)
              SizedBox(
                width: _kCustomizeWidth,
                child: ChevronSegment(
                  label: S.of(context).discoverCustomize,
                  icon: Icons.tune,
                  selected: false,
                  accentColor: accent,
                  isFirst: false,
                  isLast: true,
                  onTap: onDiscoverCustomize!,
                  tintWhenInactive: true,
                  compact: true,
                ),
              ),
            if (state.hasFilters)
              _ClearButton(
                onTap: () => ref.read(browseProvider.notifier).clearFilters(),
              ),
          ],
        ),
      ),
    );
  }

  static Object? _valueOf(BrowseState state, SearchFilter filter) {
    if (filter is CommonFilter) {
      return state.commonSelections[filter.key]?.semantic;
    }
    return state.ownFilterValues[state.sources.first.id]?[filter.key];
  }

  static void _apply(
    WidgetRef ref,
    BrowseState state,
    SearchFilter filter,
    Object? value,
    CommonSelection? selection,
  ) {
    final BrowseNotifier notifier = ref.read(browseProvider.notifier);
    if (filter is CommonFilter) {
      notifier.setCommonFilter(filter.key, selection);
      return;
    }
    notifier.setOwnFilter(state.sources.first.id, filter.key, value);
  }

  static String? _sortDisabledReason(BrowseState state, S l) {
    if (state.canSort) return null;
    return state.sortIgnoredDuringSearch
        ? l.searchSortUnavailableInSearch
        : l.searchSortNeedsSingleSource;
  }
}

/// "Filters (N)" segment opening the per-source sheet.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.accent,
    required this.count,
    required this.total,
    required this.isLast,
    required this.onTap,
  });

  final Color accent;
  final int count;
  final int total;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return ChevronSegment(
      label: count > 0
          ? '${l.collectionFilterFilters} ($count)'
          : '${l.collectionFilterFilters} · $total',
      icon: Icons.tune,
      selected: count > 0,
      accentColor: accent,
      isFirst: false,
      isLast: isLast,
      onTap: onTap,
      tintWhenInactive: true,
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 40,
          child: Icon(Icons.close, size: 18, color: AppColors.error),
        ),
      ),
    );
  }
}

class _SortChevron extends StatelessWidget {
  const _SortChevron({
    required this.options,
    required this.current,
    required this.disabledReason,
    required this.accentColor,
    required this.isLast,
    required this.onChanged,
  });

  final List<BrowseSortOption> options;
  final String current;

  /// Why sorting is off, shown as a tooltip; null means it is available.
  final String? disabledReason;

  final Color accentColor;
  final bool isLast;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    String currentLabel = l.sort;
    for (final BrowseSortOption option in options) {
      if (option.apiValue == current) {
        currentLabel = option.label(l);
        break;
      }
    }

    final String? reason = disabledReason;
    if (reason != null) {
      return Tooltip(
        message: reason,
        child: ChevronSegment(
          label: currentLabel,
          subtitle: l.sort,
          icon: Icons.sort,
          selected: false,
          accentColor: accentColor,
          isFirst: false,
          isLast: isLast,
          onTap: () {},
        ),
      );
    }

    return DropdownChevronSegment<Object>(
      label: currentLabel,
      subtitle: l.sort,
      icon: Icons.sort,
      selected: false,
      accentColor: accentColor,
      isFirst: false,
      isLast: isLast,
      menuBuilder: (BuildContext ctx) {
        final S menuL = S.of(ctx);
        return <PopupMenuEntry<Object>>[
          for (final BrowseSortOption option in options)
            PopupMenuItem<Object>(
              value: option.apiValue,
              height: 36,
              child: Text(
                option.label(menuL),
                style: AppTypography.body.copyWith(
                  color: option.apiValue == current
                      ? accentColor
                      : AppColors.textPrimary,
                  fontWeight: option.apiValue == current
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
        ];
      },
      onSelected: (Object? value) {
        if (value is String) onChanged(value);
      },
    );
  }
}
