import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/providers/profile_provider.dart';
import 'package:xerabora/shared/models/profile.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('profilesDataProvider', () {
    test('should return default data when not overridden', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProfilesData data = container.read(profilesDataProvider);

      expect(data.version, 1);
      expect(data.currentProfileId, 'default');
      expect(data.profiles.length, 1);
    });

    test('should return overridden value', () {
      final ProfilesData custom = createTestProfilesData(
        currentProfileId: 'custom',
        profiles: <Profile>[
          createTestProfile(id: 'custom', name: 'Custom'),
        ],
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profilesDataProvider.overrideWith((Ref ref) => custom),
        ],
      );
      addTearDown(container.dispose);

      final ProfilesData data = container.read(profilesDataProvider);
      expect(data.currentProfileId, 'custom');
      expect(data.profiles.first.name, 'Custom');
    });

    test('should allow state mutation via notifier', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProfilesData updated = createTestProfilesData(
        currentProfileId: 'new',
        profiles: <Profile>[
          createTestProfile(id: 'new', name: 'New Profile'),
        ],
      );
      container.read(profilesDataProvider.notifier).state = updated;

      final ProfilesData result = container.read(profilesDataProvider);
      expect(result.currentProfileId, 'new');
    });
  });

  group('currentProfileProvider', () {
    test('should return current profile from profilesData', () {
      final ProfilesData data = createTestProfilesData(
        currentProfileId: 'p2',
        profiles: <Profile>[
          createTestProfile(id: 'p1', name: 'First'),
          createTestProfile(id: 'p2', name: 'Second'),
        ],
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profilesDataProvider.overrideWith((Ref ref) => data),
        ],
      );
      addTearDown(container.dispose);

      final Profile current = container.read(currentProfileProvider);
      expect(current.id, 'p2');
      expect(current.name, 'Second');
    });

    test('should update when profilesData changes', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profilesDataProvider.overrideWith(
            (Ref ref) => createTestProfilesData(
              currentProfileId: 'a',
              profiles: <Profile>[
                createTestProfile(id: 'a', name: 'A'),
                createTestProfile(id: 'b', name: 'B'),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentProfileProvider).name, 'A');

      // Update state
      container.read(profilesDataProvider.notifier).state =
          createTestProfilesData(
        currentProfileId: 'b',
        profiles: <Profile>[
          createTestProfile(id: 'a', name: 'A'),
          createTestProfile(id: 'b', name: 'B'),
        ],
      );

      expect(container.read(currentProfileProvider).name, 'B');
    });
  });
}
