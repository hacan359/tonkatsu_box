// AppBar, автоматически собирающий крошки из BreadcrumbScope.

import 'package:flutter/material.dart';

import 'breadcrumb_app_bar.dart';
import 'breadcrumb_scope.dart';

/// AppBar, автоматически собирающий крошки из [BreadcrumbScope].
///
/// Все крошки кроме последней кликабельны:
/// - Первая крошка → `popUntil(isFirst)` (корень таба)
/// - Промежуточные → `pop()` N раз (расстояние от конца)
/// - Последняя (текущая) → без onTap
///
/// ```dart
/// BreadcrumbScope(
///   label: 'Credentials',
///   child: Scaffold(
///     appBar: const AutoBreadcrumbAppBar(),
///     body: ...,
///   ),
/// )
/// ```
class AutoBreadcrumbAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Создаёт [AutoBreadcrumbAppBar].
  const AutoBreadcrumbAppBar({
    super.key,
    this.actions,
    this.bottom,
    this.accentColor,
  });

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
    final List<String> labels = BreadcrumbScope.of(context);

    final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[];
    for (int i = 0; i < labels.length; i++) {
      final bool isLast = i == labels.length - 1;

      if (isLast) {
        crumbs.add(BreadcrumbItem(label: labels[i]));
      } else if (i == 0) {
        // Корневая крошка — вернуться в начало таба.
        crumbs.add(BreadcrumbItem(
          label: labels[i],
          onTap: () => Navigator.of(context)
              .popUntil((Route<dynamic> route) => route.isFirst),
        ));
      } else {
        // Промежуточная — pop N раз.
        final int popsNeeded = labels.length - 1 - i;
        crumbs.add(BreadcrumbItem(
          label: labels[i],
          onTap: () {
            for (int p = 0; p < popsNeeded; p++) {
              Navigator.of(context).pop();
            }
          },
        ));
      }
    }

    return BreadcrumbAppBar(
      crumbs: crumbs,
      actions: actions,
      bottom: bottom,
      accentColor: accentColor,
    );
  }
}
