import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Dialog for setting / clearing the per-collection display-name override.
///
/// `currentOverride` — the override that is currently saved (null when none).
/// `originalName` — the cached API title shown as a subtitle for reference.
/// Returns one of:
///   * a non-empty trimmed [String] — user wants to set a new override
///   * an empty string — user picked "Reset to original" (clear override)
///   * `null` — user cancelled
class RenameItemDialog extends StatefulWidget {
  const RenameItemDialog({
    required this.currentOverride,
    required this.originalName,
    super.key,
  });

  final String? currentOverride;
  final String originalName;

  static Future<String?> show(
    BuildContext context, {
    required String? currentOverride,
    required String originalName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameItemDialog(
        currentOverride: currentOverride,
        originalName: originalName,
      ),
    );
  }

  @override
  State<RenameItemDialog> createState() => _RenameItemDialogState();
}

class _RenameItemDialogState extends State<RenameItemDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentOverride ?? widget.originalName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.renameItem),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l.renameDialogHint),
              onSubmitted: (String value) {
                Navigator.of(context).pop(value.trim());
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.renameOriginalLabel(widget.originalName),
              style: AppTypography.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (widget.currentOverride != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(l.renameResetToOriginal),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l.save),
        ),
      ],
    );
  }
}
