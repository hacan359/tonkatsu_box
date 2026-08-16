import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// A single name suggestion shown as a chip above the text field.
class RenameSuggestion {
  const RenameSuggestion({required this.label, required this.value});

  /// Short tag rendered on the chip (e.g. "Romaji", "English").
  final String label;

  /// Text that will replace the input value when the chip is tapped.
  final String value;
}

/// Pops the trimmed new override, an empty string for "reset to original"
/// (clear the override), or `null` on cancel.
class RenameItemDialog extends StatefulWidget {
  const RenameItemDialog({
    required this.currentOverride,
    required this.originalName,
    this.suggestions = const <RenameSuggestion>[],
    super.key,
  });

  final String? currentOverride;
  final String originalName;
  final List<RenameSuggestion> suggestions;

  static Future<String?> show(
    BuildContext context, {
    required String? currentOverride,
    required String originalName,
    List<RenameSuggestion> suggestions = const <RenameSuggestion>[],
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameItemDialog(
        currentOverride: currentOverride,
        originalName: originalName,
        suggestions: suggestions,
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

  void _applySuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.rename),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.suggestions.isNotEmpty) ...<Widget>[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final RenameSuggestion s in widget.suggestions)
                    ActionChip(
                      label: Text('${s.label}: ${s.value}'),
                      onPressed: () => _applySuggestion(s.value),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
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
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
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
