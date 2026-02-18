// Виджет хлебных крошек для AppBar.

import 'package:flutter/material.dart';

import '../navigation/navigation_shell.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Высота toolbar для breadcrumb AppBar.
const double kBreadcrumbToolbarHeight = 40;

/// Элемент хлебных крошек.
class BreadcrumbItem {
  /// Создаёт элемент хлебных крошек.
  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });

  /// Текст крошки.
  final String label;

  /// Действие при нажатии. Null для последнего (текущего) элемента.
  final VoidCallback? onTap;
}

/// AppBar с хлебными крошками.
///
/// Отображает путь навигации: `/ › Collections › My Games › Zelda` (desktop)
/// или `[logo] › Collections › My Games › Zelda` (mobile).
/// Последний элемент — текущая страница (чуть жирнее, без onTap).
/// Остальные — кликабельные с ховер-эффектом для навигации назад.
///
/// Поддерживает [bottom] для TabBar и [actions] для кнопок справа.
class BreadcrumbAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Создаёт [BreadcrumbAppBar].
  const BreadcrumbAppBar({
    required this.crumbs,
    this.actions,
    this.bottom,
    super.key,
  });

  /// Создаёт fallback AppBar для detail screen коллекции (loading/error).
  ///
  /// Показывает `Collections › {collectionName}` с навигацией назад.
  factory BreadcrumbAppBar.collectionFallback(
    BuildContext context,
    String collectionName,
  ) {
    return BreadcrumbAppBar(
      crumbs: <BreadcrumbItem>[
        BreadcrumbItem(
          label: 'Collections',
          onTap: () => Navigator.of(context)
              .popUntil((Route<dynamic> route) => route.isFirst),
        ),
        BreadcrumbItem(
          label: collectionName,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Элементы хлебных крошек (без корня — он добавляется автоматически).
  final List<BreadcrumbItem> crumbs;

  /// Кнопки действий справа.
  final List<Widget>? actions;

  /// Нижний виджет (например, TabBar).
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kBreadcrumbToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: kBreadcrumbToolbarHeight,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: _BreadcrumbRow(crumbs: crumbs),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Строка хлебных крошек с адаптивным корнем.
class _BreadcrumbRow extends StatelessWidget {
  const _BreadcrumbRow({required this.crumbs});

  final List<BreadcrumbItem> crumbs;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= navigationBreakpoint;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Корень: `/` на desktop, логотип-ссылка на mobile
          if (isDesktop)
            Text(
              '/',
              style: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w300,
              ),
            )
          else
            InkWell(
              onTap: () => Navigator.of(context)
                  .popUntil((Route<dynamic> route) => route.isFirst),
              borderRadius: BorderRadius.circular(4),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Image.asset(
                AppAssets.logo,
                width: 20,
                height: 20,
              ),
            ),
          // Крошки
          for (int i = 0; i < crumbs.length; i++) ...<Widget>[
            _buildSeparator(),
            _buildCrumb(crumbs[i], isLast: i == crumbs.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '›',
        style: AppTypography.body.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildCrumb(BreadcrumbItem item, {required bool isLast}) {
    if (isLast || item.onTap == null) {
      return Text(
        item.label,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return _HoverCrumb(item: item);
  }
}

/// Кликабельная крошка с ховер-эффектом.
class _HoverCrumb extends StatefulWidget {
  const _HoverCrumb({required this.item});

  final BreadcrumbItem item;

  @override
  State<_HoverCrumb> createState() => _HoverCrumbState();
}

class _HoverCrumbState extends State<_HoverCrumb> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: Text(
          widget.item.label,
          style: AppTypography.body.copyWith(
            color: _isHovered
                ? AppColors.textPrimary
                : AppColors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
