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
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return BreadcrumbScope(
      label: S.of(context).databaseTitle,
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
              child: const DatabaseContent(),
            ),
          ),
        ),
      ),
    );
  }
}
