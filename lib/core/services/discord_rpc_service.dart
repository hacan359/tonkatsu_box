// Discord Rich Presence — показывает текущий элемент в статусе Discord.

import 'dart:async';

import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../api/ra_api.dart';
import '../../shared/constants/platform_features.dart';
import '../../shared/models/ra_user_profile.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/tracker_game_data.dart';

/// Application ID из Discord Developer Portal.
const String _kApplicationId = '1492141877456015491';

/// Провайдер сервиса Discord RPC.
final Provider<DiscordRpcService> discordRpcServiceProvider =
    Provider<DiscordRpcService>((Ref ref) {
  final DiscordRpcService service = DiscordRpcService();
  ref.onDispose(service.dispose);
  return service;
});

/// Сервис для отображения текущего элемента коллекции в статусе Discord.
///
/// Подключается к локальному Discord клиенту через IPC pipe.
/// Работает только на десктопе (Windows/Linux/macOS).
class DiscordRpcService {
  static final Logger _log = Logger('DiscordRpcService');

  DiscordRPC? _rpc;
  bool _initialized = false;
  bool _enabled = false;
  String? _lastPresenceKey;

  // RA sync polling
  bool _raSyncActive = false;
  Timer? _raPollTimer;
  RaApi? _raApi;
  String? _raUsername;
  String? _lastRaPresence;
  int? _lastRaGameId;
  // Кэш game info: {title, consoleName, earned, total}
  _RaGameCache? _raGameCache;

  /// RA sync активен — обычные updatePresence/clearPresence игнорируются.
  bool get isRaSyncActive => _raSyncActive;

  /// Подключён ли сервис к Discord IPC.
  bool get isConnected => _initialized;

  /// Включён ли сервис пользователем.
  bool get isEnabled => _enabled;

  /// Подключиться к Discord (вызывается при включении настройки).
  Future<void> enable() async {
    _enabled = true;
    if (!kDiscordRpcAvailable) return;
    await _connect();
  }

  /// Отключиться от Discord (вызывается при выключении настройки).
  Future<void> disable() async {
    _enabled = false;
    _lastPresenceKey = null;
    await clearPresence();
    await _disconnect();
  }

  /// Запустить трансляцию RA Rich Presence в Discord.
  ///
  /// Периодически опрашивает RA API и обновляет Discord статус.
  /// Пока RA sync активен, [updatePresence] и [clearPresence] игнорируются.
  Future<void> enableRaSync({
    required RaApi raApi,
    required String raUsername,
  }) async {
    _raApi = raApi;
    _raUsername = raUsername;
    _raSyncActive = true;
    _lastRaPresence = null;
    _lastPresenceKey = null;

    if (!_enabled || !kDiscordRpcAvailable) return;
    if (!_initialized) await _connect();

    // Первый опрос сразу
    await _pollRaPresence();

    // Затем каждые 30 секунд
    _raPollTimer?.cancel();
    _raPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollRaPresence(),
    );

    _log.info('RA sync started for $raUsername');
  }

  /// Остановить трансляцию RA Rich Presence.
  Future<void> disableRaSync() async {
    _raPollTimer?.cancel();
    _raPollTimer = null;
    _raSyncActive = false;
    _raApi = null;
    _raUsername = null;
    _lastRaPresence = null;
    _lastRaGameId = null;
    _raGameCache = null;

    // Очищаем Discord статус после остановки RA sync
    if (_initialized && _rpc != null) {
      try {
        await _rpc!.setPresence(const DiscordPresence());
      } on Exception catch (_) {}
    }

    _log.info('RA sync stopped');
  }

  /// Обновить статус Discord текущим элементом коллекции.
  ///
  /// [raData] — данные RA трекера (показывает иконку + прогресс достижений).
  Future<void> updatePresence(
    CollectionItem item, {
    TrackerGameData? raData,
  }) async {
    if (!_enabled || !kDiscordRpcAvailable || _raSyncActive) return;

    // Дедупликация — не обновлять если уже показываем этот элемент
    final String key = '${item.mediaType.value}:${item.externalId}';
    if (key == _lastPresenceKey) return;
    _lastPresenceKey = key;

    // Lazy reconnect если Discord был запущен после приложения
    if (!_initialized) await _connect();
    if (!_initialized || _rpc == null) return;

    try {
      await _rpc!.setPresence(DiscordPresence(
        details: '${_activityVerb(item.mediaType)} ${item.itemName}',
        state: _buildState(item, raData),
        timestamps: DiscordTimestamps(
          start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        largeAsset: const DiscordAsset(
          key: 'logo',
          text: 'Tonkatsu Box',
        ),
        smallAsset: raData != null
            ? DiscordAsset(
                key: 'ra',
                text: _buildRaTooltip(raData),
              )
            : null,
      ));
    } on Exception catch (e) {
      _log.fine('Failed to update Discord presence: $e');
      _initialized = false;
    }
  }

  /// Очистить статус Discord (вызывается при уходе с экрана деталей).
  Future<void> clearPresence() async {
    _lastPresenceKey = null;
    if (_raSyncActive || !_initialized || _rpc == null) return;
    try {
      await _rpc!.setPresence(const DiscordPresence());
    } on Exception catch (e) {
      _log.fine('Failed to clear Discord presence: $e');
    }
  }

  /// Освободить ресурсы.
  Future<void> dispose() async {
    _raPollTimer?.cancel();
    _raPollTimer = null;
    await _disconnect();
  }

  /// Опрашивает RA API и обновляет Discord presence.
  Future<void> _pollRaPresence() async {
    if (!_raSyncActive || _raApi == null || _raUsername == null) return;
    if (!_initialized) await _connect();
    if (!_initialized || _rpc == null) return;

    try {
      final RaUserProfile profile =
          await _raApi!.getUserProfile(_raUsername!);
      final String presenceMsg = profile.richPresenceMsg ?? '';
      final int? gameId = profile.lastGameId;

      // Дедупликация — не обновлять если ничего не изменилось
      if (presenceMsg == _lastRaPresence && gameId == _lastRaGameId) return;
      _lastRaPresence = presenceMsg;

      if (presenceMsg.isEmpty || gameId == null || gameId == 0) {
        _lastRaGameId = null;
        _raGameCache = null;
        await _rpc!.setPresence(const DiscordPresence());
        return;
      }

      // Подтянуть game info если игра сменилась
      if (gameId != _lastRaGameId) {
        _lastRaGameId = gameId;
        _raGameCache = await _fetchGameSummary(gameId);
      }

      final String details = _raGameCache != null
          ? '${_raGameCache!.title} (${_raGameCache!.consoleName})'
          : 'RetroAchievements';

      final String state = _raGameCache != null &&
              _raGameCache!.earned != null &&
              _raGameCache!.total != null &&
              _raGameCache!.total! > 0
          ? '$presenceMsg · ${_raGameCache!.earned}/${_raGameCache!.total}'
          : presenceMsg;

      await _rpc!.setPresence(DiscordPresence(
        details: details,
        state: state,
        timestamps: DiscordTimestamps(
          start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        largeAsset: const DiscordAsset(
          key: 'logo',
          text: 'Tonkatsu Box',
        ),
        smallAsset: const DiscordAsset(
          key: 'ra',
          text: 'RetroAchievements',
        ),
      ));
    } on Exception catch (e) {
      _log.fine('RA presence poll failed: $e');
      if (e is RaApiException) return;
      _initialized = false;
    }
  }

  /// Загружает краткую инфо об игре для Discord presence.
  Future<_RaGameCache?> _fetchGameSummary(int raGameId) async {
    try {
      final Map<String, dynamic> data =
          await _raApi!.getGameSummary(_raUsername!, raGameId);
      return _RaGameCache(
        gameId: raGameId,
        title: data['Title'] as String? ?? '',
        consoleName: data['ConsoleName'] as String? ?? '',
        earned: data['NumAwardedToUserHardcore'] as int? ??
            data['NumAwardedToUser'] as int?,
        total: data['NumAchievements'] as int?,
      );
    } on Exception catch (e) {
      _log.fine('Failed to fetch RA game summary: $e');
      return null;
    }
  }

  Future<void> _connect() async {
    if (_initialized) return;
    try {
      _rpc = DiscordRPC();
      await _rpc!.initialize(_kApplicationId);
      _initialized = true;
      _log.info('Discord RPC connected');
    } on Exception catch (e) {
      _log.fine('Discord RPC init failed: $e');
      _rpc = null;
    }
  }

  Future<void> _disconnect() async {
    if (_rpc != null) {
      try {
        _rpc!.dispose();
      } on Exception catch (_) {}
    }
    _rpc = null;
    _initialized = false;
  }

  /// Строит вторую строку: платформа/прогресс + год + RA достижения.
  static String _buildState(CollectionItem item, TrackerGameData? raData) {
    final int? year = item.releaseYear;
    final String yearSuffix = year != null ? ' ($year)' : '';

    final String progress = switch (item.mediaType) {
      MediaType.game => '${item.platformName}$yearSuffix',
      MediaType.anime => item.currentEpisode > 0 && item.totalEpisodes != null
          ? 'Episode ${item.currentEpisode} / ${item.totalEpisodes}'
          : 'Anime$yearSuffix',
      MediaType.manga => item.currentEpisode > 0
          ? 'Chapter ${item.currentEpisode}'
              '${item.manga?.chapters != null ? " / ${item.manga!.chapters}" : ""}'
          : 'Manga$yearSuffix',
      MediaType.tvShow || MediaType.animation =>
        item.currentSeason > 0 || item.currentEpisode > 0
            ? 'S${item.currentSeason.toString().padLeft(2, "0")}'
              'E${item.currentEpisode.toString().padLeft(2, "0")}'
            : 'TV$yearSuffix',
      MediaType.movie =>
        'Movie${item.runtime != null ? " · ${item.runtime} min" : ""}$yearSuffix',
      MediaType.visualNovel => 'Visual Novel$yearSuffix',
      MediaType.custom => 'Custom$yearSuffix',
    };

    // Добавляем RA прогресс если есть
    if (raData != null &&
        raData.achievementsEarned != null &&
        raData.achievementsTotal != null) {
      final String award = raData.isMastered
          ? ' · Mastered'
          : raData.isBeaten
              ? ' · Beaten'
              : '';
      return '$progress · ${raData.achievementsEarned}/${raData.achievementsTotal}$award';
    }

    return progress;
  }

  /// Tooltip для RA иконки.
  static String _buildRaTooltip(TrackerGameData raData) {
    if (raData.isMastered) return 'Mastered';
    if (raData.isBeaten) return 'Beaten';
    if (raData.achievementsEarned != null && raData.achievementsTotal != null) {
      return '${raData.achievementsEarned}/${raData.achievementsTotal} achievements';
    }
    return 'RetroAchievements';
  }

  /// Глагол активности (не локализуется — виден друзьям в Discord).
  static String _activityVerb(MediaType type) => switch (type) {
        MediaType.game => 'Playing',
        MediaType.movie ||
        MediaType.tvShow ||
        MediaType.animation ||
        MediaType.anime =>
          'Watching',
        MediaType.manga || MediaType.visualNovel => 'Reading',
        MediaType.custom => 'Browsing',
      };
}

/// Кэш информации об игре для RA polling.
class _RaGameCache {
  const _RaGameCache({
    required this.gameId,
    required this.title,
    required this.consoleName,
    this.earned,
    this.total,
  });

  final int gameId;
  final String title;
  final String consoleName;
  final int? earned;
  final int? total;
}
