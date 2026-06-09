import 'dart:convert';

import 'tracker_profile.dart';

/// Per-game tracker progress (RA, Steam). Linked to `games.id` (IGDB id),
/// optionally scoped by [platformId] so the same IGDB game can hold separate
/// progress for each platform installation (PS2, GameCube, …).
class TrackerGameData {
  const TrackerGameData({
    required this.id,
    required this.trackerType,
    required this.gameId,
    required this.trackerGameId,
    required this.lastSyncedAt,
    this.platformId,
    this.trackerGameTitle,
    this.achievementsEarned,
    this.achievementsTotal,
    this.achievementsEarnedHardcore,
    this.awardKind,
    this.awardDate,
    this.playtimeMinutes,
    this.lastPlayedAt,
    this.trackerData,
  });

  factory TrackerGameData.fromDb(Map<String, dynamic> row) {
    final String? dataString = row['tracker_data'] as String?;
    Map<String, dynamic>? parsedData;
    if (dataString != null && dataString.isNotEmpty) {
      parsedData = json.decode(dataString) as Map<String, dynamic>;
    }

    return TrackerGameData(
      id: row['id'] as int,
      trackerType: TrackerType.fromString(row['tracker_type'] as String),
      gameId: row['game_id'] as int,
      platformId: row['platform_id'] as int?,
      trackerGameId: row['tracker_game_id'] as String,
      trackerGameTitle: row['tracker_game_title'] as String?,
      achievementsEarned: row['achievements_earned'] as int?,
      achievementsTotal: row['achievements_total'] as int?,
      achievementsEarnedHardcore:
          row['achievements_earned_hardcore'] as int?,
      awardKind: row['award_kind'] as String?,
      awardDate: row['award_date'] as int?,
      playtimeMinutes: row['playtime_minutes'] as int?,
      lastPlayedAt: row['last_played_at'] as int?,
      trackerData: parsedData,
      lastSyncedAt: row['last_synced_at'] as int,
    );
  }

  final int id;
  final TrackerType trackerType;

  /// IGDB id (`games.id`).
  final int gameId;

  /// Optional platform scope — same IGDB game on PS2 vs GameCube can hold
  /// separate progress. `null` means "applies to the game regardless of
  /// platform" (legacy rows, trackers that don't differentiate).
  final int? platformId;

  /// Provider-side game id (RA GameID / Steam AppID). Different per platform
  /// on RetroAchievements; same across platforms on Steam.
  final String trackerGameId;

  /// Provider-side title, can drift from IGDB.
  final String? trackerGameTitle;

  final int? achievementsEarned;
  final int? achievementsTotal;

  /// RA-only — hardcore mode counts achievements without save-state cheats.
  final int? achievementsEarnedHardcore;

  /// 'mastered-hardcore', 'beaten-softcore', or null. RA awards.
  final String? awardKind;

  final int? awardDate;

  /// Steam-only.
  final int? playtimeMinutes;

  final int? lastPlayedAt;

  /// Provider-specific opaque blob (e.g. RA recent achievements list).
  final Map<String, dynamic>? trackerData;

  final int lastSyncedAt;

  /// 0.0–1.0; 0.0 when [achievementsTotal] is null / zero.
  double get completionRate {
    if (achievementsTotal == null ||
        achievementsTotal == 0 ||
        achievementsEarned == null) {
      return 0.0;
    }
    return achievementsEarned! / achievementsTotal!;
  }

  /// 0.0–1.0 for RA hardcore mode.
  double get hardcoreCompletionRate {
    if (achievementsTotal == null ||
        achievementsTotal == 0 ||
        achievementsEarnedHardcore == null) {
      return 0.0;
    }
    return achievementsEarnedHardcore! / achievementsTotal!;
  }

  bool get hasAward => awardKind != null;

  bool get isMastered =>
      awardKind != null && awardKind!.contains('mastered');

  bool get isBeaten =>
      awardKind != null && awardKind!.contains('beaten');

  bool get isHardcore =>
      awardKind != null && awardKind!.contains('hardcore');

  String get raGameUrl =>
      'https://retroachievements.org/game/$trackerGameId';

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'tracker_type': trackerType.value,
      'game_id': gameId,
      'platform_id': platformId,
      'tracker_game_id': trackerGameId,
      'tracker_game_title': trackerGameTitle,
      'achievements_earned': achievementsEarned,
      'achievements_total': achievementsTotal,
      'achievements_earned_hardcore': achievementsEarnedHardcore,
      'award_kind': awardKind,
      'award_date': awardDate,
      'playtime_minutes': playtimeMinutes,
      'last_played_at': lastPlayedAt,
      'tracker_data': trackerData != null ? json.encode(trackerData) : null,
      'last_synced_at': lastSyncedAt,
    };
  }

  TrackerGameData copyWith({
    int? id,
    TrackerType? trackerType,
    int? gameId,
    int? platformId,
    bool clearPlatformId = false,
    String? trackerGameId,
    String? trackerGameTitle,
    int? achievementsEarned,
    int? achievementsTotal,
    int? achievementsEarnedHardcore,
    String? awardKind,
    int? awardDate,
    int? playtimeMinutes,
    int? lastPlayedAt,
    Map<String, dynamic>? trackerData,
    int? lastSyncedAt,
  }) {
    return TrackerGameData(
      id: id ?? this.id,
      trackerType: trackerType ?? this.trackerType,
      gameId: gameId ?? this.gameId,
      platformId:
          clearPlatformId ? null : (platformId ?? this.platformId),
      trackerGameId: trackerGameId ?? this.trackerGameId,
      trackerGameTitle: trackerGameTitle ?? this.trackerGameTitle,
      achievementsEarned: achievementsEarned ?? this.achievementsEarned,
      achievementsTotal: achievementsTotal ?? this.achievementsTotal,
      achievementsEarnedHardcore:
          achievementsEarnedHardcore ?? this.achievementsEarnedHardcore,
      awardKind: awardKind ?? this.awardKind,
      awardDate: awardDate ?? this.awardDate,
      playtimeMinutes: playtimeMinutes ?? this.playtimeMinutes,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      trackerData: trackerData ?? this.trackerData,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
