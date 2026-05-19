import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class CreateTierListDialog {
  CreateTierListDialog._();

  static Future<String?> show(BuildContext context, {String? initialName}) {
    final TextEditingController controller =
        TextEditingController(text: initialName ?? '');
    final S l = S.of(context);
    final Future<String?> result = showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tierListCreateFromCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tierListNameHint),
          onSubmitted: (String value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.create),
          ),
        ],
      ),
    );
    return result.whenComplete(controller.dispose);
  }
}
