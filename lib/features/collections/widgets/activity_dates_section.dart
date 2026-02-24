// Секция отображения и редактирования дат активности элемента коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: AppColors.brand,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              S.of(context).activityDatesTitle,
              style: AppTypography.h3,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateRow(
          icon: Icons.add_circle_outline,
          label: S.of(context).activityDatesAdded,
          date: addedAt,
          editable: false,
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.play_circle_outline,
          label: S.of(context).activityDatesStarted,
          date: startedAt,
          editable: isEditable,
          onTap: () => _pickDate(context, 'started', startedAt),
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.check_circle_outline,
          label: S.of(context).activityDatesCompleted,
          date: completedAt,
          editable: isEditable,
          onTap: () => _pickDate(context, 'completed', completedAt),
        ),
        if (lastActivityAt != null) ...<Widget>[
          const SizedBox(height: 6),
          _DateRow(
            icon: Icons.update,
            label: S.of(context).activityDatesLastActivity,
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
      helpText: type == 'started'
          ? S.of(context).activityDatesSelectStart
          : S.of(context).activityDatesSelectCompletion,
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
    final Widget content = Row(
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          date != null ? _formatDate(date!) : '\u2014',
          style: AppTypography.body.copyWith(
            fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
            color: date != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        if (editable) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.edit_outlined,
            size: 14,
            color: AppColors.brand,
          ),
        ],
      ],
    );

    if (editable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.sm,
          ),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      child: content,
    );
  }
}
