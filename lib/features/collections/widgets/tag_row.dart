import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/color_picker_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/global_tags_provider.dart';

/// One editable tag row shared by both tag dialogs: tappable color dots,
/// name with usage count, rename, delete. [leading] hosts drag or checkbox.
class TagRow extends StatelessWidget {
  const TagRow({
    required this.tag,
    required this.usageCount,
    required this.onColorTap,
    required this.onTextColorTap,
    required this.onRename,
    required this.onDelete,
    this.leading,
    this.onTap,
    super.key,
  });

  final Tag tag;
  final int usageCount;
  final VoidCallback onColorTap;
  final VoidCallback onTextColorTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: AppSpacing.xs),
          ],
          TagColorDot(
            color: tag.color != null ? Color(tag.color!) : null,
            size: 20,
            onTap: onColorTap,
          ),
          const SizedBox(width: AppSpacing.xs),
          TagColorDot(
            color: tag.textColor != null ? Color(tag.textColor!) : null,
            size: 20,
            icon: Icons.text_fields,
            onTap: onTextColorTap,
            tooltip: l.tagTextColor,
          ),
        ],
      ),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              tag.name,
              style: tag.textColor != null
                  ? TextStyle(color: Color(tag.textColor!))
                  : null,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (usageCount > 0) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '· $usageCount',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onRename,
            tooltip: l.tagRename,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            tooltip: l.tagDelete,
          ),
        ],
      ),
    );
  }
}

/// Edit flows both dialogs launch from a [TagRow]; all persist immediately
/// through [globalTagsProvider] — a dialog's Cancel does not undo them.
abstract final class TagEditActions {
  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _RenameTagDialog(initialName: tag.name),
    );
    if (newName == null || newName.isEmpty || newName == tag.name) return;
    await ref.read(globalTagsProvider.notifier).rename(tag.id, newName);
  }

  static Future<void> changeColor(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) {
    return _applyPickedColor(
      context,
      current: tag.color,
      apply: (int? value) =>
          ref.read(globalTagsProvider.notifier).updateColor(tag.id, value),
    );
  }

  static Future<void> changeTextColor(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) {
    return _applyPickedColor(
      context,
      current: tag.textColor,
      apply: (int? value) =>
          ref.read(globalTagsProvider.notifier).updateTextColor(tag.id, value),
    );
  }

  static Future<void> _applyPickedColor(
    BuildContext context, {
    required int? current,
    required Future<void> Function(int? value) apply,
  }) async {
    final Color? picked = await ColorPickerDialog.show(
      context: context,
      currentColor: current != null ? Color(current) : null,
      allowNoColor: true,
    );
    if (picked == null) return;
    await apply(ColorPickerDialog.storedValue(picked));
  }

  /// Returns true when the user confirmed and the tag is gone.
  static Future<bool> delete(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final S l = S.of(context);
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: l.tagDelete,
      message: l.tagDeleteConfirm(tag.name),
      confirmLabel: l.delete,
    );
    if (!confirmed) return false;
    await ref.read(globalTagsProvider.notifier).delete(tag.id);
    return true;
  }
}

/// Owns its controller so it dies with the dialog's State — disposing right
/// after `showDialog` returns races the closing route's focus teardown.
class _RenameTagDialog extends StatefulWidget {
  const _RenameTagDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameTagDialog> createState() => _RenameTagDialogState();
}

class _RenameTagDialogState extends State<_RenameTagDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      title: Text(l.tagRename),
      content: TextField(
        controller: _controller,
        // Mobile: no autofocus so the keyboard waits for a tap on the field.
        autofocus: !kIsMobile,
        decoration: const InputDecoration(isDense: true),
        onSubmitted: (String value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: <Widget>[
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

class TagColorDot extends StatelessWidget {
  const TagColorDot({
    required this.color,
    required this.size,
    this.icon,
    this.onTap,
    this.tooltip,
    super.key,
  });

  final Color? color;
  final double size;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget dot = GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: color != null
                  ? color!.withAlpha(180)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: color == null
              ? Icon(
                  icon ?? Icons.palette_outlined,
                  size: size * 0.6,
                  color: AppColors.textTertiary,
                )
              : (icon != null
                  ? Icon(icon, size: size * 0.6, color: AppColors.onOverlay)
                  : null),
        ),
      ),
    );
    final String? message = tooltip;
    if (message == null) return dot;
    return Tooltip(message: message, child: dot);
  }
}
