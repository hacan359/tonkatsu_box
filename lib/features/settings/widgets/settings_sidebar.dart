// Sidebar для десктопного лейаута настроек.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Элемент sidebar-а настроек.
class SettingsSidebarItem {
  /// Создаёт [SettingsSidebarItem].
  const SettingsSidebarItem({
    required this.label,
    this.id,
    this.isSeparator = false,
  });

  /// Идентификатор секции (для маршрутизации контента).
  final String? id;

  /// Текст элемента.
  final String label;

  /// Визуальный разделитель между группами (вместо обычного элемента).
  final bool isSeparator;
}

/// Sidebar для десктопного лейаута настроек (200px).
///
/// Отображает список элементов с highlight для выбранного.
class SettingsSidebar extends StatelessWidget {
  /// Создаёт [SettingsSidebar].
  const SettingsSidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    super.key,
  });

  /// Индекс выбранного элемента.
  final int selectedIndex;

  /// Callback при выборе элемента.
  final ValueChanged<int> onSelected;

  /// Список элементов sidebar-а.
  final List<SettingsSidebarItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final SettingsSidebarItem item = items[index];

        if (item.isSeparator) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Divider(height: 1, color: AppColors.surfaceBorder),
          );
        }

        final bool isSelected = index == selectedIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 1,
          ),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceLight : null,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                item.label,
                style: AppTypography.body.copyWith(
                  color: isSelected ? AppColors.brand : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
