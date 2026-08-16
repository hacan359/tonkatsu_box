import 'package:core/models/item_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
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

  Future<String> currentProfileId() async {
    final ProviderContainer probe = await makeContainer();
    final String id = probe.read(currentProfileProvider).id;
    return id;
  }

  group('HomeStatusFilterNotifier', () {
    test('should default to no filter when nothing is persisted', () async {
      final ProviderContainer container = await makeContainer();

      expect(container.read(homeStatusFilterProvider), isEmpty);
    });

    test('should restore every persisted status for the current profile',
        () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filters_$profileId': <String>[
            ItemStatus.inProgress.value,
            ItemStatus.ignored.value,
          ],
        },
      );

      expect(container.read(homeStatusFilterProvider), <ItemStatus>{
        ItemStatus.inProgress,
        ItemStatus.ignored,
      });
    });

    test('should drop a stored value that no longer maps to a status',
        () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filters_$profileId': <String>[
            'on_hold',
            ItemStatus.completed.value,
          ],
        },
      );

      expect(
        container.read(homeStatusFilterProvider),
        <ItemStatus>{ItemStatus.completed},
      );
    });

    test('should keep an empty selection instead of falling back to the '
        'legacy key', () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filters_$profileId': <String>[],
          'home_status_filter_$profileId': ItemStatus.dropped.value,
        },
      );

      expect(container.read(homeStatusFilterProvider), isEmpty);
    });

    test('should migrate the single status stored by the older build',
        () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filter_$profileId': ItemStatus.planned.value,
        },
      );

      expect(
        container.read(homeStatusFilterProvider),
        <ItemStatus>{ItemStatus.planned},
      );
    });

    test('should treat the legacy "all" sentinel as no filter', () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filter_$profileId': 'all',
        },
      );

      expect(container.read(homeStatusFilterProvider), isEmpty);
    });

    test('should ignore an unparsable legacy value', () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filter_$profileId': 'on_hold',
        },
      );

      expect(container.read(homeStatusFilterProvider), isEmpty);
    });

    test('should persist the selection under the profile-suffixed key',
        () async {
      final ProviderContainer container = await makeContainer();
      final String profileId = container.read(currentProfileProvider).id;

      container.read(homeStatusFilterProvider.notifier).setFilter(
        <ItemStatus>{ItemStatus.completed, ItemStatus.ignored},
      );

      expect(container.read(homeStatusFilterProvider), <ItemStatus>{
        ItemStatus.completed,
        ItemStatus.ignored,
      });
      final SharedPreferences prefs =
          container.read(sharedPreferencesProvider);
      expect(
        prefs.getStringList('home_status_filters_$profileId'),
        <String>[ItemStatus.completed.value, ItemStatus.ignored.value],
      );
    });

    test('should persist an empty list when the filter is cleared', () async {
      final String profileId = await currentProfileId();
      final ProviderContainer container = await makeContainer(
        initialPrefs: <String, Object>{
          'home_status_filters_$profileId': <String>[ItemStatus.dropped.value],
        },
      );

      container
          .read(homeStatusFilterProvider.notifier)
          .setFilter(const <ItemStatus>{});

      expect(container.read(homeStatusFilterProvider), isEmpty);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getStringList('home_status_filters_$profileId'),
        isEmpty,
      );
    });
  });
}
