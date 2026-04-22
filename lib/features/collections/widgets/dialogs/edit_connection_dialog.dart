import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/canvas_connection.dart';
import '../../../../shared/widgets/color_picker_dialog.dart';

// Диалог редактирования свойств связи на канвасе.

/// Диалог для редактирования label, цвета и стиля связи.
///
/// Возвращает `Map<String, dynamic>` с ключами `label`, `color`, `style`,
/// или `null` если пользователь отменил.
class EditConnectionDialog extends StatefulWidget {
  /// Создаёт [EditConnectionDialog].
  const EditConnectionDialog({
    this.initialLabel,
    this.initialColor,
    this.initialStyle,
    super.key,
  });

  /// Начальный лейбл.
  final String? initialLabel;

  /// Начальный цвет (hex).
  final String? initialColor;

  /// Начальный стиль.
  final ConnectionStyle? initialStyle;

  /// Показывает диалог и возвращает результат.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialLabel,
    String? initialColor,
    ConnectionStyle? initialStyle,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return EditConnectionDialog(
          initialLabel: initialLabel,
          initialColor: initialColor,
          initialStyle: initialStyle,
        );
      },
    );
  }

  @override
  State<EditConnectionDialog> createState() => _EditConnectionDialogState();
}

class _EditConnectionDialogState extends State<EditConnectionDialog> {
  late final TextEditingController _labelController;
  late String _selectedColor;
  late ConnectionStyle _selectedStyle;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initialLabel ?? '',
    );
    _selectedColor = widget.initialColor ?? '#666666';
    _selectedStyle = widget.initialStyle ?? ConnectionStyle.solid;
  }

  Color get _selectedColorValue {
    final String cleaned = _selectedColor.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  String _colorToHex(Color color) {
    final int rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _submit() {
    final String label = _labelController.text.trim();

    Navigator.of(context).pop(<String, dynamic>{
      'label': label.isEmpty ? null : label,
      'color': _selectedColor,
      'style': _selectedStyle.value,
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.editConnectionTitle),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l.linkLabelOptional,
                border: const OutlineInputBorder(),
                hintText: l.connectionLabelHint,
              ),
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(
              l.colorPickerTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final Color? picked = await ColorPickerDialog.show(
                  context: context,
                  currentColor: _selectedColorValue,
                );
                if (picked == null) return;
                setState(() => _selectedColor = _colorToHex(picked));
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _selectedColorValue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedColor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.connectionStyleLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ConnectionStyle>(
              segments: <ButtonSegment<ConnectionStyle>>[
                ButtonSegment<ConnectionStyle>(
                  value: ConnectionStyle.solid,
                  label: Text(l.connectionStyleSolid),
                  icon: const Icon(Icons.horizontal_rule, size: 18),
                ),
                ButtonSegment<ConnectionStyle>(
                  value: ConnectionStyle.dashed,
                  label: Text(l.connectionStyleDashed),
                  icon: const Icon(Icons.more_horiz, size: 18),
                ),
                ButtonSegment<ConnectionStyle>(
                  value: ConnectionStyle.arrow,
                  label: Text(l.connectionStyleArrow),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                ),
              ],
              selected: <ConnectionStyle>{_selectedStyle},
              onSelectionChanged: (Set<ConnectionStyle> selection) {
                setState(() => _selectedStyle = selection.first);
              },
            ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l.save),
        ),
      ],
    );
  }
}
