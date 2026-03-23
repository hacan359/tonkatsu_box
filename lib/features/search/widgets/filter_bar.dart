// Горизонтальная строка фильтров.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import 'filter_dropdown.dart';
import 'source_dropdown.dart';

/// Горизонтальная строка фильтров для Browse mode.
///
/// Содержит: Source dropdown + Filter dropdowns + Sort dropdown.
/// Горизонтальный скролл если фильтров много.
class FilterBar extends ConsumerWidget {
  /// Создаёт [FilterBar].
  const FilterBar({this.onBeforeFilterChange, super.key});

  /// Вызывается перед применением фильтра.
  ///
  /// Позволяет синхронизировать текст поиска из контроллера в провайдер.
  final VoidCallback? onBeforeFilterChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState browseState = ref.watch(browseProvider);
    final SearchSource source = browseState.source;
    final List<SearchFilter> filters = source.filters;
    final bool hasActiveFilters = browseState.filterValues.values
        .any((Object? v) => v != null);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        children: <Widget>[
          // Source dropdown
          SourceDropdown(
            current: source,
            onChanged: (SearchSource newSource) {
              ref.read(browseProvider.notifier).setSource(newSource.id);
            },
          ),
          const SizedBox(width: 6),
          // Filter dropdowns
          for (final SearchFilter filter in filters) ...<Widget>[
            FilterDropdown(
              key: ValueKey<String>('${source.id}_${filter.cacheKey}'),
              filter: filter,
              value: browseState.filterValues[filter.key],
              onChanged: (Object? value) {
                onBeforeFilterChange?.call();
                ref
                    .read(browseProvider.notifier)
                    .setFilter(filter.key, value);
              },
            ),
            const SizedBox(width: 6),
          ],
          // Sort dropdown
          if (source.sortOptions.isNotEmpty)
            SortDropdown(
              options: source.sortOptions,
              current: browseState.effectiveSortBy,
              enabled: !browseState.hasSearchQuery ||
                  source.supportsSortDuringSearch,
              onChanged: (String sortBy) {
                ref.read(browseProvider.notifier).setSort(sortBy);
              },
            ),
          // Clear filters
          if (hasActiveFilters) ...<Widget>[
            const SizedBox(width: 6),
            ActionChip(
              avatar: Icon(
                Icons.close,
                size: 14,
                color: AppColors.error.withAlpha(180),
              ),
              label: Text(
                S.of(context).filtersClear,
                style: AppTypography.caption.copyWith(
                  color: AppColors.error.withAlpha(180),
                ),
              ),
              side: BorderSide(
                color: AppColors.error.withAlpha(60),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                ref.read(browseProvider.notifier).clearFilters();
              },
            ),
          ],
        ],
      ),
    );
  }
}
