// Универсальный дропдаун фильтра.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/search_source.dart';

/// Sentinel-объект для сброса фильтра.
///
/// PopupMenuButton трактует null как закрытие меню (не вызывает onSelected),
/// поэтому для "All" опции используется уникальный sentinel.
const String _resetSentinel = '__filter_reset__';

/// Универсальный дропдаун для одного фильтра.
///
/// Показывает текущее значение фильтра или placeholder.
/// При тапе открывает PopupMenu с вариантами.
class FilterDropdown extends ConsumerStatefulWidget {
  /// Создаёт [FilterDropdown].
  const FilterDropdown({
    required this.filter,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Описание фильтра.
  final SearchFilter filter;

  /// Текущее выбранное значение (null = не выбрано).
  final Object? value;

  /// Callback при выборе нового значения.
  final ValueChanged<Object?> onChanged;

  @override
  ConsumerState<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends ConsumerState<FilterDropdown> {
  List<FilterOption>? _options;
  Map<Object, String>? _labelCache;
  bool _isLoadingOptions = false;
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
  void didUpdateWidget(FilterDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.cacheKey != widget.filter.cacheKey) {
      _options = null;
      _labelCache = null;
      _loadOptions();
    }
  }

  Future<void> _loadOptions() async {
    if (_isLoadingOptions) return;
    final int gen = ++_loadGeneration;
    setState(() => _isLoadingOptions = true);

    try {
      final S l = S.of(context);
      final List<FilterOption> options =
          await widget.filter.options(ref, l);
      if (_loadGeneration != gen || !mounted) return;
      setState(() {
        _options = options;
        _labelCache = <Object, String>{
          for (final FilterOption opt in options)
            if (opt.value != null) opt.value!: opt.label,
        };
        _isLoadingOptions = false;
      });
    } on Exception {
      if (_loadGeneration != gen || !mounted) return;
      setState(() => _isLoadingOptions = false);
    }
  }

  String _getSelectedLabel(S l) {
    if (widget.value == null) {
      return widget.filter.placeholder(l);
    }

    // Множественный выбор — показываем количество
    if (widget.filter.multiSelect && widget.value is List<Object>) {
      final List<Object> selected = widget.value! as List<Object>;
      if (selected.isEmpty) return widget.filter.placeholder(l);
      if (selected.length == 1 && _labelCache != null) {
        return _labelCache![selected.first] ?? selected.first.toString();
      }
      return '${widget.filter.placeholder(l)} (${selected.length})';
    }

    if (_labelCache == null) return '...';

    return _labelCache![widget.value] ?? widget.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool isActive = widget.filter.multiSelect
        ? widget.value is List<Object> &&
            (widget.value! as List<Object>).isNotEmpty
        : widget.value != null;
    final String label = _getSelectedLabel(l);

    final Widget chip = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.brand.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isActive ? AppColors.brand : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: isActive
                  ? AppColors.brand
                  : AppColors.textTertiary,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isActive
                ? AppColors.brand
                : AppColors.textTertiary,
          ),
        ],
      ),
    );

    // Searchable фильтры — диалог с полем поиска
    if (widget.filter.searchable) {
      return InkWell(
        onTap: () => _showSearchableDialog(l),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: chip,
      );
    }

    // Обычные фильтры — PopupMenuButton
    return PopupMenuButton<Object>(
      onSelected: (Object value) {
        widget.onChanged(value == _resetSentinel ? null : value);
      },
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      color: AppColors.surface,
      constraints: const BoxConstraints(maxHeight: 400),
      itemBuilder: (BuildContext context) {
        if (_options == null || _isLoadingOptions) {
          return <PopupMenuEntry<Object>>[
            const PopupMenuItem<Object>(
              enabled: false,
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ];
        }

        return <PopupMenuEntry<Object>>[
          // "All" option для сброса (sentinel вместо null)
          PopupMenuItem<Object>(
            value: _resetSentinel,
            height: 36,
            child: Text(
              l.browseFilterAll,
              style: AppTypography.body.copyWith(
                color: widget.value == null
                    ? AppColors.brand
                    : AppColors.textSecondary,
                fontWeight: widget.value == null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
          // Варианты фильтра
          for (final FilterOption option in _options!)
            if (option.value != null)
              PopupMenuItem<Object>(
                value: option.value,
                height: 36,
                child: Text(
                  option.label,
                  style: AppTypography.body.copyWith(
                    color: option.value == widget.value
                        ? AppColors.brand
                        : AppColors.textPrimary,
                    fontWeight: option.value == widget.value
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
        ];
      },
      child: chip,
    );
  }

  /// Открывает диалог с полем поиска для фильтрации вариантов.
  Future<void> _showSearchableDialog(S l) async {
    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext context) => SearchableFilterDialog(
        title: widget.filter.placeholder(l),
        options: _options,
        isLoading: _isLoadingOptions,
        currentValue: widget.value,
        allLabel: l.browseFilterAll,
        multiSelect: widget.filter.multiSelect,
      ),
    );
    if (result == null) return;
    widget.onChanged(result == _resetSentinel ? null : result);
  }
}

/// Диалог с полем поиска для фильтров с большим количеством вариантов.
///
/// Поддерживает два режима:
/// - single-select: тап по опции закрывает диалог с выбранным значением
/// - multi-select: чекбоксы + кнопка подтверждения
class SearchableFilterDialog extends StatefulWidget {
  /// Создаёт [SearchableFilterDialog].
  const SearchableFilterDialog({
    required this.title,
    required this.options,
    required this.isLoading,
    required this.currentValue,
    required this.allLabel,
    this.multiSelect = false,
    super.key,
  });

  final String title;
  final List<FilterOption>? options;
  final bool isLoading;
  final Object? currentValue;
  final String allLabel;
  final bool multiSelect;

  @override
  State<SearchableFilterDialog> createState() =>
      SearchableFilterDialogState();
}

class SearchableFilterDialogState extends State<SearchableFilterDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  /// Выбранные значения (только для multiSelect).
  late final Set<Object> _selected = <Object>{
    if (widget.currentValue is List<Object>)
      ...(widget.currentValue! as List<Object>),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FilterOption> get _filteredOptions {
    if (widget.options == null) return <FilterOption>[];

    List<FilterOption> result;
    if (_query.isEmpty) {
      result = widget.options!
          .where((FilterOption o) => o.value != null)
          .toList();
    } else {
      final String lower = _query.toLowerCase();
      result = widget.options!
          .where(
            (FilterOption o) =>
                o.value != null && o.label.toLowerCase().contains(lower),
          )
          .toList();
    }

    // В multiSelect — выбранные элементы всегда сверху
    if (widget.multiSelect && _selected.isNotEmpty) {
      result.sort((FilterOption a, FilterOption b) {
        final bool aSelected = _selected.contains(a.value);
        final bool bSelected = _selected.contains(b.value);
        if (aSelected == bSelected) return 0;
        return aSelected ? -1 : 1;
      });
    }

    return result;
  }

  bool _isSelected(Object? value) {
    if (widget.multiSelect) {
      return value != null && _selected.contains(value);
    }
    return value == widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      title: Text(
        widget.title,
        style: AppTypography.h3,
      ),
      contentPadding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: <Widget>[
            // Поле поиска
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.title,
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (String value) {
                    setState(() => _query = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Список вариантов
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      ),
      actions: widget.multiSelect
          ? <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_resetSentinel),
                child: Text(
                  l.browseFilterAll,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  if (_selected.isEmpty) {
                    Navigator.of(context).pop(_resetSentinel);
                  } else {
                    Navigator.of(context).pop(_selected.toList());
                  }
                },
                child: Text(
                  _selected.isEmpty
                      ? l.reset
                      : l.platformFilterApply(_selected.length),
                ),
              ),
            ]
          : null,
    );
  }

  Widget _buildList() {
    if (widget.isLoading || widget.options == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final List<FilterOption> filtered = _filteredOptions;

    // single-select: +1 для опции "All" (без поискового запроса)
    final bool showAll = !widget.multiSelect && _query.isEmpty;
    final int itemCount =
        showAll ? filtered.length + 1 : filtered.length;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        // Опция "All" — первый элемент, только single-select без запроса
        if (showAll && index == 0) {
          return _buildOptionTile(
            label: widget.allLabel,
            isSelected: widget.currentValue == null,
            onTap: () => Navigator.of(context).pop(_resetSentinel),
          );
        }

        final int optionIndex = showAll ? index - 1 : index;
        final FilterOption option = filtered[optionIndex];
        final bool selected = _isSelected(option.value);

        if (widget.multiSelect) {
          return _buildCheckboxTile(
            label: option.label,
            isSelected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selected.remove(option.value);
                } else if (option.value != null) {
                  _selected.add(option.value!);
                }
              });
            },
          );
        }

        return _buildOptionTile(
          label: option.label,
          isSelected: selected,
          onTap: () => Navigator.of(context).pop(option.value),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? AppColors.brand : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: isSelected
                      ? AppColors.brand
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Дропдаун сортировки.
class SortDropdown extends StatelessWidget {
  /// Создаёт [SortDropdown].
  const SortDropdown({
    required this.options,
    required this.current,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Доступные варианты сортировки.
  final List<BrowseSortOption> options;

  /// Текущее значение сортировки (API).
  final String current;

  /// Callback при выборе нового значения.
  final ValueChanged<String> onChanged;

  /// Доступен ли дропдаун для взаимодействия.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    // Найти текущий label
    String currentLabel = l.browseSort;
    for (final BrowseSortOption option in options) {
      if (option.apiValue == current) {
        currentLabel = option.label(l);
        break;
      }
    }

    final Widget chip = Container(
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
          Icon(
            Icons.sort,
            size: 14,
            color: enabled
                ? AppColors.textTertiary
                : AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            currentLabel,
            style: AppTypography.body.copyWith(
              color: enabled
                  ? AppColors.textSecondary
                  : AppColors.textTertiary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: enabled
                ? AppColors.textTertiary
                : AppColors.textTertiary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Tooltip(
        message: l.browseSortDisabledHint,
        child: chip,
      );
    }

    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      color: AppColors.surface,
      itemBuilder: (BuildContext context) {
        final S menuL = S.of(context);
        return options.map((BrowseSortOption option) {
          final bool isSelected = option.apiValue == current;
          return PopupMenuItem<String>(
            value: option.apiValue,
            height: 36,
            child: Text(
              option.label(menuL),
              style: AppTypography.body.copyWith(
                color: isSelected
                    ? AppColors.brand
                    : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
      child: chip,
    );
  }
}
