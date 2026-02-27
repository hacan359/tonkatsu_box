// Экран импорта данных из оффлайн-выгрузки Trakt.tv.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../content/trakt_import_content.dart';

/// Экран импорта из Trakt.tv ZIP-выгрузки.
///
/// Тонкая обёртка вокруг [TraktImportContent] с Scaffold/AppBar/BreadcrumbScope.
/// Используется при push-навигации на мобильных устройствах.
class TraktImportScreen extends StatelessWidget {
  /// Создаёт [TraktImportScreen].
  const TraktImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: S.of(context).traktTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: TraktImportContent(
            onImportComplete: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
