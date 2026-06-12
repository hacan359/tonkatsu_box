import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/tmdb_content_languages.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'welcome_hero.dart';
import 'welcome_reveal.dart';

/// Language — interface language and content language.
class WelcomeStepLanguage extends ConsumerStatefulWidget {
  const WelcomeStepLanguage({super.key});

  @override
  ConsumerState<WelcomeStepLanguage> createState() =>
      _WelcomeStepLanguageState();
}

class _WelcomeStepLanguageState extends ConsumerState<WelcomeStepLanguage> {
  /// True once the user picks a content language by hand — disables the
  /// auto-sync with the UI language so the deliberate choice isn't overwritten.
  bool _contentLangTouched = false;

  void _onUiLanguageSelected(String uiCode) {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    notifier.setAppLanguage(uiCode);
    if (!_contentLangTouched) {
      notifier.setTmdbLanguage(defaultContentLanguageForUi(uiCode));
    }
  }

  void _onContentLanguageSelected(String code) {
    setState(() => _contentLangTouched = true);
    ref.read(settingsNotifierProvider.notifier).setTmdbLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final S l = S.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 470;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                WelcomeReveal(
                  index: 0,
                  child: WelcomeHero(
                    icon: Icons.language,
                    title: l.welcomeLanguageTitle,
                    subtitle: l.welcomeLanguageSubtitle,
                    compact: compact,
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                WelcomeReveal(
                  index: 1,
                  child: SizedBox(
                    width: 300,
                    child: _LanguageOption(
                      label: 'English',
                      isSelected: settings.appLanguage == 'en',
                      onTap: () => _onUiLanguageSelected('en'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                WelcomeReveal(
                  index: 2,
                  child: SizedBox(
                    width: 300,
                    child: _LanguageOption(
                      label: 'Русский',
                      isSelected: settings.appLanguage == 'ru',
                      onTap: () => _onUiLanguageSelected('ru'),
                    ),
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                WelcomeReveal(
                  index: 3,
                  child: SizedBox(
                    width: 300,
                    child: _ContentLanguageDropdown(
                      value: settings.tmdbLanguage,
                      label: l.settingsContentLanguage,
                      subtitle: l.settingsContentLanguageSubtitle,
                      onChanged: _onContentLanguageSelected,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                WelcomeReveal(
                  index: 4,
                  child: Text(
                    l.welcomeLanguageHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContentLanguageDropdown extends StatelessWidget {
  const _ContentLanguageDropdown({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });

  final String value;
  final String label;
  final String subtitle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = kTmdbContentLanguages
        .any((TmdbContentLanguage lang) => lang.code == value);
    final String effectiveValue =
        hasValue ? value : kTmdbContentLanguages.first.code;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: effectiveValue,
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.textTertiary),
              dropdownColor: AppColors.surface,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
              items: <DropdownMenuItem<String>>[
                for (final TmdbContentLanguage lang in kTmdbContentLanguages)
                  DropdownMenuItem<String>(
                    value: lang.code,
                    child: Text(lang.nativeName),
                  ),
              ],
              onChanged: (String? code) {
                if (code != null) onChanged(code);
              },
            ),
          ),
        ),
      ],
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
        duration: AppDurations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    AppColors.brand.withAlpha(38),
                    AppColors.brand.withAlpha(8),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.surface,
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
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
