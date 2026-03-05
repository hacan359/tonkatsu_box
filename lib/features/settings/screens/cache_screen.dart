// Экран настроек кэширования изображений.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../content/cache_content.dart';

/// Экран настроек кэширования изображений.
///
/// Тонкая обёртка вокруг [CacheContent] с Scaffold/AppBar/BreadcrumbScope.
/// Используется при push-навигации на мобильных устройствах.
class CacheScreen extends StatelessWidget {
  /// Создаёт [CacheScreen].
  const CacheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return BreadcrumbScope(
      label: S.of(context).cacheTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 600 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: const CacheContent(),
            ),
          ),
        ),
      ),
    );
  }
}
