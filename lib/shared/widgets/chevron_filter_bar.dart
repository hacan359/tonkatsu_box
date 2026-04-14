// Переиспользуемые chevron-сегменты для filter-баров.
//
// Используются на AllItemsScreen и CollectionScreen для фильтрации
// по типу медиа и статусу.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/item_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Универсальный chevron-сегмент для filter-баров.
///
/// V-вырез слева (кроме первого) и V-конец справа (кроме последнего).
/// В режиме [compact] показывает [Tooltip] + иконку вместо текста.
class ChevronSegment extends StatelessWidget {
  /// Создаёт [ChevronSegment].
  const ChevronSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  /// Текстовая метка сегмента.
  final String label;

  /// Иконка для compact-режима.
  final IconData icon;

  /// Выбран ли сегмент.
  final bool selected;

  /// Цвет заливки при выборе.
  final Color accentColor;

  /// Первый сегмент (прямой левый край).
  final bool isFirst;

  /// Последний сегмент (прямой правый край).
  final bool isLast;

  /// Обработчик нажатия.
  final VoidCallback onTap;

  /// Показывать иконку вместо текста.
  final bool compact;

  /// Ширина chevron-скоса.
  static const double chevronWidth = 6;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor : AppColors.surface;
    final Color contentColor =
        selected ? AppColors.background : AppColors.textSecondary;

    return ClipPath(
      clipper: ChevronClipper(
        chevronWidth: chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: isFirst ? 4 : chevronWidth + 1,
                right: isLast ? 4 : chevronWidth + 1,
              ),
              child: Center(
                child: compact
                    ? Tooltip(
                        message: label,
                        child: Icon(icon, size: 18, color: contentColor),
                      )
                    : Text(
                        label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.bodySmall.copyWith(
                          color: contentColor,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomClipper, вырезающий из прямоугольника форму стрелочки.
class ChevronClipper extends CustomClipper<Path> {
  /// Создаёт [ChevronClipper].
  const ChevronClipper({
    required this.chevronWidth,
    required this.hasLeftNotch,
    required this.hasRightPoint,
  });

  /// Ширина V-скоса.
  final double chevronWidth;

  /// V-вырез слева.
  final bool hasLeftNotch;

  /// V-остриё справа.
  final bool hasRightPoint;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double mid = size.height / 2;

    if (hasLeftNotch) {
      path.moveTo(0, 0);
      path.lineTo(chevronWidth, mid);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
    }

    if (hasRightPoint) {
      path.lineTo(size.width - chevronWidth, size.height);
      path.lineTo(size.width, mid);
      path.lineTo(size.width - chevronWidth, 0);
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ChevronClipper old) {
    return chevronWidth != old.chevronWidth ||
        hasLeftNotch != old.hasLeftNotch ||
        hasRightPoint != old.hasRightPoint;
  }
}

/// Chevron-сегмент в виде dropdown для выбора статуса.
///
/// Визуально идентичен [ChevronSegment] (всегда `isLast: true`), но при
/// нажатии открывает [PopupMenuButton] со списком статусов.
class StatusDropdownSegment extends StatelessWidget {
  /// Создаёт [StatusDropdownSegment].
  const StatusDropdownSegment({
    required this.status,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  /// Текущий выбранный статус (null = все).
  final ItemStatus? status;

  /// Показывать иконку вместо текста.
  final bool compact;

  /// Callback при изменении статуса.
  final ValueChanged<ItemStatus?> onChanged;

  static const double _chevronWidth = 6;

  static const List<ItemStatus> _order = <ItemStatus>[
    ItemStatus.inProgress,
    ItemStatus.planned,
    ItemStatus.notStarted,
    ItemStatus.completed,
    ItemStatus.dropped,
  ];

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool active = status != null;
    final Color accentColor = active ? status!.color : AppColors.surface;
    final Color contentColor =
        active ? AppColors.background : AppColors.textSecondary;
    final String label = active ? status!.genericLabel(l) : l.homeFilterAll;
    final IconData icon = active ? status!.materialIcon : Icons.filter_list;

    return PopupMenuButton<String>(
      onSelected: (String v) {
        onChanged(v == 'all' ? null : ItemStatus.fromString(v));
      },
      offset: const Offset(0, 40),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
        _menuItem('all', Icons.filter_list_off, l.homeFilterAll,
            status == null, null),
        const PopupMenuDivider(height: 8),
        for (final ItemStatus s in _order)
          _menuItem(s.value, s.materialIcon, s.genericLabel(l),
              status == s, s.color),
      ],
      child: ClipPath(
        clipper: const ChevronClipper(
          chevronWidth: _chevronWidth,
          hasLeftNotch: true,
          hasRightPoint: false,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          color: accentColor,
          child: Padding(
            padding: const EdgeInsets.only(
              left: _chevronWidth + 1,
              right: 4,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (compact)
                      Tooltip(
                        message: label,
                        child: Icon(icon, size: 18, color: contentColor),
                      )
                    else
                      Text(
                        label,
                        maxLines: 1,
                        style: AppTypography.bodySmall.copyWith(
                          color: contentColor,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: contentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    bool selected,
    Color? statusColor,
  ) {
    final Color itemColor = selected
        ? (statusColor ?? AppColors.brand)
        : AppColors.textPrimary;
    final Color iconColor = selected
        ? (statusColor ?? AppColors.brand)
        : AppColors.textTertiary;

    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: itemColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
