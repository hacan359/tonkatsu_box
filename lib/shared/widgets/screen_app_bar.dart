// Единый AppBar для всех экранов приложения.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'copyable_text.dart';

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
                child: CopyableText(
                  text: title!,
                  child: Text(
                    title!,
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}

