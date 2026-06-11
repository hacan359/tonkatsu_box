import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/profile.dart';

/// Initialized in main() via overrideWithValue and re-initialized whenever
/// a profile is created or deleted.
final StateProvider<ProfilesData> profilesDataProvider =
    StateProvider<ProfilesData>((Ref ref) {
  // Fallback only; main() overrides this.
  return ProfilesData.defaultData();
});

final Provider<Profile> currentProfileProvider =
    Provider<Profile>((Ref ref) {
  final ProfilesData data = ref.watch(profilesDataProvider);
  return data.currentProfile;
});
