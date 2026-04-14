// Экран атрибуции API-провайдеров и лицензий.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../content/credits_content.dart';

/// Экран Credits с атрибуцией API-провайдеров и лицензиями.
///
/// Тонкая обёртка вокруг [CreditsContent] с Scaffold/AppBar.
/// Используется при push-навигации на мобильных устройствах.
class CreditsScreen extends StatelessWidget {
  /// Создаёт [CreditsScreen].
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: S.of(context).settingsCreditsLicenses),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                children: const <Widget>[
                  CreditsContent(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
