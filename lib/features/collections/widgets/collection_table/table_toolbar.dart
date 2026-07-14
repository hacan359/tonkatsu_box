import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Toolbar above the collection table: the column visibility menu and the
/// filter dialog trigger.
class TableToolbar extends StatelessWidget {
  const TableToolbar({
    required this.columnLabels,
    required this.isColumnHidden,
    required this.onToggleColumn,
    required this.activeFilterCount,
    required this.onOpenFilters,
    super.key,
  });

  /// Columns the user may hide, field id → user-facing label.
  final Map<String, String> columnLabels;
  final bool Function(String field) isColumnHidden;
  final ValueChanged<String> onToggleColumn;
  final int activeFilterCount;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        _buildColumnsButton(l),
        const SizedBox(width: AppSpacing.xs),
        _buildFilterButton(l),
      ],
    );
  }

  Widget _buildColumnsButton(S l) {
    return PopupMenuButton<String>(
      tooltip: l.collectionTableColumns,
      color: AppColors.surface,
      onSelected: onToggleColumn,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final MapEntry<String, String> e in columnLabels.entries)
          CheckedPopupMenuItem<String>(
            value: e.key,
            checked: !isColumnHidden(e.key),
            child: Text(e.value, style: AppTypography.body),
          ),
      ],
      child: _buildChip(
        icon: Icons.view_column_outlined,
        label: l.collectionTableColumns,
        active: false,
      ),
    );
  }

  Widget _buildFilterButton(S l) {
    final bool active = activeFilterCount > 0;
    return InkWell(
      onTap: onOpenFilters,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: _buildChip(
        icon: Icons.tune,
        label: active
            ? '${l.collectionFilterFilters} · $activeFilterCount'
            : l.collectionFilterFilters,
        active: active,
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    final Color color = active ? AppColors.brand : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
