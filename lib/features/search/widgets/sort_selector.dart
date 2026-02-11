// Виджет выбора сортировки результатов поиска.

import 'package:flutter/material.dart';

import '../../../shared/models/search_sort.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Виджет выбора сортировки для результатов поиска.
///
/// Показывает сегментированную кнопку с тремя опциями:
/// Relevance, Date, Rating. При повторном нажатии на активный
/// сегмент переключается направление сортировки.
class SortSelector extends StatelessWidget {
  /// Создаёт [SortSelector].
  const SortSelector({
    required this.currentSort,
    required this.onChanged,
    super.key,
  });

  /// Текущая сортировка.
  final SearchSort currentSort;

  /// Callback при изменении сортировки.
  final ValueChanged<SearchSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.sort,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Sort:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SegmentedButton<SearchSortField>(
              segments: <ButtonSegment<SearchSortField>>[
                ButtonSegment<SearchSortField>(
                  value: SearchSortField.relevance,
                  label: Text(
                    'Relevance${_orderIndicator(SearchSortField.relevance)}',
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                ),
                ButtonSegment<SearchSortField>(
                  value: SearchSortField.date,
                  label: Text(
                    'Date${_orderIndicator(SearchSortField.date)}',
                  ),
                  icon: const Icon(Icons.calendar_today, size: 16),
                ),
                ButtonSegment<SearchSortField>(
                  value: SearchSortField.rating,
                  label: Text(
                    'Rating${_orderIndicator(SearchSortField.rating)}',
                  ),
                  icon: const Icon(Icons.star, size: 16),
                ),
              ],
              selected: <SearchSortField>{currentSort.field},
              onSelectionChanged: (Set<SearchSortField> selected) {
                final SearchSortField field = selected.first;
                if (field == currentSort.field) {
                  // Повторное нажатие — переключаем направление
                  onChanged(currentSort.toggleOrder());
                } else {
                  // Новое поле — сброс на descending
                  onChanged(SearchSort(
                    field: field,
                    order: SearchSortOrder.descending,
                  ));
                }
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStatePropertyAll<TextStyle?>(
                  AppTypography.caption,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Возвращает индикатор направления для активного поля.
  String _orderIndicator(SearchSortField field) {
    if (currentSort.field != field) return '';
    return currentSort.order == SearchSortOrder.ascending ? ' \u2191' : ' \u2193';
  }
}
