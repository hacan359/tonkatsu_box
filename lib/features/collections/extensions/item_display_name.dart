import 'package:core/models/collection_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';

/// [displayNameOf] subscribes to title-language changes inside `build`;
/// [currentDisplayNameOf] is a one-shot read for event handlers.
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
