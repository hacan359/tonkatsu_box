import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../models/common_filter.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../utils/filter_ui.dart';
import 'filter_dropdown.dart';

/// What a filter control reports back: either a shared pick (already resolved
/// to per-source values) or a raw value for the single source that owns it.
typedef FilterPick = void Function(Object? value, CommonSelection? selection);

/// Shared option loading for one filter. Owns the async list plus, for a
/// [CommonFilter], the semantic → per-source table needed to build a pick.
mixin FilterOptionsLoader<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  List<FilterOption>? options;
  CommonFilterOptions? commonOptions;
  bool isLoadingOptions = false;

  int _generation = 0;

  SearchFilter get filter;

  Future<void> loadOptions() async {
    if (isLoadingOptions) return;
    final int gen = ++_generation;
    setState(() => isLoadingOptions = true);
    try {
      final S l = S.of(context);
      final SearchFilter target = filter;
      if (target is CommonFilter) {
        final CommonFilterOptions loaded = await target.load(ref, l);
        if (_generation != gen || !mounted) return;
        setState(() {
          commonOptions = loaded;
          options = loaded.display;
          isLoadingOptions = false;
        });
        return;
      }
      final List<FilterOption> loaded = await target.options(ref, l);
      if (_generation != gen || !mounted) return;
      setState(() {
        options = loaded;
        isLoadingOptions = false;
      });
    } on Exception {
      if (_generation != gen || !mounted) return;
      setState(() => isLoadingOptions = false);
    }
  }

  void resetOptions() {
    options = null;
    commonOptions = null;
  }

  /// Turns a menu value into a pick. A [CommonFilter] value is a
  /// [FilterSemantic]; everything else passes through untouched.
  void report(Object? value, FilterPick onPick) {
    final Object? resolved = value == kFilterResetSentinel ? null : value;
    if (filter is! CommonFilter) {
      onPick(resolved, null);
      return;
    }
    if (resolved is! FilterSemantic) {
      onPick(null, null);
      return;
    }
    final Map<String, CommonFilterTarget>? targets =
        commonOptions?.bySource[resolved];
    if (targets == null || targets.isEmpty) {
      onPick(null, null);
      return;
    }
    onPick(
      resolved,
      CommonSelection(semantic: resolved, targets: targets),
    );
  }

  /// Label for the current [value]: the matching option, a count for
  /// multi-select, or the placeholder when nothing is picked.
  String labelFor(Object? value, S l) {
    if (value == null) return filter.placeholder(l);
    if (filter.multiSelect && value is List<Object>) {
      if (value.isEmpty) return filter.placeholder(l);
      return '${filter.placeholder(l)} (${value.length})';
    }
    final List<FilterOption>? loaded = options;
    if (loaded == null) return '...';
    for (final FilterOption option in loaded) {
      if (option.value == value) return option.label;
    }
    return value.toString();
  }

  List<PopupMenuEntry<Object>> menuEntries(
    S l,
    Object? value,
    Color accent,
  ) {
    final List<FilterOption>? loaded = options;
    if (loaded == null || isLoadingOptions) {
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
          l.all,
          style: AppTypography.body.copyWith(
            color: value == null ? accent : AppColors.textSecondary,
            fontWeight: value == null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
      for (final FilterOption option in loaded)
        if (option.value != null)
          PopupMenuItem<Object>(
            value: option.value,
            height: 36,
            child: Text(
              option.label,
              style: AppTypography.body.copyWith(
                color: option.value == value ? accent : AppColors.textPrimary,
                fontWeight:
                    option.value == value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
    ];
  }
}

/// One filter as a chevron segment of the desktop bar.
class FilterChevron extends ConsumerStatefulWidget {
  const FilterChevron({
    required this.filter,
    required this.value,
    required this.accentColor,
    required this.isLast,
    required this.onPick,
    super.key,
  });

  final SearchFilter filter;
  final Object? value;
  final Color accentColor;
  final bool isLast;
  final FilterPick onPick;

  @override
  ConsumerState<FilterChevron> createState() => _FilterChevronState();
}

class _FilterChevronState extends ConsumerState<FilterChevron>
    with FilterOptionsLoader<FilterChevron> {
  bool _initialLoadDone = false;

  @override
  SearchFilter get filter => widget.filter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      loadOptions();
    }
  }

  @override
  void didUpdateWidget(FilterChevron oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.cacheKey != widget.filter.cacheKey) {
      resetOptions();
      loadOptions();
    }
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
    final String? subtitle = _isActive ? widget.filter.placeholder(l) : null;

    final Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
        customPicker = widget.filter.openCustomPicker;
    if (customPicker != null) {
      return ChevronSegment(
        label: labelFor(widget.value, l),
        subtitle: subtitle,
        icon: Icons.filter_list,
        selected: _isActive,
        accentColor: widget.accentColor,
        isFirst: false,
        isLast: widget.isLast,
        onTap: () async {
          final Object? result =
              await customPicker(context, ref, l, widget.value);
          if (!mounted) return;
          report(result, widget.onPick);
        },
      );
    }

    if (widget.filter.searchable) {
      return ChevronSegment(
        label: labelFor(widget.value, l),
        subtitle: subtitle,
        icon: Icons.filter_list,
        selected: _isActive,
        accentColor: widget.accentColor,
        isFirst: false,
        isLast: widget.isLast,
        onTap: () async {
          final Object? result = await showDialog<Object>(
            context: context,
            builder: (BuildContext _) => SearchableFilterDialog(
              title: widget.filter.placeholder(l),
              options: options,
              isLoading: isLoadingOptions,
              currentValue: widget.value,
              allLabel: l.all,
              multiSelect: widget.filter.multiSelect,
            ),
          );
          if (result == null || !mounted) return;
          report(result, widget.onPick);
        },
      );
    }

    return DropdownChevronSegment<Object>(
      label: labelFor(widget.value, l),
      subtitle: subtitle,
      icon: Icons.filter_list,
      selected: _isActive,
      accentColor: widget.accentColor,
      isFirst: false,
      isLast: widget.isLast,
      menuBuilder: (BuildContext _) =>
          menuEntries(l, widget.value, widget.accentColor),
      onSelected: (Object? value) => report(value, widget.onPick),
    );
  }
}
