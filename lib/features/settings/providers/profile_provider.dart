// Провайдеры для профильной системы.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/profile.dart';

/// Провайдер данных всех профилей.
///
/// Инициализируется в main() через overrideWithValue.
/// Переинициализируется при создании/удалении профиля.
final StateProvider<ProfilesData> profilesDataProvider =
    StateProvider<ProfilesData>((Ref ref) {
  // Default — будет overridden из main()
  return ProfilesData.defaultData();
});

/// Текущий активный профиль.
final Provider<Profile> currentProfileProvider =
    Provider<Profile>((Ref ref) {
  final ProfilesData data = ref.watch(profilesDataProvider);
  return data.currentProfile;
});
