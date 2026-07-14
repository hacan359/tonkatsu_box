import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Info button exposing system metadata (added / last activity / completion
/// time) via a tooltip and a dialog.
class SystemMetaInfoButton extends StatelessWidget {
  const SystemMetaInfoButton({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.info_outline,
        size: 16,
        color: AppColors.textTertiary,
      ),
      visualDensity: VisualDensity.compact,
      tooltip: text,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(S.of(ctx).activityDatesTitle),
          content: SingleChildScrollView(
            child: Text(
              text,
              style: AppTypography.body.copyWith(height: 1.6),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.of(ctx).done),
            ),
          ],
        ),
      ),
    );
  }
}
