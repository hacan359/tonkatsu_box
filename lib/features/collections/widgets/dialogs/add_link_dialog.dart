import 'package:flutter/material.dart';

// Диалог добавления/редактирования ссылки на канвасе.

/// Диалог для ввода URL и метки ссылки.
///
/// Возвращает `Map<String, dynamic>` с ключами `url` и `label`,
/// или `null` если пользователь отменил.
class AddLinkDialog extends StatefulWidget {
  /// Создаёт [AddLinkDialog].
  const AddLinkDialog({
    this.initialUrl,
    this.initialLabel,
    super.key,
  });

  /// Начальный URL (для редактирования).
  final String? initialUrl;

  /// Начальная метка (для редактирования).
  final String? initialLabel;

  /// Показывает диалог и возвращает результат.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialUrl,
    String? initialLabel,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AddLinkDialog(
          initialUrl: initialUrl,
          initialLabel: initialLabel,
        );
      },
    );
  }

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _labelController;
  bool get _isEditing => widget.initialUrl != null;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final String url = _urlController.text.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  void _submit() {
    if (!_canSubmit) return;

    final String url = _urlController.text.trim();
    final String label = _labelController.text.trim();

    Navigator.of(context).pop(<String, dynamic>{
      'url': url,
      'label': label.isNotEmpty ? label : url,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? 'Edit Link' : 'Add Link'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'My Link',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
