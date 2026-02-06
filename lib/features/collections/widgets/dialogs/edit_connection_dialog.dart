import 'package:flutter/material.dart';

import '../../../../shared/models/canvas_connection.dart';

// Диалог редактирования свойств связи на канвасе.

/// Доступные цвета для связей.
const List<_ColorOption> _colorOptions = <_ColorOption>[
  _ColorOption(label: 'Gray', hex: '#666666', color: Color(0xFF666666)),
  _ColorOption(label: 'Red', hex: '#E53935', color: Color(0xFFE53935)),
  _ColorOption(label: 'Orange', hex: '#FB8C00', color: Color(0xFFFB8C00)),
  _ColorOption(label: 'Yellow', hex: '#FDD835', color: Color(0xFFFDD835)),
  _ColorOption(label: 'Green', hex: '#43A047', color: Color(0xFF43A047)),
  _ColorOption(label: 'Blue', hex: '#1E88E5', color: Color(0xFF1E88E5)),
  _ColorOption(label: 'Purple', hex: '#8E24AA', color: Color(0xFF8E24AA)),
  _ColorOption(label: 'Black', hex: '#212121', color: Color(0xFF212121)),
];

class _ColorOption {
  const _ColorOption({
    required this.label,
    required this.hex,
    required this.color,
  });
  final String label;
  final String hex;
  final Color color;
}

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

    // Если цвет не совпадает ни с одним вариантом, берём по умолчанию
    if (!_colorOptions.any((_ColorOption o) => o.hex == _selectedColor)) {
      _selectedColor = '#666666';
    }
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
    return AlertDialog(
      title: const Text('Edit Connection'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. depends on, related to...',
              ),
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions
                  .map((_ColorOption option) => _ColorButton(
                        color: option.color,
                        isSelected: option.hex == _selectedColor,
                        tooltip: option.label,
                        onTap: () {
                          setState(() => _selectedColor = option.hex);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Style',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ConnectionStyle>(
              segments: const <ButtonSegment<ConnectionStyle>>[
                ButtonSegment<ConnectionStyle>(
                  value: ConnectionStyle.solid,
                  label: Text('Solid'),
                  icon: Icon(Icons.horizontal_rule, size: 18),
                ),
                ButtonSegment<ConnectionStyle>(
                  value: ConnectionStyle.dashed,
                  label: Text('Dashed'),
                  icon: Icon(Icons.more_horiz, size: 18),
                ),
                ButtonSegment<ConnectionStyle>(
                  value: ConnectionStyle.arrow,
                  label: Text('Arrow'),
                  icon: Icon(Icons.arrow_forward, size: 18),
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
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Кнопка выбора цвета.
class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.tooltip,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: _contrastColor(color),
                )
              : null,
        ),
      ),
    );
  }

  /// Возвращает контрастный цвет (белый или чёрный) для читаемости.
  static Color _contrastColor(Color color) {
    final double luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
