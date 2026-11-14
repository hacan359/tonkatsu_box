import 'package:core/models/import_source_kind.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/frame_page.dart';
import '../content/kinorium_import_content.dart';
import '../widgets/remembered_import_collection.dart';

/// Thin wrapper around [KinoriumImportContent] with a title bar.
class KinoriumImportScreen extends StatelessWidget {
  const KinoriumImportScreen({this.initialCollectionId, super.key});

  /// Preselects "existing collection" when opened from a collection.
  final int? initialCollectionId;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return FramePage(
      title: S.of(context).settingsKinoriumImport,
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
                  source: ImportSourceKind.kinorium,
                  initialCollectionId: initialCollectionId,
                  builder: (int? collectionId) =>
                      KinoriumImportContent(initialCollectionId: collectionId),
                ),
              ),
            ),
          ),
    );
  }
}
