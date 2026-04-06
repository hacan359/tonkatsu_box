// Экран каталога онлайн-коллекций.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../content/browse_collections_content.dart';

/// Экран каталога онлайн-коллекций.
///
/// Тонкая обёртка вокруг [BrowseCollectionsContent] с Scaffold/AppBar.
class BrowseCollectionsScreen extends StatelessWidget {
  /// Создаёт [BrowseCollectionsScreen].
  const BrowseCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenAppBar(
        title: S.of(context).settingsBrowseCollections,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => BrowseCollectionsContent.refresh(context),
          ),
        ],
      ),
      body: const BrowseCollectionsContent(),
    );
  }
}
