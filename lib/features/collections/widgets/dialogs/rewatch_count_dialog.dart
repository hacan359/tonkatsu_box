import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

/// Manual editor for the rewatch counter. Pops `(count: N)` on save,
/// `(count: null)` when the field was left empty (clear back to "not
/// tracked"), or `null` when cancelled.
class RewatchCountDialog extends StatefulWidget {
  const RewatchCountDialog({this.initialCount, super.key});

  final int? initialCount;

  static Future<({int? count})?> show(
    BuildContext context, {
    int? initialCount,
  }) {
    return showDialog<({int? count})>(
      context: context,
      builder: (BuildContext context) =>
          RewatchCountDialog(initialCount: initialCount),
    );
  }

  @override
  State<RewatchCountDialog> createState() => _RewatchCountDialogState();
}

class _RewatchCountDialogState extends State<RewatchCountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialCount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop((count: int.tryParse(_controller.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l.rewatchCountEdit, style: AppTypography.h2),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: '0',
            helperText: l.rewatchCountHint,
          ),
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}
