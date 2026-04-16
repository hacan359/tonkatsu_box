// Провайдер настроек Kodi — per-profile persistence через SharedPreferences.

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

/// Ключи SharedPreferences для Kodi (per-profile, суффикс `_${profileId}`).
///
/// Структура уже pluralized (`kodi_profile_{id}_*`) — готова к поддержке
/// нескольких Kodi хостов в будущем. Для MVP active profile = `default`.
abstract class KodiSettingsKeys {
  /// Kodi sync включён.
  static String enabled(String profileId) =>
      'kodi_enabled_$profileId';

  /// Hostname или IP.
  static String host(String profileId) =>
      'kodi_host_$profileId';

  /// HTTP JSON-RPC порт (default 8080).
  static String port(String profileId) =>
      'kodi_port_$profileId';

  /// HTTP Basic Auth username.
  static String username(String profileId) =>
      'kodi_username_$profileId';

  /// HTTP Basic Auth password.
  static String password(String profileId) =>
      'kodi_password_$profileId';

  /// Интервал синхронизации в секундах.
  static String syncIntervalSeconds(String profileId) =>
      'kodi_sync_interval_seconds_$profileId';

  /// Копировать userrating из Kodi (1–10) в наш userRating если пусто.
  static String importRatings(String profileId) =>
      'kodi_import_ratings_$profileId';

  /// Добавлять unmatched items в wishlist.
  static String addUnmatchedToWishlist(String profileId) =>
      'kodi_add_unmatched_to_wishlist_$profileId';

  /// Timestamp последней успешной синхронизации (ISO 8601).
  static String lastSyncTimestamp(String profileId) =>
      'kodi_last_sync_timestamp_$profileId';

  /// ID целевой коллекции для импорта.
  static String targetCollectionId(String profileId) =>
      'kodi_target_collection_id_$profileId';

  /// Создавать подколлекции из Kodi movie sets.
  static String createSubCollections(String profileId) =>
      'kodi_create_sub_collections_$profileId';
}

/// Порт Kodi HTTP JSON-RPC по умолчанию.
const int kodiDefaultPort = 8080;

/// Интервал синхронизации по умолчанию (60 секунд).
const int kodiDefaultSyncIntervalSeconds = 60;

/// Состояние настроек Kodi.
class KodiSettingsState {
  /// Создаёт [KodiSettingsState].
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

  /// Мастер-выключатель sync.
  final bool enabled;

  /// Hostname / IP Kodi.
  final String host;

  /// HTTP JSON-RPC порт.
  final int port;

  /// HTTP Basic Auth username.
  final String username;

  /// HTTP Basic Auth password.
  final String password;

  /// Интервал синхронизации в секундах.
  final int syncIntervalSeconds;

  /// Копировать userrating из Kodi.
  final bool importRatings;

  /// Добавлять unmatched items в wishlist.
  final bool addUnmatchedToWishlist;

  /// Timestamp последней синхронизации (ISO 8601).
  final String? lastSyncTimestamp;

  /// ID целевой коллекции для импорта (null = создать новую).
  final int? targetCollectionId;

  /// Создавать подколлекции из Kodi movie sets.
  final bool createSubCollections;

  /// Есть ли заполненный host для подключения.
  bool get hasConnection => host.isNotEmpty;

  /// Копирует с изменёнными полями.
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

/// Провайдер настроек Kodi.
final NotifierProvider<KodiSettingsNotifier, KodiSettingsState>
    kodiSettingsProvider =
    NotifierProvider<KodiSettingsNotifier, KodiSettingsState>(
  KodiSettingsNotifier.new,
);

/// Notifier для настроек Kodi с per-profile persistence.
///
/// При изменении host/port/creds автоматически вызывает
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

    // Синхронизируем KodiApi с сохранёнными настройками.
    if (loaded.hasConnection) {
      _kodiApi.setConnection(
        host: loaded.host,
        port: loaded.port,
        username: loaded.username.isNotEmpty ? loaded.username : null,
        password: loaded.password.isNotEmpty ? loaded.password : null,
      );
    }

    // Автозапуск sync при старте если enabled + target collection задана.
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

  /// Включает/выключает Kodi sync.
  Future<void> setEnabled({required bool enabled}) async {
    await _prefs.setBool(KodiSettingsKeys.enabled(_profileId), enabled);
    state = state.copyWith(enabled: enabled);
  }

  /// Устанавливает host и обновляет [KodiApi].
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

  /// Устанавливает порт и обновляет [KodiApi].
  Future<void> setPort(int port) async {
    await _prefs.setInt(KodiSettingsKeys.port(_profileId), port);
    state = state.copyWith(port: port);
    _syncKodiApi();
  }

  /// Устанавливает username и обновляет [KodiApi].
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

  /// Устанавливает password и обновляет [KodiApi].
  Future<void> setPassword(String password) async {
    if (password.isNotEmpty) {
      await _prefs.setString(KodiSettingsKeys.password(_profileId), password);
    } else {
      await _prefs.remove(KodiSettingsKeys.password(_profileId));
    }
    state = state.copyWith(password: password);
    _syncKodiApi();
  }

  /// Устанавливает интервал синхронизации.
  Future<void> setSyncIntervalSeconds(int seconds) async {
    await _prefs.setInt(
      KodiSettingsKeys.syncIntervalSeconds(_profileId),
      seconds,
    );
    state = state.copyWith(syncIntervalSeconds: seconds);
  }

  /// Включает/выключает импорт рейтингов из Kodi.
  Future<void> setImportRatings({required bool enabled}) async {
    await _prefs.setBool(
      KodiSettingsKeys.importRatings(_profileId),
      enabled,
    );
    state = state.copyWith(importRatings: enabled);
  }

  /// Включает/выключает добавление unmatched в wishlist.
  Future<void> setAddUnmatchedToWishlist({required bool enabled}) async {
    await _prefs.setBool(
      KodiSettingsKeys.addUnmatchedToWishlist(_profileId),
      enabled,
    );
    state = state.copyWith(addUnmatchedToWishlist: enabled);
  }

  /// Обновляет timestamp последней синхронизации.
  Future<void> setLastSyncTimestamp(String timestamp) async {
    await _prefs.setString(
      KodiSettingsKeys.lastSyncTimestamp(_profileId),
      timestamp,
    );
    state = state.copyWith(lastSyncTimestamp: timestamp);
  }

  /// Устанавливает целевую коллекцию для импорта.
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

  /// Включает/выключает создание подколлекций из Kodi sets.
  Future<void> setCreateSubCollections({required bool enabled}) async {
    await _prefs.setBool(
      KodiSettingsKeys.createSubCollections(_profileId),
      enabled,
    );
    state = state.copyWith(createSubCollections: enabled);
  }

  /// Сбрасывает timestamp последней синхронизации.
  ///
  /// Следующая синхронизация заберёт все items с `playcount > 0`.
  Future<void> clearLastSyncTimestamp() async {
    await _prefs.remove(KodiSettingsKeys.lastSyncTimestamp(_profileId));
    state = state.copyWith(clearLastSync: true);
  }

  /// Сбрасывает все настройки Kodi для текущего профиля.
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

  /// Синхронизирует [KodiApi] с текущим state.
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
