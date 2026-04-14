// Экран управления базой данных и конфигурацией.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../content/database_content.dart';

/// Экран управления базой данных.
///
/// Тонкая обёртка вокруг [DatabaseContent] с Scaffold/AppBar.
/// Используется при push-навигации на мобильных устройствах.
class DatabaseScreen extends StatelessWidget {
  /// Создаёт [DatabaseScreen].
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settingsDatabase)),
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
    );
  }
}
