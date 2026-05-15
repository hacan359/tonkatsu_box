import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/screenscraper_api.dart';
import '../../../core/services/screenscraper_cache_service.dart';
import '../../../shared/constants/api_defaults.dart';
import '../../../shared/constants/screenscraper_systemes.dart';
import '../../settings/providers/settings_provider.dart';

/// Identifies a SS lookup by game name + IGDB platform id. The notifier
/// converts the IGDB id to SS `systemeid` itself.
typedef SsLookup = ({String gameName, int igdbPlatformId});

final AsyncNotifierProviderFamily<ScreenScraperGameNotifier, SsGame?, SsLookup>
    screenScraperGameProvider =
    AsyncNotifierProvider.family<ScreenScraperGameNotifier, SsGame?, SsLookup>(
  ScreenScraperGameNotifier.new,
);

class ScreenScraperGameNotifier extends FamilyAsyncNotifier<SsGame?, SsLookup> {
  @override
  Future<SsGame?> build(SsLookup arg) async {
    final int? systemeId =
        ScreenScraperSystemes.forIgdbPlatform(arg.igdbPlatformId);
    if (systemeId == null) return null;

    if (!ApiDefaults.hasScreenScraperDevCreds) return null;

    final SettingsState settings = ref.watch(settingsNotifierProvider);
    if (!settings.hasScreenScraperCreds) return null;

    final ScreenScraperCacheService cache =
        ref.read(screenScraperCacheServiceProvider);
    final String key = ScreenScraperCacheService.cacheKey(
      gameName: arg.gameName,
      systemeId: systemeId,
    );

    final SsGame? cached = await cache.read(key);
    if (cached != null) return cached;
    if (await cache.isNegativelyCached(key)) return null;

    final ScreenScraperApi api = ref.read(screenScraperApiProvider);
    api.setUserCredentials(
      ssid: settings.screenScraperSsid!,
      sspassword: settings.screenScraperSspassword!,
    );

    final SsGame? fetched = await api.searchGame(
      name: arg.gameName,
      systemeId: systemeId,
    );

    if (fetched == null) {
      await cache.writeNotFound(key);
      return null;
    }
    await cache.writeGame(key, fetched);
    return fetched;
  }

  Future<void> refresh() async {
    state = const AsyncValue<SsGame?>.loading();
    state = await AsyncValue.guard(() => build(arg));
  }
}
