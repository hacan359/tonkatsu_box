// Шаг 2 Welcome Wizard — ввод имени автора.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 2: Your Name — ввод имени автора коллекций.
class WelcomeStepName extends ConsumerStatefulWidget {
  /// Создаёт [WelcomeStepName].
  const WelcomeStepName({super.key});

  @override
  ConsumerState<WelcomeStepName> createState() => _WelcomeStepNameState();
}

class _WelcomeStepNameState extends ConsumerState<WelcomeStepName> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final String current = ref.read(settingsNotifierProvider).authorName;
    _controller = TextEditingController(
      text: current == 'User' ? '' : current,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Адаптивные размеры для маленьких экранов
        final bool isSmallScreen = constraints.maxHeight < 400;
        final double iconSize = isSmallScreen ? 40 : 56;
        final double spacing = isSmallScreen ? AppSpacing.sm : 20;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.badge_outlined,
                  size: iconSize,
                  color: AppColors.brand,
                ),
                SizedBox(height: spacing),
                Text(
                  l.welcomeNameTitle,
                  style: AppTypography.h1.copyWith(
                    fontSize: isSmallScreen ? 20 : 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 6 : AppSpacing.sm),
                Text(
                  l.welcomeNameSubtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isSmallScreen ? 12 : 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                SizedBox(
                  width: isSmallScreen ? 240 : 280,
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: AppTypography.h3,
                    decoration: InputDecoration(
                      hintText: l.settingsAuthorPlaceholder,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .setDefaultAuthor(value.trim());
                    },
                  ),
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
                Text(
                  l.welcomeNameHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: isSmallScreen ? 11 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
