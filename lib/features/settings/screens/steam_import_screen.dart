// Экран импорта библиотеки Steam → IGDB игры.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../content/steam_import_content.dart';

/// Экран импорта библиотеки Steam.
///
/// Тонкая обёртка вокруг [SteamImportContent] с Scaffold/AppBar/BreadcrumbScope.
class SteamImportScreen extends StatelessWidget {
  /// Создаёт [SteamImportScreen].
  const SteamImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return BreadcrumbScope(
      label: S.of(context).steamImportTitle,
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
              child: const SteamImportContent(),
            ),
          ),
        ),
      ),
    );
  }
}
