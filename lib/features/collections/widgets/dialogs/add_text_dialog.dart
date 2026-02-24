import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

// Диалог добавления/редактирования текстового блока на канвасе.

/// Диалог для ввода текста и выбора размера шрифта.
///
/// Возвращает `Map<String, dynamic>` с ключами `content` и `fontSize`,
/// или `null` если пользователь отменил.
class AddTextDialog extends StatefulWidget {
  /// Создаёт [AddTextDialog].
  const AddTextDialog({
    this.initialContent,
    this.initialFontSize,
    super.key,
  });

  /// Начальный текст (для редактирования).
  final String? initialContent;

  /// Начальный размер шрифта (для редактирования).
  final double? initialFontSize;

  /// Показывает диалог и возвращает результат.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialContent,
    double? initialFontSize,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AddTextDialog(
          initialContent: initialContent,
          initialFontSize: initialFontSize,
        );
      },
    );
  }

  @override
  State<AddTextDialog> createState() => _AddTextDialogState();
}

/// Доступные размеры шрифта.
const List<_FontSizeOption> _fontSizeOptions = <_FontSizeOption>[
  _FontSizeOption(labelKey: 'small', size: 12),
  _FontSizeOption(labelKey: 'medium', size: 16),
  _FontSizeOption(labelKey: 'large', size: 24),
  _FontSizeOption(labelKey: 'title', size: 32),
];

class _FontSizeOption {
  const _FontSizeOption({required this.labelKey, required this.size});
  final String labelKey;
  final double size;

  /// Возвращает локализованную метку.
  String localizedLabel(S l) {
    switch (labelKey) {
      case 'small':
        return l.fontSizeSmall;
      case 'medium':
        return l.fontSizeMedium;
      case 'large':
        return l.fontSizeLarge;
      case 'title':
        return l.fontSizeTitle;
      default:
        return labelKey;
    }
  }
}

class _AddTextDialogState extends State<AddTextDialog> {
  late final TextEditingController _contentController;
  late double _selectedFontSize;
  bool get _isEditing => widget.initialContent != null;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
    _selectedFontSize = widget.initialFontSize ?? 16;
    // Если initialFontSize не совпадает ни с одним вариантом, берём ближайший
    if (!_fontSizeOptions.any(
      (_FontSizeOption o) => o.size == _selectedFontSize,
    )) {
      _selectedFontSize = 16;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final String content = _contentController.text.trim();
    if (content.isEmpty) return;

    Navigator.of(context).pop(<String, dynamic>{
      'content': content,
      'fontSize': _selectedFontSize,
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? l.editTextTitle : l.addTextTitle),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: l.textContentLabel,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                minLines: 2,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                initialValue: _selectedFontSize,
                decoration: InputDecoration(
                  labelText: l.fontSizeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _fontSizeOptions
                    .map(
                      (_FontSizeOption option) => DropdownMenuItem<double>(
                        value: option.size,
                        child:
                            Text('${option.localizedLabel(l)} (${option.size.toInt()}px)'),
                      ),
                    )
                    .toList(),
                onChanged: (double? value) {
                  if (value != null) {
                    setState(() => _selectedFontSize = value);
                  }
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
          child: Text(_isEditing ? l.save : l.add),
        ),
      ],
    );
  }
}
