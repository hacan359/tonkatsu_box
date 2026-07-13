import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../shared/utils/duration_formatter.dart';
import '../../../shared/widgets/dual_date_picker_dialog.dart';

typedef OnDateChanged = Future<void> Function(String type, DateTime date);

class ActivityDatesSection extends ConsumerWidget {
  const ActivityDatesSection({
    required this.addedAt,
    required this.isEditable,
    required this.onDateChanged,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.completionTime,
    super.key,
  });

  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
  final Duration? completionTime;
  final bool isEditable;
  final OnDateChanged onDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(settingsNotifierProvider.select((SettingsState s) => s.dateFormat)),
    );
    final String localeName = Localizations.localeOf(context).toLanguageTag();
    String fmt(DateTime d) => preset.format(d, locale: localeName);

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
          formatter: fmt,
          editable: false,
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.play_circle_outline,
          label: S.of(context).activityDatesStarted,
          date: startedAt,
          formatter: fmt,
          editable: isEditable,
          onTap: () => _pickDate(context, 'started', startedAt),
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.check_circle_outline,
          label: S.of(context).activityDatesCompleted,
          date: completedAt,
          formatter: fmt,
          editable: isEditable,
          onTap: () => _pickDate(context, 'completed', completedAt),
        ),
        if (completionTime != null) ...<Widget>[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatCompletionTime(completionTime!, S.of(context)),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (lastActivityAt != null) ...<Widget>[
          const SizedBox(height: 6),
          _DateRow(
            icon: Icons.update,
            label: S.of(context).sortLastActivityDisplay,
            date: lastActivityAt,
            formatter: fmt,
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

    final DateTime? picked = await showDualDatePicker(
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
    required this.formatter,
    required this.editable,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final DateTime? date;
  final String Function(DateTime) formatter;
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
          date != null ? formatter(date!) : '\u2014',
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
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            child: content,
          ),
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
