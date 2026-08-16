import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/rich_hero_style.dart';

/// Standalone so widgets can read the flag without the full SettingsNotifier;
/// when it's uninitialized (unit tests) the value falls back to `false`.
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

/// Same test-safe fallback as above: no settings in scope → classic style.
final Provider<RichHeroStyle> richHeroStyleProvider = Provider<RichHeroStyle>(
  (Ref ref) {
    try {
      return ref.watch(
        settingsNotifierProvider.select(
          (SettingsState s) => s.richHeroStyle,
        ),
      );
    } on Object {
      return RichHeroStyle.classic;
    }
  },
);
