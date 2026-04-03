// Экран импорта RetroAchievements → IGDB игры.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../content/ra_import_content.dart';

/// Экран импорта RetroAchievements.
///
/// Тонкая обёртка вокруг [RaImportContent] с Scaffold/AppBar.
class RaImportScreen extends StatelessWidget {
  /// Создаёт [RaImportScreen].
  const RaImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Scaffold(
      appBar: ScreenAppBar(title: S.of(context).settingsRaImport),
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
            child: const RaImportContent(),
          ),
        ),
      ),
    );
  }
}
