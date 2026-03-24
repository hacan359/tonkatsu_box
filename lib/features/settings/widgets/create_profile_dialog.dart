// Диалог создания профиля.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

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
            Text(l.profileColor, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ProfileColors.values.map((String hex) {
                final Color color = Profile.hexToColor(hex);
                final bool isSelected = hex == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.textPrimary,
                              width: 2.5,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
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
