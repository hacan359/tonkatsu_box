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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.badge_outlined,
              size: 56,
              color: AppColors.brand,
            ),
            const SizedBox(height: 20),
            Text(
              l.welcomeNameTitle,
              style: AppTypography.h1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.welcomeNameSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 280,
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
            const SizedBox(height: AppSpacing.md),
            Text(
              l.welcomeNameHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
