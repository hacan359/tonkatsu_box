// Виджет хлебных крошек для AppBar.

import 'package:flutter/material.dart';

import '../navigation/navigation_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Высота toolbar для breadcrumb AppBar.
const double kBreadcrumbToolbarHeight = 44;

/// Максимальная ширина текста текущей (последней) крошки.
const double _currentCrumbMaxWidth = 300;

/// Максимальная ширина текста промежуточной крошки.
const double _crumbMaxWidth = 180;

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
/// Отображает путь навигации: `/ > Collections > My Games > Zelda` (desktop)
/// или `← > Collections > My Games > Zelda` (mobile).
/// Последний элемент — текущая страница (жирнее, без onTap).
/// Остальные — кликабельные с ховер-эффектом для навигации назад.
///
/// На мобильном при длинных путях (>2 крошек) промежуточные сворачиваются в `…`.
///
/// Поддерживает [bottom] для TabBar, [actions] для кнопок справа,
/// и [accentColor] для тонкой линии-акцента снизу.
class BreadcrumbAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Создаёт [BreadcrumbAppBar].
  const BreadcrumbAppBar({
    required this.crumbs,
    this.actions,
    this.bottom,
    this.accentColor,
    super.key,
  });


  /// Элементы хлебных крошек (без корня — он добавляется автоматически).
  final List<BreadcrumbItem> crumbs;

  /// Кнопки действий справа.
  final List<Widget>? actions;

  /// Нижний виджет (например, TabBar).
  final PreferredSizeWidget? bottom;

  /// Цвет акцентной линии снизу. Null — без линии.
  final Color? accentColor;

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kBreadcrumbToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final Widget appBar = AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: kBreadcrumbToolbarHeight,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: _BreadcrumbRow(crumbs: crumbs),
      actions: actions,
      bottom: bottom,
    );

    if (accentColor == null) {
      return appBar;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: accentColor!.withAlpha(50),
          ),
        ),
      ),
      child: appBar,
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
    final bool canPop = Navigator.of(context).canPop();

    // Определяем отображаемые крошки: на мобильном >2 — сворачиваем
    final List<_CrumbEntry> entries = _buildEntries(isDesktop);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Корень: `/` на desktop, ← на mobile (если есть куда вернуться)
          if (isDesktop)
            Text(
              '/',
              style: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w300,
              ),
            )
          else if (canPop)
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              color: AppColors.textTertiary,
            ),
          // Крошки
          for (final _CrumbEntry entry in entries) ...<Widget>[
            _buildSeparator(),
            if (entry.isEllipsis)
              Text(
                '…',
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              )
            else
              _buildCrumb(entry.item!, isLast: entry.isLast),
          ],
        ],
      ),
    );
  }

  /// Строит список отображаемых элементов с учётом коллапса на мобильном.
  List<_CrumbEntry> _buildEntries(bool isDesktop) {
    if (crumbs.isEmpty) return <_CrumbEntry>[];

    // На мобильном при >2 крошек: [first] … [last]
    if (!isDesktop && crumbs.length > 2) {
      return <_CrumbEntry>[
        _CrumbEntry(item: crumbs.first, isLast: false),
        const _CrumbEntry.ellipsis(),
        _CrumbEntry(item: crumbs.last, isLast: true),
      ];
    }

    return <_CrumbEntry>[
      for (int i = 0; i < crumbs.length; i++)
        _CrumbEntry(item: crumbs[i], isLast: i == crumbs.length - 1),
    ];
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.chevron_right,
        size: 14,
        color: AppColors.textTertiary.withAlpha(128),
      ),
    );
  }

  Widget _buildCrumb(BreadcrumbItem item, {required bool isLast}) {
    if (isLast || item.onTap == null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLast ? _currentCrumbMaxWidth : _crumbMaxWidth,
        ),
        child: Text(
          item.label,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            color: isLast ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return _HoverCrumb(item: item);
  }
}

/// Запись крошки для отображения (может быть реальной или `…`).
class _CrumbEntry {
  const _CrumbEntry({this.item, required this.isLast}) : isEllipsis = false;

  const _CrumbEntry.ellipsis()
      : item = null,
        isLast = false,
        isEllipsis = true;

  /// Элемент крошки. Null для `…`.
  final BreadcrumbItem? item;

  /// Является ли последним (текущим) элементом.
  final bool isLast;

  /// Является ли многоточием (сворачивание промежуточных крошек).
  final bool isEllipsis;
}

/// Кликабельная крошка с ховер-эффектом (pill-фон).
class _HoverCrumb extends StatefulWidget {
  const _HoverCrumb({required this.item});

  final BreadcrumbItem item;

  @override
  State<_HoverCrumb> createState() => _HoverCrumbState();
}

class _HoverCrumbState extends State<_HoverCrumb> {
  bool _isHovered = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'BreadcrumbCrumb');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.item.onTap?.call();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _focusNode,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.item.onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.surfaceLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _crumbMaxWidth),
                child: Text(
                  widget.item.label,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    color: _isHovered
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
