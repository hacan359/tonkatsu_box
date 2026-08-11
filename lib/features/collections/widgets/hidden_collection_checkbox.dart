import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Shared by the create and edit dialogs so the two cannot drift apart.
class HiddenCollectionCheckbox extends StatelessWidget {
  const HiddenCollectionCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return CheckboxListTile(
      value: value,
      onChanged: (bool? next) => onChanged(next ?? false),
      title: Text(l.createCollectionHiddenLabel),
      subtitle: Text(l.createCollectionHiddenHint),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
