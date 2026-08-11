// Narrow-screen filter sheet: same instant-apply semantics as the chevron
// variant — opening it does not commit a "draft", changes hit the provider
// straight away.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_logo.dart';
import '../models/common_filter.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../utils/filter_ui.dart';
import 'filter_control.dart';
import 'filter_dropdown.dart';

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

/// Bottom-sheet body holding the filter + sort rows. Discover Customize
/// lives separately in [FilterBar] — it's chrome, not a filter.
class FilterSheet extends ConsumerWidget {
  const FilterSheet({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final BrowseState browseState = ref.watch(browseProvider);
    final MediaTypeFilters filters = browseState.filters;
    final List<BrowseSortOption> sortOptions = browseState.canSort
        ? browseState.sortSource?.sortOptions ?? const <BrowseSortOption>[]
        : const <BrowseSortOption>[];
    final bool hasActiveFilters = browseState.hasFilters;
    final Color accent = filterAccentForType(browseState.mediaType);

    return Material(
      color: AppColors.background,
      elevation: 16,
      shadowColor: AppColors.shadow,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: AppColors.tileImage,
        ),
        child: Stack(
          children: <Widget>[
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
                                  color: AppColors.textPrimary.withAlpha(80),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
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
                                    minimumSize: const Size(0, AppSpacing.buttonHeightDense),
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

                    // Sources come first: on a phone this sheet is the only
                    // place they can be switched.
                    if (browseState.sources.length > 1)
                      _SourcesSection(state: browseState, accent: accent),

                    if (filters.common.isNotEmpty) ...<Widget>[
                      _GroupLabel(text: l.searchCommonFilters),
                      for (final CommonFilter f in filters.common)
                        _FilterRow(
                          key: ValueKey<String>('common_${f.cacheKey}'),
                          filter: f,
                          value: browseState.commonSelections[f.key]?.semantic,
                          accent: accent,
                          onPick: (Object? v, CommonSelection? selection) => ref
                              .read(browseProvider.notifier)
                              .setCommonFilter(f.key, selection),
                        ),
                    ],

                    for (final SearchSource src in browseState.sources)
                      if ((filters.own[src.id] ?? const <SearchFilter>[])
                          .isNotEmpty) ...<Widget>[
                        _SourceLabel(source: src),
                        for (final SearchFilter f in filters.own[src.id]!)
                          _FilterRow(
                            key: ValueKey<String>('${src.id}_${f.cacheKey}'),
                            filter: f,
                            value: browseState.ownFilterValues[src.id]?[f.key],
                            accent: accent,
                            onPick: (Object? v, CommonSelection? _) => ref
                                .read(browseProvider.notifier)
                                .setOwnFilter(src.id, f.key, v),
                          ),
                      ],

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
                          l.sort.toUpperCase(),
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

/// Custom radio row — `RadioListTile` is avoided because `groupValue`
/// / `onChanged` are deprecated.
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
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
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
      ),
    );
  }
}

/// One filter row in the sheet: `Label : current value ›`. Tap opens the
/// picker. Options are loaded eagerly so the row can render the human label
/// for the currently-selected value.
class _FilterRow extends ConsumerStatefulWidget {
  const _FilterRow({
    required this.filter,
    required this.value,
    required this.accent,
    required this.onPick,
    super.key,
  });

  final SearchFilter filter;
  final Object? value;
  final Color accent;
  final FilterPick onPick;

  @override
  ConsumerState<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends ConsumerState<_FilterRow>
    with FilterOptionsLoader<_FilterRow> {
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

  String _valueLabel(S l) {
    if (widget.value == null) return l.all;
    if (widget.filter.multiSelect && widget.value is List<Object>) {
      final List<Object> sel = widget.value! as List<Object>;
      if (sel.isEmpty) return l.all;
      return l.selectedCount(sel.length);
    }
    final List<FilterOption>? loaded = options;
    if (loaded == null) return '…';
    for (final FilterOption opt in loaded) {
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
    final Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
        customPicker = widget.filter.openCustomPicker;
    final Object? result = customPicker != null
        ? await customPicker(context, ref, l, widget.value)
        : await showDialog<Object>(
            context: context,
            builder: (BuildContext ctx) => SearchableFilterDialog(
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
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
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
            Icon(
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
      ),
    );
  }
}

/// Uppercase group caption inside the sheet.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Group caption for one provider's private filters, with its logo so it is
/// obvious whose filter is being set.
class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.source});

  final SearchSource source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          SourceLogo(source: source.dataSource, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            source.dataSource.label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-select provider row. On a phone this is the only way to switch
/// sources, so it lives at the top of the sheet.
class _SourcesSection extends ConsumerWidget {
  const _SourcesSection({required this.state, required this.accent});

  final BrowseState state;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final Set<String> unsupported = state.unsupportedSourceIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _GroupLabel(text: l.searchSourcesLabel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final SearchSource source in state.sources)
                _SourceChip(
                  source: source,
                  accent: accent,
                  selected: !state.disabledSourceIds.contains(source.id),
                  blocked: unsupported.contains(source.id),
                  onTap: () => ref
                      .read(browseProvider.notifier)
                      .toggleSource(source.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.source,
    required this.accent,
    required this.selected,
    required this.blocked,
    required this.onTap,
  });

  final SearchSource source;
  final Color accent;
  final bool selected;

  /// Cannot answer the picked shared value, so it is out of this query.
  final bool blocked;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool on = selected && !blocked;
    final Widget chip = Material(
      color: on ? accent.withAlpha(38) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        onTap: blocked ? null : onTap,
        child: Container(
          height: AppSpacing.buttonHeightDense,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            border: Border.all(
              color: on ? accent : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Opacity(
                opacity: on ? 1 : 0.4,
                child: SourceLogo(source: source.dataSource, size: 14),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                source.dataSource.label,
                style: AppTypography.bodySmall.copyWith(
                  color: on ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!blocked) return chip;
    return Tooltip(message: S.of(context).searchSourceLacksValue, child: chip);
  }
}
