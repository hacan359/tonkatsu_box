import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/frame_page.dart';
import '../content/browse_collections_content.dart';

class BrowseCollectionsScreen extends StatelessWidget {
  const BrowseCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FramePage(
      title: S.of(context).settingsBrowseCollections,
      child: const BrowseCollectionsContent(),
    );
  }
}
