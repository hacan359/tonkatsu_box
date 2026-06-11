import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/kodi_api.dart';
import '../../../core/services/kodi_sync_service.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import 'profile_provider.dart';
import 'settings_provider.dart';

/// SharedPreferences keys for Kodi, suffixed with `_$profileId`: the
/// per-profile shape leaves room for multiple Kodi hosts later
/// (the MVP only uses the `default` profile).
abstract class KodiSettingsKeys {
  static String enabled(String profileId) =>
      'kodi_enabled_$profileId';

  /// Hostname or IP.
  static String host(String profileId) =>
      'kodi_host_$profileId';

  /// HTTP JSON-RPC port (default 8080).
  static String port(String profileId) =>
      'kodi_port_$profileId';

  /// HTTP Basic Auth username.
  static String username(String profileId) =>
      'kodi_username_$profileId';

  /// HTTP Basic Auth password.
  static String password(String profileId) =>
      'kodi_password_$profileId';

  static String syncIntervalSeconds(String profileId) =>
      'kodi_sync_interval_seconds_$profileId';

  /// Copy Kodi userrating (1-10) into our userRating when it is empty.
  static String importRatings(String profileId) =>
      'kodi_import_ratings_$profileId';

  static String addUnmatchedToWishlist(String profileId) =>
      'kodi_add_unmatched_to_wishlist_$profileId';

  /// Timestamp of the last successful sync (ISO 8601).
  static String lastSyncTimestamp(String profileId) =>
      'kodi_last_sync_timestamp_$profileId';

  static String targetCollectionId(String profileId) =>
      'kodi_target_collection_id_$profileId';

  /// Create sub-collections from Kodi movie sets.
  static String createSubCollections(String profileId) =>
      'kodi_create_sub_collections_$profileId';
}

const int kodiDefaultPort = 8080;

const int kodiDefaultSyncIntervalSeconds = 60;

class KodiSettingsState {
  const KodiSettingsState({
    this.enabled = false,
    this.host = '',
    this.port = kodiDefaultPort,
    this.username = '',
    this.password = '',
    this.syncIntervalSeconds = kodiDefaultSyncIntervalSeconds,
    this.importRatings = false,
    this.addUnmatchedToWishlist = true,
    this.lastSyncTimestamp,
    this.targetCollectionId,
    this.createSubCollections = true,
  });

  final bool enabled;

  /// Hostname or IP.
  final String host;

  /// HTTP JSON-RPC port.
  final int port;

  /// HTTP Basic Auth username.
  final String username;

  /// HTTP Basic Auth password.
  final String password;

  final int syncIntervalSeconds;

  final bool importRatings;

  final bool addUnmatchedToWishlist;

  /// Timestamp of the last sync (ISO 8601).
  final String? lastSyncTimestamp;

  /// Target collection id; null means create a new collection.
  final int? targetCollectionId;

  /// Create sub-collections from Kodi movie sets.
  final bool createSubCollections;

  bool get hasConnection => host.isNotEmpty;

  KodiSettingsState copyWith({
    bool? enabled,
    String? host,
    int? port,
    String? username,
    String? password,
    int? syncIntervalSeconds,
    bool? importRatings,
    bool? addUnmatchedToWishlist,
    String? lastSyncTimestamp,
    bool clearLastSync = false,
    int? targetCollectionId,
    bool clearTargetCollection = false,
    bool? createSubCollections,
  }) {
    return KodiSettingsState(
      enabled: enabled ?? this.enabled,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      syncIntervalSeconds: syncIntervalSeconds ?? this.syncIntervalSeconds,
      importRatings: importRatings ?? this.importRatings,
      addUnmatchedToWishlist:
          addUnmatchedToWishlist ?? this.addUnmatchedToWishlist,
      lastSyncTimestamp:
          clearLastSync ? null : (lastSyncTimestamp ?? this.lastSyncTimestamp),
      targetCollectionId: clearTargetCollection
          ? null
          : (targetCollectionId ?? this.targetCollectionId),
      createSubCollections: createSubCollections ?? this.createSubCollections,
    );
  }
}

final NotifierProvider<KodiSettingsNotifier, KodiSettingsState>
    kodiSettingsProvider =
    NotifierProvider<KodiSettingsNotifier, KodiSettingsState>(
  KodiSettingsNotifier.new,
);

/// Host/port/credential changes are pushed to [KodiApi] automatically via
/// [KodiApi.setConnection] / [KodiApi.clearConnection].
class KodiSettingsNotifier extends Notifier<KodiSettingsState> {
  late SharedPreferences _prefs;
  late KodiApi _kodiApi;
  late String _profileId;

  @override
  KodiSettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _kodiApi = ref.watch(kodiApiProvider);
    _profileId = ref.watch(currentProfileProvider).id;

    final KodiSettingsState loaded = _loadFromPrefs();

    if (loaded.hasConnection) {
      _kodiApi.setConnection(
        host: loaded.host,
        port: loaded.port,
        username: loaded.username.isNotEmpty ? loaded.username : null,
        password: loaded.password.isNotEmpty ? loaded.password : null,
      );
    }

    // Autostart sync on launch when enabled and a target collection is set.
    if (loaded.enabled &&
        loaded.hasConnection &&
        loaded.targetCollectionId != null) {
      Future<void>.microtask(() {
        final KodiSyncService sync = ref.read(kodiSyncServiceProvider);
        sync.start(
          intervalSeconds: loaded.syncIntervalSeconds,
          targetCollectionId: loaded.targetCollectionId!,
          importRatings: loaded.importRatings,
          createSubCollections: loaded.createSubCollections,
          onSyncTimestamp: (String timestamp) {
            setLastSyncTimestamp(timestamp);
          },
          onResult: (KodiSyncResult result) {
            if (result.hasChanges) {
              ref.invalidate(collectionsProvider);
              ref.invalidate(allItemsNotifierProvider);
              for (final int collId in result.affectedCollectionIds) {
                ref.invalidate(collectionStatsProvider(collId));
                ref.invalidate(collectionCoversProvider(collId));
                ref.invalidate(collectionItemsNotifierProvider(collId));
                ref.invalidate(canvasNotifierProvider(collId));
              }
            }
          },
          onTargetNotFound: () {
            setEnabled(enabled: false);
            setTargetCollectionId(null);
          },
        );
      });
    }

    return loaded;
  }

  KodiSettingsState _loadFromPrefs() {
    final bool enabled =
        _prefs.getBool(KodiSettingsKeys.enabled(_profileId)) ?? false;
    final String host =
        _prefs.getString(KodiSettingsKeys.host(_profileId)) ?? '';
    final int port =
        _prefs.getInt(KodiSettingsKeys.port(_profileId)) ?? kodiDefaultPort;
    final String username =
        _prefs.getString(KodiSettingsKeys.username(_profileId)) ?? '';
    final String password =
        _prefs.getString(KodiSettingsKeys.password(_profileId)) ?? '';
    final int syncIntervalSeconds =
        _prefs.getInt(KodiSettingsKeys.syncIntervalSeconds(_profileId)) ??
            kodiDefaultSyncIntervalSeconds;
    final bool importRatings =
        _prefs.getBool(KodiSettingsKeys.importRatings(_profileId)) ?? false;
    final bool addUnmatchedToWishlist =
        _prefs.getBool(KodiSettingsKeys.addUnmatchedToWishlist(_profileId)) ??
            true;
    final String? lastSyncTimestamp =
        _prefs.getString(KodiSettingsKeys.lastSyncTimestamp(_profileId));
    final int? targetCollectionId =
        _prefs.getInt(KodiSettingsKeys.targetCollectionId(_profileId));
    final bool createSubCollections =
        _prefs.getBool(KodiSettingsKeys.createSubCollections(_profileId)) ??
            true;

    return KodiSettingsState(
      enabled: enabled,
      host: host,
      port: port,
      username: username,
      password: password,
      syncIntervalSeconds: syncIntervalSeconds,
      importRatings: importRatings,
      addUnmatchedToWishlist: addUnmatchedToWishlist,
      lastSyncTimestamp: lastSyncTimestamp,
      targetCollectionId: targetCollectionId,
      createSubCollections: createSubCollections,
    );
  }

  Future<void> setEnabled({required bool enabled}) async {
    await _prefs.setBool(KodiSettingsKeys.enabled(_profileId), enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> setHost(String host) async {
    final String trimmed = host.trim();
    if (trimmed.isNotEmpty) {
      await _prefs.setString(KodiSettingsKeys.host(_profileId), trimmed);
    } else {
      await _prefs.remove(KodiSettingsKeys.host(_profileId));
    }
    state = state.copyWith(host: trimmed);
    _syncKodiApi();
  }

  Future<void> setPort(int port) async {
    await _prefs.setInt(KodiSettingsKeys.port(_profileId), port);
    state = state.copyWith(port: port);
    _syncKodiApi();
  }

  Future<void> setUsername(String username) async {
    final String trimmed = username.trim();
    if (trimmed.isNotEmpty) {
      await _prefs.setString(KodiSettingsKeys.username(_profileId), trimmed);
    } else {
      await _prefs.remove(KodiSettingsKeys.username(_profileId));
    }
    state = state.copyWith(username: trimmed);
    _syncKodiApi();
  }

  Future<void> setPassword(String password) async {
    if (password.isNotEmpty) {
      await _prefs.setString(KodiSettingsKeys.password(_profileId), password);
    } else {
      await _prefs.remove(KodiSettingsKeys.password(_profileId));
    }
    state = state.copyWith(password: password);
    _syncKodiApi();
  }

  Future<void> setSyncIntervalSeconds(int seconds) async {
    await _prefs.setInt(
      KodiSettingsKeys.syncIntervalSeconds(_profileId),
      seconds,
    );
    state = state.copyWith(syncIntervalSeconds: seconds);
  }

  Future<void> setImportRatings({required bool enabled}) async {
    await _prefs.setBool(
      KodiSettingsKeys.importRatings(_profileId),
      enabled,
    );
    state = state.copyWith(importRatings: enabled);
  }

  Future<void> setAddUnmatchedToWishlist({required bool enabled}) async {
    await _prefs.setBool(
      KodiSettingsKeys.addUnmatchedToWishlist(_profileId),
      enabled,
    );
    state = state.copyWith(addUnmatchedToWishlist: enabled);
  }

  Future<void> setLastSyncTimestamp(String timestamp) async {
    await _prefs.setString(
      KodiSettingsKeys.lastSyncTimestamp(_profileId),
      timestamp,
    );
    state = state.copyWith(lastSyncTimestamp: timestamp);
  }

  Future<void> setTargetCollectionId(int? collectionId) async {
    if (collectionId != null) {
      await _prefs.setInt(
        KodiSettingsKeys.targetCollectionId(_profileId),
        collectionId,
      );
      state = state.copyWith(targetCollectionId: collectionId);
    } else {
      await _prefs.remove(KodiSettingsKeys.targetCollectionId(_profileId));
      state = state.copyWith(clearTargetCollection: true);
    }
  }

  Future<void> setCreateSubCollections({required bool enabled}) async {
    await _prefs.setBool(
      KodiSettingsKeys.createSubCollections(_profileId),
      enabled,
    );
    state = state.copyWith(createSubCollections: enabled);
  }

  /// After this the next sync re-fetches every item with `playcount > 0`.
  Future<void> clearLastSyncTimestamp() async {
    await _prefs.remove(KodiSettingsKeys.lastSyncTimestamp(_profileId));
    state = state.copyWith(clearLastSync: true);
  }

  /// Clears every Kodi setting for the current profile only.
  Future<void> clearAll() async {
    await _prefs.remove(KodiSettingsKeys.enabled(_profileId));
    await _prefs.remove(KodiSettingsKeys.host(_profileId));
    await _prefs.remove(KodiSettingsKeys.port(_profileId));
    await _prefs.remove(KodiSettingsKeys.username(_profileId));
    await _prefs.remove(KodiSettingsKeys.password(_profileId));
    await _prefs.remove(KodiSettingsKeys.syncIntervalSeconds(_profileId));
    await _prefs.remove(KodiSettingsKeys.importRatings(_profileId));
    await _prefs.remove(KodiSettingsKeys.addUnmatchedToWishlist(_profileId));
    await _prefs.remove(KodiSettingsKeys.lastSyncTimestamp(_profileId));
    await _prefs.remove(KodiSettingsKeys.targetCollectionId(_profileId));
    await _prefs.remove(KodiSettingsKeys.createSubCollections(_profileId));

    _kodiApi.clearConnection();
    state = const KodiSettingsState();
  }

  void _syncKodiApi() {
    if (state.hasConnection) {
      _kodiApi.setConnection(
        host: state.host,
        port: state.port,
        username: state.username.isNotEmpty ? state.username : null,
        password: state.password.isNotEmpty ? state.password : null,
      );
    } else {
      _kodiApi.clearConnection();
    }
  }
}
