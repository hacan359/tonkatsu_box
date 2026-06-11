// Standalone provider so widgets (CollectionCard etc.) can read the setting
// without instantiating the full `SettingsNotifier`, which needs a whole pile
// of overrides in unit tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';

/// In unit tests where `settingsNotifierProvider` is not initialized the
/// value safely falls back to `false`, so widgets render the plain mosaic.
final Provider<bool> richCollectionsEnabledProvider = Provider<bool>(
  (Ref ref) {
    try {
      return ref.watch(
        settingsNotifierProvider.select(
          (SettingsState s) => s.richCollectionsEnabled,
        ),
      );
    } on Object {
      return false;
    }
  },
);
