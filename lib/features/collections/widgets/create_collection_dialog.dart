import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

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
    return AlertDialog(
      title: const Text('New Collection'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  hintText: 'e.g., SNES Classics',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Your name or username',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an author name';
                  }
                  return null;
                },
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
          onPressed: _submit,
          child: const Text('Create'),
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
    return AlertDialog(
      title: const Text('Rename Collection'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            labelText: 'Collection Name',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Rename'),
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
    return AlertDialog(
      title: const Text('Delete Collection?'),
      content: RichText(
        text: TextSpan(
          style: AppTypography.body,
          children: <TextSpan>[
            const TextSpan(text: 'Are you sure you want to delete '),
            TextSpan(
              text: collectionName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: '?\n\nThis action cannot be undone.',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
