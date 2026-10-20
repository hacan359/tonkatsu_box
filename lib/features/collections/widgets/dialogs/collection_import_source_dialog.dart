import 'package:core/models/collection_import.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/import_source_kind_ui.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

sealed class CollectionImportChoice {
  const CollectionImportChoice();
}

final class CollectionImportFromFile extends CollectionImportChoice {
  const CollectionImportFromFile();
}

final class CollectionImportRerun extends CollectionImportChoice {
  const CollectionImportRerun(this.record);

  final CollectionImport record;
}

/// A `.xcoll` file first, then every source that already filled this
/// collection, newest run first.
class CollectionImportSourceDialog extends StatelessWidget {
  const CollectionImportSourceDialog({required this.saved, super.key});

  final List<CollectionImport> saved;

  static Future<CollectionImportChoice?> show(
    BuildContext context,
    List<CollectionImport> saved,
  ) => showDialog<CollectionImportChoice>(
    context: context,
    builder: (BuildContext _) => CollectionImportSourceDialog(saved: saved),
  );

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final MaterialLocalizations dates = MaterialLocalizations.of(context);
    return SimpleDialog(
      title: Text(l.collectionImportPickSource),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () =>
              Navigator.of(context).pop(const CollectionImportFromFile()),
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l.collectionImportFromFile),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        for (final CollectionImport record in saved)
          SimpleDialogOption(
            key: ValueKey<String>(record.source.key),
            onPressed: () =>
                Navigator.of(context).pop(CollectionImportRerun(record)),
            child: ListTile(
              leading: _SourceIcon(record: record),
              title: Text(record.source.localizedLabel(l)),
              subtitle: Text(
                l.collectionImportLastRun(
                  dates.formatMediumDate(record.lastRunAt),
                ),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.record});

  final CollectionImport record;

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    final String? asset = record.source.assetPath;
    if (asset == null) return Icon(record.source.fallbackIcon);
    return Image.asset(asset, width: _size, height: _size);
  }
}
