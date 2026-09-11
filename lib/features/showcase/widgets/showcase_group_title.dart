import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/showcase_settings_provider.dart';

String showcaseGroupLabel(S l, ShowcaseGroup group) => switch (group) {
      ShowcaseGroup.airing => l.showcaseGroupAiring,
      ShowcaseGroup.popular => l.showcaseGroupPopular,
    };

class ShowcaseGroupTitle extends StatelessWidget {
  const ShowcaseGroupTitle({required this.group, super.key});

  final ShowcaseGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        showcaseGroupLabel(S.of(context), group),
        style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
