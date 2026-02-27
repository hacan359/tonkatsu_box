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
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: S.of(context).cacheTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: const CacheContent(),
        ),
      ),
    );
  }
}
