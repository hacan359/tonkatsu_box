import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'welcome_hero.dart';
import 'welcome_reveal.dart';

/// Your Name — the author name shown on collections you create.
class WelcomeStepName extends ConsumerStatefulWidget {
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
        final bool compact = constraints.maxHeight < 420;

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
                    icon: Icons.badge_outlined,
                    title: l.welcomeNameTitle,
                    subtitle: l.welcomeNameSubtitle,
                    compact: compact,
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                WelcomeReveal(
                  index: 1,
                  child: SizedBox(
                    width: compact ? 240 : 300,
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      style: AppTypography.h3,
                      decoration: InputDecoration(
                        hintText: l.settingsAuthorPlaceholder,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      onChanged: (String value) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .setDefaultAuthor(value.trim());
                      },
                    ),
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                WelcomeReveal(
                  index: 2,
                  child: Text(
                    l.welcomeNameHint,
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
