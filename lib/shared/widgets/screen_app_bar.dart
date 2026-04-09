// Единый AppBar для всех экранов приложения.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Высота toolbar для [ScreenAppBar].
const double kScreenAppBarHeight = 44;

/// Единый AppBar для всех экранов приложения.
///
/// Компактный (44px), с тонкой подсветкой-градиентом снизу.
/// На вложенных экранах автоматически показывает кнопку «назад».
///
/// ```dart
/// Scaffold(
///   appBar: const ScreenAppBar(),
///   body: ...,
/// )
/// ```
class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Создаёт [ScreenAppBar].
  const ScreenAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
  });

  /// Заголовок. Если null — AppBar без заголовка.
  final String? title;

  /// Кнопки действий справа.
  final List<Widget>? actions;

  /// Нижний виджет (например, TabBar).
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kScreenAppBarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceBorder,
            width: 0.5,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.surface,
            AppColors.background,
          ],
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: kScreenAppBarHeight,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppColors.textTertiary,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        leadingWidth: canPop ? 48 : 0,
        title: title != null
            ? Padding(
                padding: EdgeInsets.only(
                  left: !canPop ? 16 : 0,
                ),
                child: _CopyableTitle(title: title!),
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}

class _CopyableTitle extends StatefulWidget {
  const _CopyableTitle({required this.title});

  final String title;

  @override
  State<_CopyableTitle> createState() => _CopyableTitleState();
}

class _CopyableTitleState extends State<_CopyableTitle> {
  bool _hovering = false;
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.title));
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _copied = false;
      }),
      child: GestureDetector(
        onTap: _copy,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                widget.title,
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hovering) ...<Widget>[
              const SizedBox(width: 4),
              Icon(
                _copied ? Icons.check : Icons.copy,
                size: 14,
                color: _copied
                    ? AppColors.statusCompleted
                    : AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
