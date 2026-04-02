// Шаг 6 Welcome Wizard — финальный экран с CTA.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 6: Ready! — финальный экран с кнопками действий.
class WelcomeStepReady extends StatelessWidget {
  /// Создаёт [WelcomeStepReady].
  const WelcomeStepReady({
    required this.onGoToSettings,
    required this.onSkip,
    super.key,
  });

  /// Переход к Settings → Credentials.
  final VoidCallback onGoToSettings;

  /// Пропустить — перейти к Home.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Адаптивные размеры для маленьких экранов
        final bool isSmallScreen = constraints.maxHeight < 500;
        final double iconSize = isSmallScreen ? 40 : 56;
        final double spacing = isSmallScreen ? AppSpacing.sm : 20;
        final double titleFontSize = isSmallScreen ? 20 : 22;
        final double bodyFontSize = isSmallScreen ? 12 : 13;

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
                  Icons.celebration,
                  size: iconSize,
                  color: AppColors.brand,
                ),
                SizedBox(height: spacing),
                Text(
                  l.welcomeReadyTitle,
                  style: AppTypography.h1.copyWith(fontSize: titleFontSize),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 6 : AppSpacing.sm),
                Text(
                  l.welcomeReadyMessage,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: bodyFontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),

                // CTA: Go to Settings
                SizedBox(
                  width: isSmallScreen ? 240 : 280,
                  child: FilledButton(
                    onPressed: onGoToSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      textStyle: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(l.welcomeReadyGoToSettings),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : AppSpacing.sm),

                // Secondary: Skip
                SizedBox(
                  width: isSmallScreen ? 240 : 280,
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      textStyle: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(l.welcomeReadySkip),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : AppSpacing.md),

                Text(
                  l.welcomeReadyReturnHint,
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
