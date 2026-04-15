// Экран каталога онлайн-коллекций.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../content/browse_collections_content.dart';

/// Экран каталога онлайн-коллекций.
///
/// Тонкая обёртка вокруг [BrowseCollectionsContent] с Scaffold/AppBar.
class BrowseCollectionsScreen extends StatelessWidget {
  /// Создаёт [BrowseCollectionsScreen].
  const BrowseCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: S.of(context).settingsBrowseCollections),
        const Expanded(child: BrowseCollectionsContent()),
      ],
    );
  }
}
