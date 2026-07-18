// Release-notes dialog shown once after an app update.
// Strings are intentionally EN-only for now: the changelog itself is
// English and is not translated (owner's call, see whats_new_service.dart).

import 'package:flutter/material.dart';

import '../../core/services/whats_new_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'mini_markdown_text.dart';

/// Shows the "What's new" dialog; resolves when the user closes it.
Future<void> showWhatsNewDialog(
  BuildContext context,
  WhatsNewContent content,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => WhatsNewDialog(content: content),
  );
}

/// Scrollable release notes for one version.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({required this.content, super.key});

  final WhatsNewContent content;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          const Icon(Icons.celebration_outlined, color: AppColors.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text("What's new in ${content.version}"),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: MiniMarkdownText(
            text: content.body,
            style: AppTypography.bodySmall,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
