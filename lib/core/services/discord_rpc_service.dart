// Discord Rich Presence — показывает текущий элемент в статусе Discord.

import 'dart:async';

import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/constants/platform_features.dart';
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

  /// Обновить статус Discord текущим элементом коллекции.
  ///
  /// [raData] — данные RA трекера (показывает иконку + прогресс достижений).
  Future<void> updatePresence(
    CollectionItem item, {
    TrackerGameData? raData,
  }) async {
    if (!_enabled || !kDiscordRpcAvailable) return;

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
    if (!_initialized || _rpc == null) return;
    try {
      await _rpc!.setPresence(const DiscordPresence());
    } on Exception catch (e) {
      _log.fine('Failed to clear Discord presence: $e');
    }
  }

  /// Освободить ресурсы.
  Future<void> dispose() async {
    await _disconnect();
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
