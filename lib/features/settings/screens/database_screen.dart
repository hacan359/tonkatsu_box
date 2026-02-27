// Экран управления базой данных и конфигурацией.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../content/database_content.dart';

/// Экран управления базой данных.
///
/// Тонкая обёртка вокруг [DatabaseContent] с Scaffold/AppBar/BreadcrumbScope.
/// Используется при push-навигации на мобильных устройствах.
class DatabaseScreen extends StatelessWidget {
  /// Создаёт [DatabaseScreen].
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: S.of(context).databaseTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: const DatabaseContent(),
        ),
      ),
    );
  }
}
