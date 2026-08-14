import 'package:core/models/tag_sort_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';

const String _tagSortModeKey = 'tag_sort_mode';

/// Persisted display order of global tag lists — the tag dialogs and the
/// collection tag bar all follow the one preference.
final NotifierProvider<TagSortModeNotifier, TagSortMode> tagSortModeProvider =
    NotifierProvider<TagSortModeNotifier, TagSortMode>(
  TagSortModeNotifier.new,
);

/// Per-profile persistence: key `tag_sort_mode_{profileId}`.
class TagSortModeNotifier extends Notifier<TagSortMode> {
  String get _prefsKey {
    final String profileId = ref.read(currentProfileProvider).id;
    return '${_tagSortModeKey}_$profileId';
  }

  @override
  TagSortMode build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    final String? value = prefs.getString(_prefsKey);
    if (value == null) return TagSortMode.manual;
    return TagSortMode.fromString(value);
  }

  void setMode(TagSortMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_prefsKey, mode.value);
  }
}
