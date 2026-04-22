// Диалог создания профиля.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/color_picker_dialog.dart';

/// Диалог создания нового профиля.
///
/// Возвращает `(String name, String color)` при создании или null при отмене.
class CreateProfileDialog extends StatefulWidget {
  /// Создаёт [CreateProfileDialog].
  const CreateProfileDialog({super.key});

  /// Показывает диалог и возвращает результат.
  static Future<({String name, String color})?> show(
    BuildContext context,
  ) {
    return showDialog<({String name, String color})>(
      context: context,
      builder: (BuildContext context) => const CreateProfileDialog(),
    );
  }

  @override
  State<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<CreateProfileDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = ProfileColors.values.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l.createProfile),
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
              autofocus: true,
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
            _ProfileColorPickerButton(
              color: Profile.hexToColor(_selectedColor),
              onTap: () async {
                final Color? picked = await ColorPickerDialog.show(
                  context: context,
                  currentColor: Profile.hexToColor(_selectedColor),
                );
                if (picked == null) return;
                setState(() => _selectedColor = Profile.colorToHex(picked));
              },
            ),
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
              ? () => Navigator.of(context).pop((
                  name: _nameController.text.trim(),
                  color: _selectedColor,
                ))
              : null,
          child: Text(l.create),
        ),
      ],
    );
  }
}

/// Круглая плашка цвета с надписью «Изменить» — открывает полный color picker.
class _ProfileColorPickerButton extends StatelessWidget {
  const _ProfileColorPickerButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              S.of(context).colorPickerTitle,
              style: AppTypography.body.copyWith(color: AppColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}
