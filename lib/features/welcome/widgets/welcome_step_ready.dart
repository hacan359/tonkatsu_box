// Шаг 4 Welcome Wizard — финальный экран с CTA.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 4: Ready! — финальный экран с кнопками действий.
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.celebration,
              size: 56,
              color: AppColors.brand,
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).welcomeReadyTitle,
              style: AppTypography.h1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).welcomeReadyMessage,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // CTA: Go to Settings
            SizedBox(
              width: 280,
              child: FilledButton(
                onPressed: onGoToSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusSm,
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(S.of(context).welcomeReadyGoToSettings),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Secondary: Skip
            SizedBox(
              width: 280,
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusSm,
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(S.of(context).welcomeReadySkip),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              S.of(context).welcomeReadyReturnHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
