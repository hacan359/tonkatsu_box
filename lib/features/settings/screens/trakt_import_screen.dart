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
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return BreadcrumbScope(
      label: S.of(context).traktTitle,
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
              child: TraktImportContent(
                onImportComplete: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
