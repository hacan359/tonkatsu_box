// Диалог редактирования профиля.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/color_picker_dialog.dart';

/// Результат редактирования профиля.
sealed class EditProfileResult {
  /// Создаёт [EditProfileResult].
  const EditProfileResult();
}

/// Профиль обновлён.
class ProfileUpdated extends EditProfileResult {
  /// Создаёт [ProfileUpdated].
  const ProfileUpdated({required this.name, required this.color});

  /// Новое имя.
  final String name;

  /// Новый цвет.
  final String color;
}

/// Профиль удалён.
class ProfileDeleteRequested extends EditProfileResult {
  /// Создаёт [ProfileDeleteRequested].
  const ProfileDeleteRequested();
}

/// Диалог редактирования профиля.
class EditProfileDialog extends StatefulWidget {
  /// Создаёт [EditProfileDialog].
  const EditProfileDialog({
    required this.profile,
    required this.canDelete,
    super.key,
  });

  /// Редактируемый профиль.
  final Profile profile;

  /// Можно ли удалить (false для последнего профиля).
  final bool canDelete;

  /// Показывает диалог и возвращает результат.
  static Future<EditProfileResult?> show(
    BuildContext context, {
    required Profile profile,
    required bool canDelete,
  }) {
    return showDialog<EditProfileResult>(
      context: context,
      builder: (BuildContext context) => EditProfileDialog(
        profile: profile,
        canDelete: canDelete,
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedColor = widget.profile.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _confirmDelete() async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteProfile),
        content: Text(l.deleteProfileConfirm(widget.profile.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const ProfileDeleteRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l.editProfile),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Name
            Text(l.profileName, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l.profileName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Color
            Text(l.colorPickerTitle, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () async {
                final Color? picked = await ColorPickerDialog.show(
                  context: context,
                  currentColor: Profile.hexToColor(_selectedColor),
                );
                if (picked == null) return;
                setState(() => _selectedColor = Profile.colorToHex(picked));
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Profile.hexToColor(_selectedColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(40)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.colorPickerTitle,
                      style: AppTypography.body.copyWith(color: AppColors.brand),
                    ),
                  ],
                ),
              ),
            ),

            // Delete button
            if (widget.canDelete) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  label: Text(
                    l.deleteProfile,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(ProfileUpdated(
                  name: _nameController.text.trim(),
                  color: _selectedColor,
                ))
              : null,
          child: Text(l.save),
        ),
      ],
    );
  }

}
