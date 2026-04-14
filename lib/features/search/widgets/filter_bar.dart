// Chevron filter bar для экрана поиска.
//
// Первый шеврон — выпадающий список источников (цвет по группе).
// Остальные шевроны — dropdown фильтры + sort текущего источника.
// Clear кнопка в конце при активных фильтрах.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../sources/search_sources.dart';
import 'filter_dropdown.dart';

/// Цвет accent для группы источника.
Color _accentForGroup(String groupId) {
  return switch (groupId) {
    'tmdb' => AppColors.movieAccent,
    'igdb' => AppColors.gameAccent,
    'anilist' => AppColors.animeAccent,
    'vndb' => AppColors.visualNovelAccent,
    _ => AppColors.brand,
  };
}

/// Chevron filter bar для Browse mode.
///
/// `[Source ▾][Filter1 ▾][Filter2 ▾][Sort ▾][×]`
/// Всё в одну строку на всю ширину. Clear в конце.
class FilterBar extends ConsumerWidget {
  /// Создаёт [FilterBar].
  const FilterBar({this.onBeforeFilterChange, super.key});

  /// Вызывается перед применением фильтра.
  final VoidCallback? onBeforeFilterChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState browseState = ref.watch(browseProvider);
    final SearchSource source = browseState.source;
    final List<SearchFilter> filters = source.filters;
    final bool hasSort = source.sortOptions.isNotEmpty;
    final bool hasActiveFilters = browseState.filterValues.values
        .any((Object? v) => v != null);
    final Color accent = _accentForGroup(source.groupId);

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            // Source dropdown (первый, всегда selected).
            Expanded(
              child: _SourceDropdownChevron(
                source: source,
                accentColor: accent,
                isLast: filters.isEmpty && !hasSort,
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
                  isLast: !hasSort && i == filters.length - 1,
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
                  isLast: true,
                  onChanged: (String sortBy) {
                    ref.read(browseProvider.notifier).setSort(sortBy);
                  },
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

    return _DropdownChevronBase(
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
                    ? _accentForGroup(s.groupId)
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
      return _ChevronShell(
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

    return _DropdownChevronBase(
      label: _getLabel(l),
      subtitle: sub,
      icon: Icons.filter_list,
      selected: _isActive,
      accentColor: widget.accentColor,
      isFirst: false,
      isLast: widget.isLast,
      menuBuilder: (BuildContext ctx) => _buildFilterItems(l),
      onSelected: (Object? value) {
        widget.onChanged(value == _kReset ? null : value);
      },
    );
  }

  static const String _kReset = '__reset__';

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
        value: _kReset,
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
    widget.onChanged(result == _kReset ? null : result);
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
      return _ChevronShell(
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

    return _DropdownChevronBase(
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

// =========================================================================
// Base chevron widgets
// =========================================================================

/// Chevron-сегмент (только визуал + onTap, без dropdown).
class _ChevronShell extends StatelessWidget {
  const _ChevronShell({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor : AppColors.surface;
    final Color fg =
        selected ? AppColors.background : AppColors.textSecondary;

    return ClipPath(
      clipper: ChevronClipper(
        chevronWidth: ChevronSegment.chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: isFirst ? 4 : ChevronSegment.chevronWidth + 1,
                right: isLast ? 4 : ChevronSegment.chevronWidth + 1,
              ),
              child: Center(
                child: _buildChevronContent(
                  label: label,
                  subtitle: subtitle,
                  fg: fg,
                  selected: selected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chevron-сегмент с PopupMenuButton внутри.
class _DropdownChevronBase extends StatelessWidget {
  const _DropdownChevronBase({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.menuBuilder,
    required this.onSelected,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final bool isFirst;
  final bool isLast;
  final List<PopupMenuEntry<Object>> Function(BuildContext) menuBuilder;
  final ValueChanged<Object?> onSelected;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor : AppColors.surface;
    final Color fg =
        selected ? AppColors.background : AppColors.textSecondary;

    return ClipPath(
      clipper: ChevronClipper(
        chevronWidth: ChevronSegment.chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: bg,
        child: PopupMenuButton<Object>(
          onSelected: onSelected,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          color: AppColors.surface,
          constraints: const BoxConstraints(maxHeight: 400),
          itemBuilder: menuBuilder,
          child: Padding(
            padding: EdgeInsets.only(
              left: isFirst ? 4 : ChevronSegment.chevronWidth + 1,
              right: isLast ? 4 : ChevronSegment.chevronWidth + 1,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: _buildChevronContent(
                      label: label,
                      subtitle: subtitle,
                      fg: fg,
                      selected: selected,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 14, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Shared content builder
// =========================================================================

/// Контент шеврона: если [subtitle] задан — двухстрочный (заголовок + значение),
/// иначе однострочный.
Widget _buildChevronContent({
  required String label,
  required String? subtitle,
  required Color fg,
  required bool selected,
}) {
  if (subtitle == null) {
    return Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: AppTypography.bodySmall.copyWith(
        color: fg,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        subtitle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 9,
          color: fg.withAlpha(selected ? 180 : 140),
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: AppTypography.bodySmall.copyWith(
          color: fg,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
          height: 1.1,
        ),
      ),
    ],
  );
}
