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

    if (_labelCache == null) return '...';

    return _labelCache![widget.value] ?? widget.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool isActive = widget.value != null;
    final String label = _getSelectedLabel(l);

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
      child: Container(
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
    super.key,
  });

  /// Доступные варианты сортировки.
  final List<BrowseSortOption> options;

  /// Текущее значение сортировки (API).
  final String current;

  /// Callback при выборе нового значения.
  final ValueChanged<String> onChanged;

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
            const Icon(
              Icons.sort,
              size: 14,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              currentLabel,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
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
