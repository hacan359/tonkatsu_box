import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';

/// Prompts and confirmations used by the wishlist screen. Pure dialogs —
/// they return the user's choice and never call the wishlist notifier so
/// the screen keeps the side-effect plumbing in one place.
class WishlistDialogs {
  const WishlistDialogs._();

  /// Asks the user for a tag to apply to a bulk selection. Returns null if
  /// cancelled or the entered text was empty after trimming.
  static Future<String?> promptBulkTag(
    BuildContext context,
    int count,
  ) async {
    final S l = S.of(context);
    final TextEditingController controller = TextEditingController();
    final String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.wishlistBulkApplyTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.wishlistBulkApplyTagHint(count)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l.wishlistTagPlaceholder),
              onSubmitted: (String v) =>
                  Navigator.of(context).pop(v.trim()),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l.apply),
          ),
        ],
      ),
    );
    if (input == null || input.isEmpty) return null;
    return input;
  }

  /// Asks the user for a new name for [currentTag]. Returns null when the
  /// user cancelled, entered blank, or kept the original name.
  static Future<String?> promptRenameTag(
    BuildContext context,
    String? currentTag,
  ) async {
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: currentTag ?? '');

    final String? newTag = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.wishlistTagRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.wishlistTagPlaceholder),
          onSubmitted: (String value) =>
              Navigator.of(context).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (newTag == null || newTag.isEmpty || newTag == currentTag) return null;
    return newTag;
  }

  /// Confirms deletion of a tag and the [itemCount] items under it.
  static Future<bool> confirmDeleteTag(
    BuildContext context,
    String? tag,
    int itemCount,
  ) async {
    final S l = S.of(context);
    final String label = tag ?? l.wishlistTagUntagged;
    return _confirm(
      context,
      title: l.wishlistTagDelete,
      message: l.wishlistTagDeleteConfirm(label, itemCount),
      confirmLabel: l.delete,
    );
  }

  /// Confirms clearing all resolved items.
  static Future<bool> confirmClearResolved(
    BuildContext context,
    int resolvedCount,
  ) async {
    final S l = S.of(context);
    return _confirm(
      context,
      title: l.wishlistClearResolvedTitle,
      message: l.wishlistClearResolvedMessage(resolvedCount),
      confirmLabel: l.clear,
    );
  }

  /// Confirms deletion of a single item.
  static Future<bool> confirmDeleteItem(
    BuildContext context,
    String itemText,
  ) async {
    final S l = S.of(context);
    return _confirm(
      context,
      title: l.wishlistDeleteItem,
      message: l.wishlistDeletePrompt(itemText),
      confirmLabel: l.delete,
    );
  }

  /// Confirms bulk deletion of [count] items.
  static Future<bool> confirmBulkDelete(
    BuildContext context,
    int count,
  ) async {
    final S l = S.of(context);
    return _confirm(
      context,
      title: l.wishlistBulkDelete,
      message: l.wishlistBulkDeleteConfirm(count),
      confirmLabel: l.delete,
    );
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
