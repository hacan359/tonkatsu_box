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

/// Application ID from the Discord Developer Portal.
const String _kApplicationId = '1492141877456015491';

final Provider<DiscordRpcService> discordRpcServiceProvider =
    Provider<DiscordRpcService>((Ref ref) {
  final DiscordRpcService service = DiscordRpcService();
  ref.onDispose(service.dispose);
  return service;
});

/// Shows the current collection item in the Discord status.
///
/// Talks to the local Discord client over an IPC pipe, so it works on
/// desktop only (Windows/Linux/macOS).
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
  _RaGameCache? _raGameCache;

  /// While RA sync is active, regular updatePresence/clearPresence calls
  /// are ignored.
  bool get isRaSyncActive => _raSyncActive;

  bool get isConnected => _initialized;

  bool get isEnabled => _enabled;

  Future<void> enable() async {
    _enabled = true;
    if (!kDiscordRpcAvailable) return;
    await _connect();
  }

  Future<void> disable() async {
    _enabled = false;
    _lastPresenceKey = null;
    await clearPresence();
    await _disconnect();
  }

  /// Starts mirroring RA Rich Presence to Discord by polling the RA API.
  /// While RA sync is active, [updatePresence] and [clearPresence] no-op.
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

    // Poll immediately, then every 30 seconds.
    await _pollRaPresence();

    _raPollTimer?.cancel();
    _raPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollRaPresence(),
    );

    _log.info('RA sync started for $raUsername');
  }

  Future<void> disableRaSync() async {
    _raPollTimer?.cancel();
    _raPollTimer = null;
    _raSyncActive = false;
    _raApi = null;
    _raUsername = null;
    _lastRaPresence = null;
    _lastRaGameId = null;
    _raGameCache = null;

    // Clear the Discord status left behind by RA sync.
    if (_initialized && _rpc != null) {
      try {
        await _rpc!.setPresence(const DiscordPresence());
      } on Exception catch (_) {}
    }

    _log.info('RA sync stopped');
  }

  /// [raData] — RA tracker data; when present, shows the RA icon plus
  /// achievement progress.
  Future<void> updatePresence(
    CollectionItem item, {
    TrackerGameData? raData,
    String animeMangaTitleLanguage = 'romaji',
  }) async {
    if (!_enabled || !kDiscordRpcAvailable || _raSyncActive) return;

    // Dedupe — skip if this item is already being shown.
    final String key = '${item.mediaType.value}:${item.externalId}';
    if (key == _lastPresenceKey) return;
    _lastPresenceKey = key;

    // Lazy reconnect in case Discord was launched after the app.
    if (!_initialized) await _connect();
    if (!_initialized || _rpc == null) return;

    // The item's cover becomes the large image; the logo moves to the small
    // icon for branding. With no usable cover URL the logo stays large.
    final String? coverUrl = _remoteCoverUrl(item);
    final DiscordAsset largeAsset = coverUrl != null
        ? DiscordAsset.fromUrl(
            coverUrl,
            text: item.displayName(animeMangaTitleLanguage),
          )
        : const DiscordAsset(key: 'logo', text: 'Tonkatsu Box');
    final DiscordAsset? smallAsset = raData != null
        ? DiscordAsset(key: 'ra', text: _buildRaTooltip(raData))
        : coverUrl != null
            ? const DiscordAsset(key: 'logo', text: 'Tonkatsu Box')
            : null;

    try {
      await _rpc!.setPresence(DiscordPresence(
        details: '${_activityVerb(item.mediaType)} '
            '${item.displayName(animeMangaTitleLanguage)}',
        state: _buildState(item, raData),
        timestamps: DiscordTimestamps(
          start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        largeAsset: largeAsset,
        smallAsset: smallAsset,
      ));
    } on Exception catch (e) {
      _log.fine('Failed to update Discord presence: $e');
      _initialized = false;
    }
  }

  /// Called when leaving the item detail screen.
  Future<void> clearPresence() async {
    _lastPresenceKey = null;
    if (_raSyncActive || !_initialized || _rpc == null) return;
    try {
      await _rpc!.setPresence(const DiscordPresence());
    } on Exception catch (e) {
      _log.fine('Failed to clear Discord presence: $e');
    }
  }

  Future<void> dispose() async {
    _raPollTimer?.cancel();
    _raPollTimer = null;
    await _disconnect();
  }

  Future<void> _pollRaPresence() async {
    if (!_raSyncActive || _raApi == null || _raUsername == null) return;
    if (!_initialized) await _connect();
    if (!_initialized || _rpc == null) return;

    try {
      final RaUserProfile profile =
          await _raApi!.getUserProfile(_raUsername!);
      final String presenceMsg = profile.richPresenceMsg ?? '';
      final int? gameId = profile.lastGameId;

      // Dedupe — skip the update when nothing changed.
      if (presenceMsg == _lastRaPresence && gameId == _lastRaGameId) return;
      _lastRaPresence = presenceMsg;

      if (presenceMsg.isEmpty || gameId == null || gameId == 0) {
        _lastRaGameId = null;
        _raGameCache = null;
        await _rpc!.setPresence(const DiscordPresence());
        return;
      }

      // Refetch game info only when the game changed.
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

  /// Builds the second line: platform/progress + year + RA achievements.
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
      MediaType.book => switch ((item.book?.isComic ?? false, item.book?.pageCount)) {
          (true, final int count?) => 'Comic · $count issues$yearSuffix',
          (true, _) => 'Comic$yearSuffix',
          (false, final int count?) => 'Book · $count pages$yearSuffix',
          (false, _) => 'Book$yearSuffix',
        },
      MediaType.custom => 'Custom$yearSuffix',
    };

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

  /// The item's cover URL when Discord can fetch it directly — i.e. a remote
  /// http(s) link. Custom items may store a `local://` file marker instead;
  /// those return null so the caller falls back to the logo.
  static String? _remoteCoverUrl(CollectionItem item) {
    final String? url = item.coverUrl;
    if (url == null) return null;
    return url.startsWith('http') ? url : null;
  }

  /// Tooltip for the RA icon.
  static String _buildRaTooltip(TrackerGameData raData) {
    if (raData.isMastered) return 'Mastered';
    if (raData.isBeaten) return 'Beaten';
    if (raData.achievementsEarned != null && raData.achievementsTotal != null) {
      return '${raData.achievementsEarned}/${raData.achievementsTotal} achievements';
    }
    return 'RetroAchievements';
  }

  /// Activity verb — intentionally not localized, friends see it in Discord.
  static String _activityVerb(MediaType type) => switch (type) {
        MediaType.game => 'Playing',
        MediaType.movie ||
        MediaType.tvShow ||
        MediaType.animation ||
        MediaType.anime =>
          'Watching',
        MediaType.manga || MediaType.visualNovel || MediaType.book => 'Reading',
        MediaType.custom => 'Browsing',
      };
}

/// Cached game info for RA polling.
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
