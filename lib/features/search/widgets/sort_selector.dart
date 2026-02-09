// Виджет выбора сортировки результатов поиска.

import 'package:flutter/material.dart';

import '../../../shared/models/search_sort.dart';

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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.sort,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Sort:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
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
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStatePropertyAll<TextStyle?>(
                  theme.textTheme.labelSmall,
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
