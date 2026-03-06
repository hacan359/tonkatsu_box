// Шаг 3 Welcome Wizard — выбор языка интерфейса.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 3: Language — выбор языка интерфейса.
class WelcomeStepLanguage extends ConsumerWidget {
  /// Создаёт [WelcomeStepLanguage].
  const WelcomeStepLanguage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final S l = S.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Адаптивные размеры для маленьких экранов
        final bool isSmallScreen = constraints.maxHeight < 450;
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
                  Icons.language,
                  size: iconSize,
                  color: AppColors.brand,
                ),
                SizedBox(height: spacing),
                Text(
                  l.welcomeLanguageTitle,
                  style: AppTypography.h1.copyWith(
                    fontSize: isSmallScreen ? 20 : 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 6 : AppSpacing.sm),
                Text(
                  l.welcomeLanguageSubtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isSmallScreen ? 12 : 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                SizedBox(
                  width: 280,
                  child: _LanguageOption(
                    label: 'English',
                    isSelected: settings.appLanguage == 'en',
                    onTap: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .setAppLanguage('en'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: 280,
                  child: _LanguageOption(
                    label: 'Русский',
                    isSelected: settings.appLanguage == 'ru',
                    onTap: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .setAppLanguage('ru'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.welcomeLanguageHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand.withAlpha(20)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 22,
              color: isSelected ? AppColors.brand : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
