import 'dart:io';
import 'dart:typed_data';

import 'package:core/models/custom_media.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Result of [pickCustomCoverImage]. Either picked bytes or a URL — never
/// both, since picking one clears the other.
class CoverPickResult {
  const CoverPickResult.file(this.bytes) : url = null;
  const CoverPickResult.url(this.url) : bytes = null;

  /// Read at pick time — the browser never has a path to defer to.
  final Uint8List? bytes;
  final String? url;
}

/// An extra entry of [pickCustomCoverImage] next to "file" and "link", for a
/// provider that only some card types have.
class CoverPickSource {
  const CoverPickSource({
    required this.icon,
    required this.label,
    required this.pick,
  });

  final IconData icon;
  final String label;

  /// Opens the source's own chooser; `null` when the user backed out.
  final Future<CoverPickResult?> Function(BuildContext context) pick;
}

/// Asks the user to pick a cover source (local file, URL or one of
/// [extraSources]) and returns the result, or `null` when cancelled.
Future<CoverPickResult?> pickCustomCoverImage(
  BuildContext context, {
  required String currentUrl,
  List<CoverPickSource> extraSources = const <CoverPickSource>[],
}) async {
  final S l = S.of(context);
  final Object? choice = await showDialog<Object>(
    context: context,
    builder: (BuildContext ctx) => SimpleDialog(
      title: Text(l.customItemCoverSource),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l.customItemCoverRatio,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop('file'),
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l.customItemCoverFromFile),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop('url'),
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(l.imageFromUrl),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        for (final CoverPickSource source in extraSources)
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(source),
            child: ListTile(
              leading: Icon(source.icon),
              title: Text(source.label),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    ),
  );

  if (choice is CoverPickSource) {
    if (!context.mounted) return null;
    return choice.pick(context);
  }

  if (choice == 'file') {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final Uint8List? bytes = result.files.first.bytes;
    if (bytes == null) return null;
    return CoverPickResult.file(bytes);
  }

  if (choice == 'url') {
    if (!context.mounted) return null;
    final String? url = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _CoverUrlDialog(initialUrl: currentUrl),
    );
    if (url == null || url.isEmpty) return null;
    return CoverPickResult.url(url);
  }

  return null;
}

/// Owns its controller: disposing it once `showDialog` returns would pull it
/// out from under the closing animation, which still rebuilds the field.
class _CoverUrlDialog extends StatefulWidget {
  const _CoverUrlDialog({required this.initialUrl});

  final String initialUrl;

  @override
  State<_CoverUrlDialog> createState() => _CoverUrlDialogState();
}

class _CoverUrlDialogState extends State<_CoverUrlDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialUrl);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.customItemCoverUrl),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l.confirm),
        ),
      ],
    );
  }
}

/// Visual preview that picks the best available cover source in order:
/// freshly picked bytes → cached cover from a previous edit → URL.
class CustomCoverPreview extends StatelessWidget {
  const CustomCoverPreview({
    required this.bytes,
    required this.cachedUri,
    required this.url,
    required this.onTap,
    super.key,
  });

  final Uint8List? bytes;

  /// A `file:` path on desktop, the server's `/img` URL on web.
  final Uri? cachedUri;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: 100,
          height: 150,
          color: AppColors.surfaceLight,
          child: _buildPreview(context),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, Object e, StackTrace? s) =>
            _CoverPlaceholder(),
      );
    }
    final Uri? cached = cachedUri;
    if (cached != null) {
      // The File branch is unreachable on web, where cachedUri is always the
      // server's /img URL — dart:io's stub never gets touched.
      final ImageProvider provider = cached.isScheme('file')
          ? FileImage(File(cached.toFilePath()))
          : NetworkImage(cached.toString()) as ImageProvider;
      return Image(
        image: provider,
        fit: BoxFit.cover,
        errorBuilder: (_, Object e, StackTrace? s) =>
            _CoverPlaceholder(),
      );
    }
    if (url.isNotEmpty && !CustomMedia.isLocalCover(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, Object e, StackTrace? s) =>
            _CoverPlaceholder(),
      );
    }
    return _CoverPlaceholder();
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 4),
        Text(
          l.customItemAddCover,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
