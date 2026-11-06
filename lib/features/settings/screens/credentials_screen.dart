import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/frame_page.dart';
import '../content/credentials_content.dart';

class CredentialsScreen extends StatelessWidget {
  const CredentialsScreen({
    super.key,
    this.isInitialSetup = false,
  });

  /// Adds the first-run welcome section above the key form.
  final bool isInitialSetup;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return FramePage(
      title: S.of(context).settingsApiKeys,
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
                child: CredentialsContent(isInitialSetup: isInitialSetup),
              ),
            ),
          ),
    );
  }
}
