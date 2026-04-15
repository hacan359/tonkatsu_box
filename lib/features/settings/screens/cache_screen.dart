// Экран настроек кэширования изображений.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../content/cache_content.dart';

/// Экран настроек кэширования изображений.
///
/// Тонкая обёртка вокруг [CacheContent] с Scaffold/AppBar.
/// Используется при push-навигации на мобильных устройствах.
class CacheScreen extends StatelessWidget {
  /// Создаёт [CacheScreen].
  const CacheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: S.of(context).settingsCache),
        Expanded(
          child: Align(
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
                child: const CacheContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
