import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/segmented_pill.dart';

enum _ImageSource {
  url,
  file,
}

/// Pops a map with a `url` key (URL mode) or `base64` + `mimeType`
/// (file mode); `null` on cancel.
class AddImageDialog extends StatefulWidget {
  const AddImageDialog({this.initialUrl, super.key});

  /// Initial URL (for editing).
  final String? initialUrl;

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
  Uint8List? _pickedBytes;
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
    // withData: the browser only ever hands out bytes, and the canvas stores
    // the image as base64 anyway.
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) return;

    final String base64String = base64Encode(bytes);

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
      _pickedBytes = bytes;
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
      title: Text(_isEditing ? l.editImageTitle : l.canvasAddImage),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            if (!_isEditing) ...<Widget>[
              SegmentedPill<_ImageSource>(
                options: <SegmentedPillOption<_ImageSource>>[
                  SegmentedPillOption<_ImageSource>(
                    value: _ImageSource.url,
                    label: l.imageFromUrl,
                    icon: Icons.link,
                  ),
                  SegmentedPillOption<_ImageSource>(
                    value: _ImageSource.file,
                    label: l.imageFromFile,
                    icon: Icons.folder_open,
                  ),
                ],
                selected: _source,
                onChanged: (_ImageSource s) => setState(() => _source = s),
              ),
              const SizedBox(height: 16),
            ],

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

            if (_source == _ImageSource.file) ...<Widget>[
              if (_fileName != null) ...<Widget>[
                Text(
                  _fileName!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (_pickedBytes != null)
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: Image.memory(
                        _pickedBytes!,
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
