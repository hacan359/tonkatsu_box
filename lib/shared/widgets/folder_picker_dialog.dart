import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../l10n/app_localizations.dart';
import '../extensions/snackbar_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A browsable picker root: a storage volume or any fixed directory.
class FolderPickerRoot {
  /// Creates a [FolderPickerRoot].
  const FolderPickerRoot({
    required this.path,
    required this.label,
    this.removable = false,
  });

  /// Root directory; navigation never goes above it.
  final String path;

  /// Human-readable name shown in the volume list.
  final String label;

  /// Removable volume (SD card, USB drive); affects only the list icon.
  final bool removable;
}

/// In-app folder browser over the real filesystem.
///
/// The system SAF picker returns content URIs whose conversion to a raw
/// path is firmware-dependent guesswork — some firmwares produce paths
/// that do not exist on disk. Browsing real directories sidesteps the
/// conversion entirely; use this wherever a raw writable path is
/// required on Android.
///
/// With a single root the dialog opens straight inside it; with several
/// (internal storage + SD/USB) it opens on a volume list, and `..` from
/// a volume root leads back to that list.
class FolderPickerDialog extends StatefulWidget {
  /// Creates a [FolderPickerDialog].
  const FolderPickerDialog({
    required this.roots,
    required this.title,
    super.key,
  }) : assert(roots.length > 0, 'at least one root is required');

  /// Browsable roots; navigation never goes above them.
  final List<FolderPickerRoot> roots;

  /// Dialog title.
  final String title;

  /// Shows the picker; resolves to the chosen directory or `null` on cancel.
  static Future<String?> show(
    BuildContext context, {
    required List<FolderPickerRoot> roots,
    required String title,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          FolderPickerDialog(roots: roots, title: title),
    );
  }

  @override
  State<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  /// Current directory; `null` means the volume list screen.
  String? _currentPath;
  List<String> _subDirs = <String>[];
  bool _readError = false;

  @override
  void initState() {
    super.initState();
    if (widget.roots.length == 1) {
      _enter(widget.roots.first.path);
    }
  }

  bool get _atVolumeList => _currentPath == null;

  bool get _atRoot {
    final String? current = _currentPath;
    if (current == null) return false;
    return widget.roots
        .any((FolderPickerRoot root) => p.equals(root.path, current));
  }

  // Sync IO keeps the state machine trivial; a single directory listing
  // is fast even on slow flash storage.
  void _loadEntries() {
    final String? current = _currentPath;
    if (current == null) return;
    try {
      final List<String> dirs = Directory(current)
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => d.path)
          .where((String path) => !p.basename(path).startsWith('.'))
          .toList()
        ..sort(
          (String a, String b) => p
              .basename(a)
              .toLowerCase()
              .compareTo(p.basename(b).toLowerCase()),
        );
      setState(() {
        _subDirs = dirs;
        _readError = false;
      });
    } on FileSystemException {
      setState(() {
        _subDirs = <String>[];
        _readError = true;
      });
    }
  }

  void _enter(String path) {
    _currentPath = path;
    _loadEntries();
  }

  void _up() {
    final String? current = _currentPath;
    if (current == null) return;
    if (_atRoot) {
      if (widget.roots.length > 1) {
        setState(() {
          _currentPath = null;
          _subDirs = <String>[];
          _readError = false;
        });
      }
      return;
    }
    _currentPath = p.dirname(current);
    _loadEntries();
  }

  Future<void> _createFolder() async {
    final String? current = _currentPath;
    if (current == null) return;
    final String? name = await _FolderNameDialog.show(context);
    if (name == null) return;
    try {
      final Directory dir = Directory(p.join(current, name));
      dir.createSync();
      _enter(dir.path);
    } on FileSystemException {
      if (!mounted) return;
      context.showSnack(
        S.of(context).folderPickerCreateError,
        type: SnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);
    final double listHeight =
        (MediaQuery.of(context).size.height * 0.45).clamp(200.0, 400.0);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: listHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _currentPath ?? l10n.folderPickerVolumeList,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildList(l10n)),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('folder-picker-new'),
          onPressed: _atVolumeList ? null : _createFolder,
          child: Text(l10n.folderPickerNewFolder),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('folder-picker-select'),
          onPressed: _atVolumeList
              ? null
              : () => Navigator.of(context).pop(_currentPath),
          child: Text(l10n.folderPickerSelect),
        ),
      ],
    );
  }

  /// Whether the ".." entry is shown: anywhere below a root, or at a
  /// root when there is a volume list to go back to.
  bool get _showUpTile =>
      !_atVolumeList && (!_atRoot || widget.roots.length > 1);

  Widget _buildList(S l10n) {
    if (_atVolumeList) {
      return ListView.builder(
        itemCount: widget.roots.length,
        itemBuilder: (BuildContext context, int index) {
          final FolderPickerRoot root = widget.roots[index];
          return ListTile(
            dense: true,
            leading: Icon(
              root.removable
                  ? Icons.sd_card_outlined
                  : Icons.smartphone_outlined,
              size: 20,
            ),
            title: Text(root.label),
            onTap: () => _enter(root.path),
          );
        },
      );
    }

    final int upSlot = _showUpTile ? 1 : 0;

    if (_readError) {
      return _withUpEntry(
        Center(
          child: Text(
            l10n.folderPickerReadError,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      );
    }
    if (_subDirs.isEmpty) {
      return _withUpEntry(
        Center(
          child: Text(
            l10n.folderPickerEmpty,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _subDirs.length + upSlot,
      itemBuilder: (BuildContext context, int index) {
        if (upSlot == 1 && index == 0) return _upTile();
        final String path = _subDirs[index - upSlot];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.folder_outlined, size: 20),
          title: Text(p.basename(path)),
          onTap: () => _enter(path),
        );
      },
    );
  }

  /// Keeps the ".." entry visible above empty/error states so the user
  /// can always navigate back out of an unreadable folder.
  Widget _withUpEntry(Widget body) {
    if (!_showUpTile) return body;
    return Column(
      children: <Widget>[
        _upTile(),
        Expanded(child: body),
      ],
    );
  }

  Widget _upTile() {
    return ListTile(
      key: const ValueKey<String>('folder-picker-up'),
      dense: true,
      leading: const Icon(Icons.drive_folder_upload_outlined, size: 20),
      title: const Text('..'),
      onTap: _up,
    );
  }
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog();

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _FolderNameDialog(),
    );
  }

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  static final RegExp _forbiddenChars = RegExp(r'[\\/:*?"<>|]');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.folderPickerNewFolder),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          focusNode: _nameFocus,
          decoration: InputDecoration(
            labelText: l10n.folderPickerFolderName,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: (String? value) {
            final String name = value?.trim() ?? '';
            if (name.isEmpty || _forbiddenChars.hasMatch(name)) {
              return l10n.folderPickerInvalidName;
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('folder-picker-create-confirm'),
          onPressed: _submit,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
