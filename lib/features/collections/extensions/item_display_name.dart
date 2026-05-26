import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_item.dart';
import '../../settings/providers/settings_provider.dart';

/// Resolves the user-facing name for a [CollectionItem], honouring the
/// AniList title-language setting and the manual rename override.
///
/// Use [displayNameOf] inside `build` to subscribe to language changes,
/// and [currentDisplayNameOf] in event handlers / async callbacks for a
/// one-shot snapshot.
extension CollectionItemDisplay on WidgetRef {
  String displayNameOf(CollectionItem item) {
    final String lang = watch(
      settingsNotifierProvider.select((SettingsState s) => s.animeMangaTitleLanguage),
    );
    return item.displayName(lang);
  }

  String currentDisplayNameOf(CollectionItem item) {
    final String lang = read(settingsNotifierProvider).animeMangaTitleLanguage;
    return item.displayName(lang);
  }
}
