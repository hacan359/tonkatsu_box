import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../content/simkl_import_content.dart';

/// Simkl import screen (movies, TV shows and anime in one import).
///
/// Thin wrapper around [SimklImportContent] with a title bar, pushed from
/// settings.
class SimklImportScreen extends StatelessWidget {
  /// Creates a [SimklImportScreen].
  const SimklImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: S.of(context).simklImportTitle),
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
                child: const SimklImportContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
