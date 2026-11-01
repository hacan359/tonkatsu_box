import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../content/simkl_import_content.dart';
import '../widgets/remembered_import_collection.dart';

class SimklImportScreen extends StatelessWidget {
  const SimklImportScreen({this.initialCollectionId, super.key});

  /// Preselects "existing collection" when opened from a collection.
  final int? initialCollectionId;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: S.of(context).simklImportTitle),
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
                  source: ImportSourceKind.simkl,
                  initialCollectionId: initialCollectionId,
                  builder: (int? collectionId) =>
                      SimklImportContent(initialCollectionId: collectionId),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
