import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'copyable_text.dart';

const double kScreenAppBarHeight = 44;

/// Icon size for [ScreenAppBar]'s leading/action buttons. Sized down from the
/// Material default (24) to sit right in the compact 44px bar.
const double kScreenAppBarIconSize = 20;

/// The app-wide [AppBar]: 44px tall, with an automatic back button on pushed
/// routes.
class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
  });

  final String? title;

  final List<Widget>? actions;

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
      decoration: BoxDecoration(
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
                icon: const Icon(Icons.arrow_back,
                    size: kScreenAppBarIconSize),
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

