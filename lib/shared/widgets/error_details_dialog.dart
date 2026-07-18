import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../extensions/snackbar_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Copies `message\n\ndetail` to the clipboard and confirms with a snack.
void copyErrorDetails(
  BuildContext context, {
  required String message,
  String? detail,
}) {
  final String text =
      (detail == null || detail.isEmpty) ? message : '$message\n\n$detail';
  Clipboard.setData(ClipboardData(text: text));
  context.showSnack(S.of(context).errorDetailsCopied, type: SnackType.info);
}

/// Full error [message] + optional debug [detail], nothing truncated,
/// one button copies both.
Future<void> showErrorDetailsDialog(
  BuildContext context, {
  required String message,
  String? detail,
  String? title,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      final S l = S.of(dialogContext);
      return AlertDialog(
        title: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title ?? l.errorDetailsTitle)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SelectableText(message, style: AppTypography.body),
              if (detail != null && detail.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: SelectableText(
                    detail,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => copyErrorDetails(
              dialogContext,
              message: message,
              detail: detail,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l.copyErrorDetails),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.close),
          ),
        ],
      );
    },
  );
}
