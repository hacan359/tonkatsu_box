// Chevron filter bar для экрана поиска.
//
// Первый шеврон — выпадающий список источников (цвет по группе).
// Остальные шевроны — dropdown фильтры + sort текущего источника.
// Clear кнопка в конце при активных фильтрах.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../sources/search_sources.dart';
import '../utils/filter_ui.dart';
import 'filter_dropdown.dart';
import 'filter_sheet.dart';

/// Фикс ширина первого (Source) шеврона — чтобы не «прыгал» остальной ряд
/// при переключении источника с разной длиной label.
const double _kSourceWidth = 130;

/// Фикс ширина компактного Customize-шеврона (иконка с Tooltip).
const double _kCustomizeWidth = 44;

/// Chevron filter bar для Browse mode.
///
/// `[Source ▾][Filter1 ▾][Filter2 ▾][Sort ▾][Customize?][×?]`
/// Всё в одну строку на всю ширину. Customize показывается для TMDB
/// источников без активного запроса; Clear — при активных фильтрах.
class FilterBar extends ConsumerWidget {
  /// Создаёт [FilterBar].
  const FilterBar({
    this.onBeforeFilterChange,
    this.onDiscoverCustomize,
    super.key,
  });

  /// Вызывается перед применением фильтра.
  final VoidCallback? onBeforeFilterChange;

  /// Открыть «Discover Customize» (TMDB-источники без активного запроса).
  /// Если `null` — сегмент не показывается.
  final VoidCallback? onDiscoverCustomize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState browseState = ref.watch(browseProvider);
    final SearchSource source = browseState.source;
    final List<SearchFilter> filters = source.filters;
    final bool hasSort = source.sortOptions.isNotEmpty;
    final bool hasActiveFilters = browseState.filterValues.values
        .any((Object? v) => v != null);
    // Discover Customize — это настройка самого фида (фильтры/сортировка),
    // поэтому активные фильтры его НЕ скрывают. Скрываем только при
    // текстовом запросе, когда фид превращается в результаты поиска.
    final bool showCustomize = onDiscoverCustomize != null &&
        !browseState.hasSearchQuery &&
        source.groupId == 'tmdb';
    final Color accent = filterAccentForGroup(source.groupId);

    // На узких экранах: Source + кнопка «Фильтры (N)» + (опционально)
    // Customize-иконка вместо chevron-ряда.
    if (isCompactScreen(context)) {
      return _CompactBar(
        source: source,
        accent: accent,
        activeFilterCount: _countActive(browseState.filterValues),
        onSourceChanged: (String id) =>
            ref.read(browseProvider.notifier).setSource(id),
        onOpenFilters: () => showFilterSheet(context),
        onDiscoverCustomize: showCustomize ? onDiscoverCustomize : null,
      );
    }

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            // Source dropdown (первый, всегда selected, фикс ширина чтобы
            // не прыгало при смене источника).
            SizedBox(
              width: _kSourceWidth,
              child: _SourceDropdownChevron(
                source: source,
                accentColor: accent,
                isLast: filters.isEmpty && !hasSort && !showCustomize,
                onSourceChanged: (String id) {
                  ref.read(browseProvider.notifier).setSource(id);
                },
              ),
            ),
            // Фильтры.
            for (int i = 0; i < filters.length; i++)
              Expanded(
                child: _FilterDropdownChevron(
                  key: ValueKey<String>(
                    '${source.id}_${filters[i].cacheKey}',
                  ),
                  filter: filters[i],
                  value: browseState.filterValues[filters[i].key],
                  accentColor: accent,
                  isLast: !hasSort &&
                      !showCustomize &&
                      i == filters.length - 1,
                  onChanged: (Object? value) {
                    onBeforeFilterChange?.call();
                    ref
                        .read(browseProvider.notifier)
                        .setFilter(filters[i].key, value);
                  },
                ),
              ),
            // Sort.
            if (hasSort)
              Expanded(
                child: _SortDropdownChevron(
                  options: source.sortOptions,
                  current: browseState.effectiveSortBy,
                  enabled: !browseState.hasSearchQuery ||
                      source.supportsSortDuringSearch,
                  accentColor: accent,
                  isLast: !showCustomize,
                  onChanged: (String sortBy) {
                    ref.read(browseProvider.notifier).setSort(sortBy);
                  },
                ),
              ),
            // Discover Customize (TMDB, без активного запроса) —
            // компактная иконка с Tooltip, не растягивается.
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
            // Clear.
            if (hasActiveFilters)
              _ClearButton(
                onTap: () =>
                    ref.read(browseProvider.notifier).clearFilters(),
              ),
          ],
        ),
      ),
    );
  }

  /// Считает количество активных фильтров (не null, не пустой List).
  static int _countActive(Map<String, Object?> values) {
    int n = 0;
    for (final Object? v in values.values) {
      if (v == null) continue;
      if (v is List<Object> && v.isEmpty) continue;
      n++;
    }
    return n;
  }
}

// =========================================================================
// Compact bar (узкие экраны)
// =========================================================================

/// Узкий вариант FilterBar:
/// `[Source ▾][🎚 Фильтры (N)][⚙ Customize?]`.
///
/// Source — chevron того же шейпа что на широких. «Фильтры» открывают
/// [FilterSheet]. Customize — отдельная иконка для TMDB источников
/// (Discover Customize не фильтр, поэтому в шит не пускаем).
class _CompactBar extends StatelessWidget {
  const _CompactBar({
    required this.source,
    required this.accent,
    required this.activeFilterCount,
    required this.onSourceChanged,
    required this.onOpenFilters,
    required this.onDiscoverCustomize,
  });

  final SearchSource source;
  final Color accent;
  final int activeFilterCount;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback? onDiscoverCustomize;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool showCustomize = onDiscoverCustomize != null;
    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _kSourceWidth,
              child: _SourceDropdownChevron(
                source: source,
                accentColor: accent,
                isLast: false,
                onSourceChanged: onSourceChanged,
              ),
            ),
            Expanded(
              child: _FiltersChevronButton(
                accent: accent,
                count: activeFilterCount,
                label: l.collectionFilterFilters,
                isLast: !showCustomize,
                onTap: onOpenFilters,
              ),
            ),
            if (showCustomize)
              SizedBox(
                width: _kCustomizeWidth,
                child: ChevronSegment(
                  label: l.discoverCustomize,
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
          ],
        ),
      ),
    );
  }
}

/// Шеврон-кнопка «🎚 Фильтры (N)» — средний сегмент compact bar.
class _FiltersChevronButton extends StatelessWidget {
  const _FiltersChevronButton({
    required this.accent,
    required this.count,
    required this.label,
    required this.isLast,
    required this.onTap,
  });

  final Color accent;
  final int count;
  final String label;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = count > 0;
    return ChevronSegment(
      label: count > 0 ? '$label ($count)' : label,
      icon: Icons.tune,
      selected: active,
      accentColor: accent,
      isFirst: false,
      isLast: isLast,
      onTap: onTap,
      tintWhenInactive: true,
    );
  }
}

// =========================================================================
// Clear button
// =========================================================================

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 40,
          child: Icon(
            Icons.close,
            size: 18,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Source dropdown chevron
// =========================================================================

class _SourceDropdownChevron extends StatelessWidget {
  const _SourceDropdownChevron({
    required this.source,
    required this.accentColor,
    required this.isLast,
    required this.onSourceChanged,
  });

  final SearchSource source;
  final Color accentColor;
  final bool isLast;
  final ValueChanged<String> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return DropdownChevronSegment<Object>(
      label: source.label(l),
      subtitle: source.groupName,
      icon: source.icon,
      selected: true,
      accentColor: accentColor,
      isFirst: true,
      isLast: isLast,
      menuBuilder: (BuildContext ctx) => _buildGroupedItems(l),
      onSelected: (Object? value) {
        if (value is String) onSourceChanged(value);
      },
    );
  }

  List<PopupMenuEntry<Object>> _buildGroupedItems(S l) {
    final List<PopupMenuEntry<Object>> items = <PopupMenuEntry<Object>>[];

    for (final SourceGroupEntry group in groupedSearchSources) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider(height: 8));
      }
      items.add(PopupMenuItem<Object>(
        enabled: false,
        height: 28,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(group.groupIcon, size: 14, color: AppColors.textTertiary),
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

      for (final SearchSource s in group.sources) {
        final bool isSelected = s.id == source.id;
        items.add(PopupMenuItem<Object>(
          value: s.id,
          height: 36,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              s.label(l),
              style: AppTypography.body.copyWith(
                color: isSelected
                    ? filterAccentForGroup(s.groupId)
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

// =========================================================================
// Filter dropdown chevron
// =========================================================================

class _FilterDropdownChevron extends ConsumerStatefulWidget {
  const _FilterDropdownChevron({
    required this.filter,
    required this.value,
    required this.accentColor,
    required this.isLast,
    required this.onChanged,
    super.key,
  });

  final SearchFilter filter;
  final Object? value;
  final Color accentColor;
  final bool isLast;
  final ValueChanged<Object?> onChanged;

  @override
  ConsumerState<_FilterDropdownChevron> createState() =>
      _FilterDropdownChevronState();
}

class _FilterDropdownChevronState
    extends ConsumerState<_FilterDropdownChevron> {
  List<FilterOption>? _options;
  bool _isLoading = false;
  bool _initialLoadDone = false;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _loadOptions();
    }
  }

  @override
  void didUpdateWidget(_FilterDropdownChevron oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.cacheKey != widget.filter.cacheKey) {
      _options = null;
      _initialLoadDone = false;
      _loadOptions();
    }
  }

  Future<void> _loadOptions() async {
    if (_isLoading) return;
    final int gen = ++_loadGeneration;
    setState(() => _isLoading = true);
    try {
      final S l = S.of(context);
      final List<FilterOption> opts =
          await widget.filter.options(ref, l);
      if (_loadGeneration != gen || !mounted) return;
      setState(() {
        _options = opts;
        _isLoading = false;
      });
    } on Exception {
      if (_loadGeneration != gen || !mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _getLabel(S l) {
    if (widget.value == null) return widget.filter.placeholder(l);
    if (widget.filter.multiSelect && widget.value is List<Object>) {
      final List<Object> sel = widget.value! as List<Object>;
      if (sel.isEmpty) return widget.filter.placeholder(l);
      return '${widget.filter.placeholder(l)} (${sel.length})';
    }
    if (_options == null) return '...';
    for (final FilterOption opt in _options!) {
      if (opt.value == widget.value) return opt.label;
    }
    return widget.value.toString();
  }

  bool get _isActive {
    if (widget.filter.multiSelect) {
      return widget.value is List<Object> &&
          (widget.value! as List<Object>).isNotEmpty;
    }
    return widget.value != null;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    final String? sub = _isActive ? widget.filter.placeholder(l) : null;

    if (widget.filter.searchable) {
      return ChevronSegment(
        label: _getLabel(l),
        subtitle: sub,
        icon: Icons.filter_list,
        selected: _isActive,
        accentColor: widget.accentColor,
        isFirst: false,
        isLast: widget.isLast,
        onTap: () => _showSearchableDialog(l),
      );
    }

    return DropdownChevronSegment<Object>(
      label: _getLabel(l),
      subtitle: sub,
      icon: Icons.filter_list,
      selected: _isActive,
      accentColor: widget.accentColor,
      isFirst: false,
      isLast: widget.isLast,
      menuBuilder: (BuildContext ctx) => _buildFilterItems(l),
      onSelected: (Object? value) {
        widget.onChanged(value == kFilterResetSentinel ? null : value);
      },
    );
  }

  List<PopupMenuEntry<Object>> _buildFilterItems(S l) {
    if (_options == null || _isLoading) {
      return <PopupMenuEntry<Object>>[
        const PopupMenuItem<Object>(
          enabled: false,
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }

    return <PopupMenuEntry<Object>>[
      PopupMenuItem<Object>(
        value: kFilterResetSentinel,
        height: 36,
        child: Text(
          l.browseFilterAll,
          style: AppTypography.body.copyWith(
            color: widget.value == null
                ? widget.accentColor
                : AppColors.textSecondary,
            fontWeight:
                widget.value == null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
      for (final FilterOption opt in _options!)
        if (opt.value != null)
          PopupMenuItem<Object>(
            value: opt.value,
            height: 36,
            child: Text(
              opt.label,
              style: AppTypography.body.copyWith(
                color: opt.value == widget.value
                    ? widget.accentColor
                    : AppColors.textPrimary,
                fontWeight: opt.value == widget.value
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
    ];
  }

  Future<void> _showSearchableDialog(S l) async {
    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext context) => SearchableFilterDialog(
        title: widget.filter.placeholder(l),
        options: _options,
        isLoading: _isLoading,
        currentValue: widget.value,
        allLabel: l.browseFilterAll,
        multiSelect: widget.filter.multiSelect,
      ),
    );
    if (result == null) return;
    widget.onChanged(result == kFilterResetSentinel ? null : result);
  }
}

// =========================================================================
// Sort dropdown chevron
// =========================================================================

class _SortDropdownChevron extends StatelessWidget {
  const _SortDropdownChevron({
    required this.options,
    required this.current,
    required this.enabled,
    required this.accentColor,
    required this.isLast,
    required this.onChanged,
  });

  final List<BrowseSortOption> options;
  final String current;
  final bool enabled;
  final Color accentColor;
  final bool isLast;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    String currentLabel = l.browseSort;
    for (final BrowseSortOption opt in options) {
      if (opt.apiValue == current) {
        currentLabel = opt.label(l);
        break;
      }
    }

    if (!enabled) {
      return ChevronSegment(
        label: currentLabel,
        subtitle: l.browseSort,
        icon: Icons.sort,
        selected: false,
        accentColor: accentColor,
        isFirst: false,
        isLast: isLast,
        onTap: () {},
      );
    }

    return DropdownChevronSegment<Object>(
      label: currentLabel,
      subtitle: l.browseSort,
      icon: Icons.sort,
      selected: false,
      accentColor: accentColor,
      isFirst: false,
      isLast: isLast,
      menuBuilder: (BuildContext ctx) {
        final S menuL = S.of(ctx);
        return <PopupMenuEntry<Object>>[
          for (final BrowseSortOption opt in options)
            PopupMenuItem<Object>(
              value: opt.apiValue,
              height: 36,
              child: Text(
                opt.label(menuL),
                style: AppTypography.body.copyWith(
                  color: opt.apiValue == current
                      ? accentColor
                      : AppColors.textPrimary,
                  fontWeight: opt.apiValue == current
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
