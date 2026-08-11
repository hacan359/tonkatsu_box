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

/// Asks the user to pick a cover source (local file or URL) and returns
/// the result, or `null` when the user cancelled.
Future<CoverPickResult?> pickCustomCoverImage(
  BuildContext context, {
  required String currentUrl,
}) async {
  final S l = S.of(context);
  final String? choice = await showDialog<String>(
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
      ],
    ),
  );

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
    final TextEditingController urlCtrl =
        TextEditingController(text: currentUrl);
    try {
      final String? url = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l.customItemCoverUrl),
          content: TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(hintText: 'https://...'),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(urlCtrl.text.trim()),
              child: Text(l.confirm),
            ),
          ],
        ),
      );
      if (url == null || url.isEmpty) return null;
      return CoverPickResult.url(url);
    } finally {
      urlCtrl.dispose();
    }
  }

  return null;
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
