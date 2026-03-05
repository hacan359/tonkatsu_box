// Экран настройки API ключей (IGDB, SteamGridDB, TMDB).

import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../content/credentials_content.dart';

/// Экран настройки API ключей.
///
/// Тонкая обёртка вокруг [CredentialsContent] с Scaffold/AppBar/BreadcrumbScope.
/// Используется при push-навигации на мобильных устройствах.
class CredentialsScreen extends StatelessWidget {
  /// Создаёт [CredentialsScreen].
  const CredentialsScreen({
    super.key,
    this.isInitialSetup = false,
  });

  /// Флаг начальной настройки (показывает Welcome секцию).
  final bool isInitialSetup;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return BreadcrumbScope(
      label: S.of(context).credentialsTitle,
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
              child: CredentialsContent(isInitialSetup: isInitialSetup),
            ),
          ),
        ),
      ),
    );
  }
}
