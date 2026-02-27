// Экран атрибуции API-провайдеров и лицензий.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../content/credits_content.dart';

/// Экран Credits с атрибуцией API-провайдеров и лицензиями.
///
/// Тонкая обёртка вокруг [CreditsContent] с Scaffold/AppBar/BreadcrumbScope.
/// Используется при push-навигации на мобильных устройствах.
class CreditsScreen extends StatelessWidget {
  /// Создаёт [CreditsScreen].
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: S.of(context).creditsTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: ListView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          children: const <Widget>[
            CreditsContent(),
          ],
        ),
      ),
    );
  }
}
