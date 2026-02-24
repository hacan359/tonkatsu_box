import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

/// Результат диалога создания коллекции.
class CreateCollectionResult {
  /// Создаёт [CreateCollectionResult].
  const CreateCollectionResult({
    required this.name,
    required this.author,
  });

  /// Название коллекции.
  final String name;

  /// Автор коллекции.
  final String author;
}

/// Диалог создания новой коллекции.
class CreateCollectionDialog extends StatefulWidget {
  /// Создаёт [CreateCollectionDialog].
  const CreateCollectionDialog({
    this.defaultAuthor,
    super.key,
  });

  /// Автор по умолчанию.
  final String? defaultAuthor;

  /// Показывает диалог и возвращает результат.
  static Future<CreateCollectionResult?> show(
    BuildContext context, {
    String? defaultAuthor,
  }) {
    return showDialog<CreateCollectionResult>(
      context: context,
      builder: (BuildContext context) => CreateCollectionDialog(
        defaultAuthor: defaultAuthor,
      ),
    );
  }

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.defaultAuthor != null) {
      _authorController.text = widget.defaultAuthor!;
    }
    // Автофокус на название
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(
        CreateCollectionResult(
          name: _nameController.text.trim(),
          author: _authorController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.createCollectionTitle),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: InputDecoration(
                labelText: l.createCollectionNameLabel,
                hintText: l.createCollectionNameHint,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return l.createCollectionEnterName;
                }
                if (value.trim().length < 2) {
                  return l.createCollectionNameTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: l.createCollectionAuthor,
                hintText: l.createCollectionAuthorHint,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return l.createCollectionEnterAuthor;
                }
                return null;
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
          onPressed: _submit,
          child: Text(l.create),
        ),
      ],
    );
  }
}

/// Диалог переименования коллекции.
class RenameCollectionDialog extends StatefulWidget {
  /// Создаёт [RenameCollectionDialog].
  const RenameCollectionDialog({
    required this.currentName,
    super.key,
  });

  /// Текущее название.
  final String currentName;

  /// Показывает диалог и возвращает новое название.
  static Future<String?> show(BuildContext context, String currentName) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => RenameCollectionDialog(
        currentName: currentName,
      ),
    );
  }

  @override
  State<RenameCollectionDialog> createState() => _RenameCollectionDialogState();
}

class _RenameCollectionDialogState extends State<RenameCollectionDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.renameCollectionTitle),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: l.createCollectionNameLabel,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return l.createCollectionEnterName;
            }
            if (value.trim().length < 2) {
              return l.createCollectionNameTooShort;
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l.rename),
        ),
      ],
    );
  }
}

/// Диалог подтверждения удаления.
class DeleteCollectionDialog extends StatelessWidget {
  /// Создаёт [DeleteCollectionDialog].
  const DeleteCollectionDialog({
    required this.collectionName,
    super.key,
  });

  /// Название коллекции.
  final String collectionName;

  /// Показывает диалог и возвращает true при подтверждении.
  static Future<bool> show(BuildContext context, String collectionName) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteCollectionDialog(
        collectionName: collectionName,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.deleteCollectionTitle),
      scrollable: true,
      content: Text(l.deleteCollectionMessage(collectionName)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(l.delete),
        ),
      ],
    );
  }
}
