// Секция отображения и редактирования дат активности элемента коллекции.

import 'package:flutter/material.dart';

/// Форматирует [DateTime] в читаемую строку (например, "Jan 15, 2025").
String _formatDate(DateTime date) {
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Колбэк для изменения даты.
///
/// [type] — тип даты ('started' или 'completed'),
/// [date] — выбранная дата.
typedef OnDateChanged = Future<void> Function(String type, DateTime date);

/// Секция для отображения и редактирования дат активности.
///
/// Показывает Added, Started, Completed и Last Activity.
/// Позволяет редактировать Started и Completed через DatePicker.
class ActivityDatesSection extends StatelessWidget {
  /// Создаёт [ActivityDatesSection].
  const ActivityDatesSection({
    required this.addedAt,
    required this.isEditable,
    required this.onDateChanged,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    super.key,
  });

  /// Дата добавления (readonly).
  final DateTime addedAt;

  /// Дата начала.
  final DateTime? startedAt;

  /// Дата завершения.
  final DateTime? completedAt;

  /// Дата последней активности (readonly).
  final DateTime? lastActivityAt;

  /// Можно ли редактировать даты.
  final bool isEditable;

  /// Колбэк при изменении даты.
  final OnDateChanged onDateChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Activity Dates',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateRow(
          icon: Icons.add_circle_outline,
          label: 'Added',
          date: addedAt,
          editable: false,
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.play_circle_outline,
          label: 'Started',
          date: startedAt,
          editable: isEditable,
          onTap: () => _pickDate(context, 'started', startedAt),
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          date: completedAt,
          editable: isEditable,
          onTap: () => _pickDate(context, 'completed', completedAt),
        ),
        if (lastActivityAt != null) ...<Widget>[
          const SizedBox(height: 6),
          _DateRow(
            icon: Icons.update,
            label: 'Last Activity',
            date: lastActivityAt,
            editable: false,
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    String type,
    DateTime? current,
  ) async {
    final DateTime initialDate = current ?? DateTime.now();
    final DateTime firstDate = DateTime(1980);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: type == 'started' ? 'Select start date' : 'Select completion date',
    );

    if (picked != null && context.mounted) {
      await onDateChanged(type, picked);
    }
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.date,
    required this.editable,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final DateTime? date;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Widget content = Row(
      children: <Widget>[
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          date != null ? _formatDate(date!) : '\u2014',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
            color: date != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        if (editable) ...<Widget>[
          const SizedBox(width: 4),
          Icon(
            Icons.edit_outlined,
            size: 14,
            color: colorScheme.primary,
          ),
        ],
      ],
    );

    if (editable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: content,
    );
  }
}
