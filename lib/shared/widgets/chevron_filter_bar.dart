// Переиспользуемые chevron-сегменты для filter-баров.
//
// Используются на AllItemsScreen и CollectionScreen для фильтрации
// по типу медиа и статусу.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../models/item_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Универсальный chevron-сегмент для filter-баров.
///
/// V-вырез слева (кроме первого) и V-конец справа (кроме последнего).
/// В режиме [compact] показывает [Tooltip] + иконку вместо текста.
/// Если задан [subtitle] — рендерится двухстрочно (subtitle сверху мелким,
/// label снизу). [compact] и [subtitle] взаимоисключающие: при `compact: true`
/// subtitle игнорируется.
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
    this.subtitle,
    this.tintWhenInactive = false,
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

  /// Опциональный двухстрочный режим: subtitle сверху, label снизу.
  final String? subtitle;

  /// В неактивном состоянии тонировать фон/контент в [accentColor]
  /// приглушённо вместо нейтрального серого.
  final bool tintWhenInactive;

  /// Ширина chevron-скоса.
  static const double chevronWidth = 6;

  /// Альфа фона для неактивного тонированного сегмента (~15%).
  static const int inactiveTintBgAlpha = 38;

  /// Альфа контента (текст/иконка) для неактивного тонированного сегмента.
  static const int inactiveTintContentAlpha = 220;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color contentColor;
    if (selected) {
      bg = accentColor;
      contentColor = AppColors.background;
    } else if (tintWhenInactive) {
      bg = accentColor.withAlpha(inactiveTintBgAlpha);
      contentColor = accentColor.withAlpha(inactiveTintContentAlpha);
    } else {
      bg = AppColors.surface;
      contentColor = AppColors.textSecondary;
    }

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
                child: buildChevronContent(
                  context: context,
                  label: label,
                  icon: icon,
                  subtitle: subtitle,
                  contentColor: contentColor,
                  selected: selected,
                  compact: compact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Контент chevron-сегмента (используется и в [ChevronSegment], и в
/// [DropdownChevronSegment]).
///
/// - `compact: true` → только иконка с [Tooltip].
/// - `subtitle != null` → двухстрочный текст.
/// - иначе — однострочный label.
///
/// На узких экранах ([isCompactScreen]) шрифты сжимаются ~до 83% — по
/// аналогии с MediaPosterCard / RatingBadge.
Widget buildChevronContent({
  required BuildContext context,
  required String label,
  required IconData icon,
  required String? subtitle,
  required Color contentColor,
  required bool selected,
  required bool compact,
}) {
  if (compact) {
    return Tooltip(
      message: label,
      child: Icon(icon, size: 18, color: contentColor),
    );
  }

  final bool dense = isCompactScreen(context);
  // 12 → 10, 9 → 8 — пропорция как у MediaPosterCard.tagName / RatingBadge.
  final double labelSize = dense ? 10 : 12;
  final double subtitleSize = dense ? 8 : 9;

  if (subtitle == null) {
    return Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: AppTypography.bodySmall.copyWith(
        color: contentColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: labelSize,
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        subtitle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: subtitleSize,
          color: contentColor.withAlpha(selected ? 180 : 140),
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: AppTypography.bodySmall.copyWith(
          color: contentColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: labelSize,
          height: 1.1,
        ),
      ),
    ],
  );
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
/// Опциональный [subtitle] рендерится двухстрочно (subtitle сверху мелким,
/// label снизу) — игнорируется в `compact` режиме.
class StatusDropdownSegment extends StatelessWidget {
  /// Создаёт [StatusDropdownSegment].
  const StatusDropdownSegment({
    required this.status,
    required this.compact,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// Текущий выбранный статус (null = все).
  final ItemStatus? status;

  /// Показывать иконку вместо текста.
  final bool compact;

  /// Callback при изменении статуса.
  final ValueChanged<ItemStatus?> onChanged;

  /// Опциональный двухстрочный режим: подпись сверху, выбранный статус снизу.
  final String? subtitle;

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
                    Flexible(
                      child: buildChevronContent(
                        context: context,
                        label: label,
                        icon: icon,
                        subtitle: subtitle,
                        contentColor: contentColor,
                        selected: active,
                        compact: compact,
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

/// Универсальный chevron-сегмент с [PopupMenuButton] внутри.
///
/// Аналог [ChevronSegment], но при нажатии открывает меню. Элементы меню
/// строит [menuBuilder]. Поддерживает опциональный [subtitle] (двухстрочный
/// режим) и индикатор выпадания справа от label.
class DropdownChevronSegment<T extends Object> extends StatelessWidget {
  /// Создаёт [DropdownChevronSegment].
  const DropdownChevronSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.menuBuilder,
    required this.onSelected,
    this.subtitle,
    this.compact = false,
    super.key,
  });

  /// Текстовая метка сегмента.
  final String label;

  /// Иконка для compact-режима.
  final IconData icon;

  /// Подсветка как «выбранный».
  final bool selected;

  /// Цвет заливки при выборе.
  final Color accentColor;

  /// Первый сегмент (прямой левый край).
  final bool isFirst;

  /// Последний сегмент (прямой правый край).
  final bool isLast;

  /// Построитель пунктов меню.
  final List<PopupMenuEntry<T>> Function(BuildContext) menuBuilder;

  /// Callback при выборе пункта.
  final ValueChanged<T?> onSelected;

  /// Опциональный двухстрочный режим.
  final String? subtitle;

  /// Показывать только иконку.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor : AppColors.surface;
    final Color contentColor =
        selected ? AppColors.background : AppColors.textSecondary;

    return ClipPath(
      clipper: ChevronClipper(
        chevronWidth: ChevronSegment.chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: bg,
        child: PopupMenuButton<T>(
          onSelected: onSelected,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          color: AppColors.surface,
          constraints: const BoxConstraints(maxHeight: 400),
          itemBuilder: menuBuilder,
          child: Padding(
            padding: EdgeInsets.only(
              left: isFirst ? 4 : ChevronSegment.chevronWidth + 1,
              right: isLast ? 4 : ChevronSegment.chevronWidth + 1,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: buildChevronContent(
                      context: context,
                      label: label,
                      icon: icon,
                      subtitle: subtitle,
                      contentColor: contentColor,
                      selected: selected,
                      compact: compact,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 14, color: contentColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
