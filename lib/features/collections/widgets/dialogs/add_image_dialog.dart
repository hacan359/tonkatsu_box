import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

// Диалог добавления изображения на канвас.
//
// Поддерживает два режима: URL и локальный файл (base64).

/// Способ добавления изображения.
enum _ImageSource {
  url,
  file,
}

/// Диалог для добавления изображения на канвас.
///
/// Возвращает `Map<String, dynamic>` с ключом `url` (для URL)
/// или `base64` + `mimeType` (для файла), или `null` при отмене.
class AddImageDialog extends StatefulWidget {
  /// Создаёт [AddImageDialog].
  const AddImageDialog({this.initialUrl, super.key});

  /// Начальный URL (для редактирования).
  final String? initialUrl;

  /// Показывает диалог и возвращает результат.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialUrl,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AddImageDialog(initialUrl: initialUrl);
      },
    );
  }

  @override
  State<AddImageDialog> createState() => _AddImageDialogState();
}

class _AddImageDialogState extends State<AddImageDialog> {
  late final TextEditingController _urlController;
  _ImageSource _source = _ImageSource.url;
  String? _filePath;
  String? _fileName;
  String? _base64Data;
  String? _mimeType;

  bool get _isEditing => widget.initialUrl != null;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    switch (_source) {
      case _ImageSource.url:
        final String url = _urlController.text.trim();
        return url.startsWith('http://') || url.startsWith('https://');
      case _ImageSource.file:
        return _base64Data != null;
    }
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    if (file.path == null) return;

    final File ioFile = File(file.path!);
    final List<int> bytes = await ioFile.readAsBytes();
    final String base64String = base64Encode(bytes);

    // Определяем MIME-тип по расширению
    final String ext = file.extension?.toLowerCase() ?? '';
    final String mimeType = switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'image/png',
    };

    setState(() {
      _filePath = file.path;
      _fileName = file.name;
      _base64Data = base64String;
      _mimeType = mimeType;
    });
  }

  void _submit() {
    if (!_canSubmit) return;

    switch (_source) {
      case _ImageSource.url:
        Navigator.of(context).pop(<String, dynamic>{
          'url': _urlController.text.trim(),
        });
      case _ImageSource.file:
        Navigator.of(context).pop(<String, dynamic>{
          'base64': _base64Data,
          'mimeType': _mimeType,
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S l = S.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? l.editImageTitle : l.addImageTitle),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            // Выбор источника
            if (!_isEditing) ...<Widget>[
              SegmentedButton<_ImageSource>(
                segments: <ButtonSegment<_ImageSource>>[
                  ButtonSegment<_ImageSource>(
                    value: _ImageSource.url,
                    label: Text(l.imageFromUrl),
                    icon: const Icon(Icons.link),
                  ),
                  ButtonSegment<_ImageSource>(
                    value: _ImageSource.file,
                    label: Text(l.imageFromFile),
                    icon: const Icon(Icons.folder_open),
                  ),
                ],
                selected: <_ImageSource>{_source},
                onSelectionChanged: (Set<_ImageSource> selected) {
                  setState(() => _source = selected.first);
                },
              ),
              const SizedBox(height: 16),
            ],

            // URL ввод
            if (_source == _ImageSource.url) ...<Widget>[
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l.imageUrlLabel,
                  hintText: l.imageUrlHint,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              // Превью
              if (_urlController.text.trim().startsWith('http'))
                SizedBox(
                  height: 150,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: _urlController.text.trim(),
                      fit: BoxFit.contain,
                      placeholder: (BuildContext context, String url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (BuildContext context, String url,
                              Object error) =>
                          Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
            ],

            // Файл
            if (_source == _ImageSource.file) ...<Widget>[
              if (_fileName != null) ...<Widget>[
                Text(
                  _fileName!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (_filePath != null)
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: Image.file(
                        File(_filePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (BuildContext context, Object error,
                                StackTrace? stackTrace) =>
                            Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_fileName != null ? l.imageChooseAnother : l.imageChooseFile),
              ),
            ],
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
          onPressed: _canSubmit ? _submit : null,
          child: Text(_isEditing ? l.save : l.add),
        ),
      ],
    );
  }
}
