// Bottom sheet с фильтрами/sort/customize для search-экрана на узких экранах.
//
// Открывается из FilterBar по тапу на иконку «🎚 Фильтры (N)».
// Все изменения применяются мгновенно (без кнопки «Применить»), как в
// chevron-варианте на широких экранах.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../utils/filter_ui.dart';
import 'filter_dropdown.dart';

/// Открыть [FilterSheet] как modal bottom sheet.
///
/// Возвращает Future, завершающийся при закрытии sheet. Применение фильтров
/// идёт мгновенно через [browseProvider], поэтому возвращаемого значения нет.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext _, ScrollController scrollController) =>
          FilterSheet(scrollController: scrollController),
    ),
  );
}

/// Содержимое bottom sheet с фильтрами и сортировкой.
///
/// Discover Customize здесь нет — это часть интерфейса, а не фильтр,
/// и живёт отдельной кнопкой в [FilterBar].
class FilterSheet extends ConsumerWidget {
  /// Создаёт [FilterSheet].
  const FilterSheet({
    required this.scrollController,
    super.key,
  });

  /// Контроллер скролла из [DraggableScrollableSheet].
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final BrowseState browseState = ref.watch(browseProvider);
    final SearchSource source = browseState.source;
    final List<SearchFilter> filters = source.filters;
    final List<BrowseSortOption> sortOptions = source.sortOptions;
    final bool hasActiveFilters = browseState.hasFilters;
    final Color accent = filterAccentForGroup(source.groupId);

    return Material(
      color: AppColors.background,
      elevation: 16,
      shadowColor: Colors.black,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.backgroundTile),
            repeat: ImageRepeat.repeat,
            opacity: 0.03,
            scale: 0.667,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Цветной glow группы — как «backdrop» для FilterSheet.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.7),
                      radius: 1.1,
                      colors: <Color>[
                        accent.withAlpha(110),
                        accent.withAlpha(30),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Затемнение к низу для читаемости.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.background.withAlpha(80),
                        AppColors.background.withAlpha(160),
                        AppColors.background.withAlpha(220),
                      ],
                      stops: const <double>[0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Стеклянная карточка с drag handle внутри (как
            // item_details_sheet) — единая подложка, всё на стекле.
            SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(80),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.surfaceBorder.withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Header: drag handle + Сбросить (как у item_details).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(80),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              if (hasActiveFilters)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    minimumSize: const Size(0, 28),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => ref
                                      .read(browseProvider.notifier)
                                      .clearFilters(),
                                  child: Text(
                                    l.filtersClear,
                                    style:
                                        AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Filters.
                    if (filters.isNotEmpty)
                      for (final SearchFilter f in filters)
                        _FilterRow(
                          key: ValueKey<String>(
                            '${source.id}_${f.cacheKey}',
                          ),
                          filter: f,
                          value: browseState.filterValues[f.key],
                          accent: accent,
                          onChanged: (Object? v) => ref
                              .read(browseProvider.notifier)
                              .setFilter(f.key, v),
                        ),

                    // Sort.
                    if (sortOptions.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          l.browseSort.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      for (final BrowseSortOption opt in sortOptions)
                        _SortTile(
                          label: opt.label(l),
                          selected:
                              opt.apiValue == browseState.effectiveSortBy,
                          accent: accent,
                          onTap: () => ref
                              .read(browseProvider.notifier)
                              .setSort(opt.apiValue),
                        ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Sort tile (один вариант сортировки)
// =========================================================================

/// Строка-радиокнопка для выбора сортировки. Кастомная (без [RadioListTile]
/// чтобы не задействовать deprecated `groupValue`/`onChanged`).
class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 18,
        color: selected ? accent : AppColors.textTertiary,
      ),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: selected ? accent : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      onTap: onTap,
    );
  }
}

// =========================================================================
// Filter row (одна строка фильтра)
// =========================================================================

/// Строка фильтра в sheet: `Label : current value ›`. Тап → диалог выбора.
///
/// Загружает options фильтра асинхронно (через [SearchFilter.options]) для
/// получения человеко-читаемого label текущего значения.
class _FilterRow extends ConsumerStatefulWidget {
  const _FilterRow({
    required this.filter,
    required this.value,
    required this.accent,
    required this.onChanged,
    super.key,
  });

  final SearchFilter filter;
  final Object? value;
  final Color accent;
  final ValueChanged<Object?> onChanged;

  @override
  ConsumerState<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends ConsumerState<_FilterRow> {
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

  String _valueLabel(S l) {
    if (widget.value == null) return l.browseFilterAll;
    if (widget.filter.multiSelect && widget.value is List<Object>) {
      final List<Object> sel = widget.value! as List<Object>;
      if (sel.isEmpty) return l.browseFilterAll;
      return l.platformFilterApply(sel.length);
    }
    if (_options == null) return '…';
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

  Future<void> _openDialog() async {
    final S l = S.of(context);
    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext ctx) => SearchableFilterDialog(
        title: widget.filter.placeholder(l),
        options: _options,
        isLoading: _isLoading,
        currentValue: widget.value,
        allLabel: l.browseFilterAll,
        multiSelect: widget.filter.multiSelect,
      ),
    );
    if (result == null) return;
    // SearchableFilterDialog возвращает sentinel kFilterResetSentinel для All.
    widget.onChanged(result == kFilterResetSentinel ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return ListTile(
      title: Text(
        widget.filter.placeholder(l),
        style: AppTypography.body,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              _valueLabel(l),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTypography.body.copyWith(
                color: _isActive
                    ? widget.accent
                    : AppColors.textSecondary,
                fontWeight:
                    _isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      dense: true,
      onTap: _openDialog,
    );
  }
}
