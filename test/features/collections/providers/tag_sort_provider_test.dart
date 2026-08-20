import 'package:core/models/tag_sort_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/collections/providers/tag_sort_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/profile_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('TagSortModeNotifier', () {
    test('should default to manual when nothing is persisted', () async {
      final ProviderContainer container = await makeContainer();
      expect(container.read(tagSortModeProvider), TagSortMode.manual);
    });

    test('should restore the persisted mode for the current profile',
        () async {
      final ProviderContainer container = await makeContainer();
      final String profileId = container.read(currentProfileProvider).id;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tag_sort_mode_$profileId': TagSortMode.alphaDesc.value,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer restored = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(restored.dispose);

      expect(restored.read(tagSortModeProvider), TagSortMode.alphaDesc);
    });

    test('should update state and persist under the profile-suffixed key',
        () async {
      final ProviderContainer container = await makeContainer();
      final String profileId = container.read(currentProfileProvider).id;

      container
          .read(tagSortModeProvider.notifier)
          .setMode(TagSortMode.alphaAsc);

      expect(container.read(tagSortModeProvider), TagSortMode.alphaAsc);
      final SharedPreferences prefs =
          container.read(sharedPreferencesProvider);
      expect(
        prefs.getString('tag_sort_mode_$profileId'),
        TagSortMode.alphaAsc.value,
      );
    });

    test('should fall back to manual on a corrupt stored value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer probe = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      final String profileId = probe.read(currentProfileProvider).id;
      probe.dispose();

      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{'tag_sort_mode_$profileId': 'bogus'},
      );
      expect(container.read(tagSortModeProvider), TagSortMode.manual);
    });
  });
}
