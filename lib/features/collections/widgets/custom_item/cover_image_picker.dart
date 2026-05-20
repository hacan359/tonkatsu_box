import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/custom_media.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Result of [pickCustomCoverImage]. Either a local file path or a URL —
/// never both, since picking one path clears the other.
class CoverPickResult {
  const CoverPickResult.file(this.localPath) : url = null;
  const CoverPickResult.url(this.url) : localPath = null;

  final String? localPath;
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
            title: Text(l.customItemCoverFromUrl),
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
    );
    if (result == null || result.files.isEmpty) return null;
    final String? path = result.files.first.path;
    if (path == null) return null;
    return CoverPickResult.file(path);
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
/// freshly picked local file → cached file from previous edit → URL.
class CustomCoverPreview extends StatelessWidget {
  const CustomCoverPreview({
    required this.localPath,
    required this.cachedPath,
    required this.url,
    required this.onTap,
    super.key,
  });

  final String? localPath;
  final String? cachedPath;
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
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, Object e, StackTrace? s) =>
            _CoverPlaceholder(),
      );
    }
    if (cachedPath != null) {
      return Image.file(
        File(cachedPath!),
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
        const Icon(
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
