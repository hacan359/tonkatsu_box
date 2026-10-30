import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../content/igdb_list_import_content.dart';
import '../widgets/remembered_import_collection.dart';

/// Thin [Scaffold]/title-bar wrapper around [IgdbListImportContent].
class IgdbListImportScreen extends StatelessWidget {
  const IgdbListImportScreen({this.initialCollectionId, super.key});

  /// Preselects "existing collection" when opened from a collection.
  final int? initialCollectionId;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: S.of(context).settingsIgdbImport),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: RememberedImportCollection(
                  source: ImportSourceKind.igdbList,
                  initialCollectionId: initialCollectionId,
                  builder: (int? collectionId) =>
                      IgdbListImportContent(initialCollectionId: collectionId),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
