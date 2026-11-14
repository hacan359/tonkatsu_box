import 'package:core/models/import_source_kind.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/frame_page.dart';
import '../content/custom_cards_import_content.dart';
import '../widgets/remembered_import_collection.dart';

/// Thin [Scaffold]/title-bar wrapper around [CustomCardsImportContent].
class CustomCardsImportScreen extends StatelessWidget {
  const CustomCardsImportScreen({this.initialCollectionId, super.key});

  /// Preselects "existing collection" when opened from a collection.
  final int? initialCollectionId;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return FramePage(
      title: S.of(context).settingsCustomCardsImport,
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
                  source: ImportSourceKind.customCards,
                  initialCollectionId: initialCollectionId,
                  builder: (int? collectionId) => CustomCardsImportContent(
                    initialCollectionId: collectionId,
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
