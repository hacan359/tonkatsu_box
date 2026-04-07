// Модель прогресса per-game от внешнего трекера.

import 'dart:convert';

import 'tracker_profile.dart';

/// Прогресс по игре от внешнего трекера (RA, Steam).
///
/// Привязан к `games.id` (IGDB), а не к `collection_items.id`.
/// Одна запись на трекер на игру.
class TrackerGameData {
  /// Создаёт [TrackerGameData].
  const TrackerGameData({
    required this.id,
    required this.trackerType,
    required this.gameId,
    required this.trackerGameId,
    required this.lastSyncedAt,
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

  /// Создаёт [TrackerGameData] из записи БД.
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

  /// Уникальный ID.
  final int id;

  /// Тип трекера.
  final TrackerType trackerType;

  /// IGDB ID игры (`games.id`).
  final int gameId;

  /// ID игры в трекере (RA GameID / Steam AppID).
  final String trackerGameId;

  /// Название в трекере (может отличаться от IGDB).
  final String? trackerGameTitle;

  /// Полученные достижения.
  final int? achievementsEarned;

  /// Всего достижений.
  final int? achievementsTotal;

  /// Hardcore достижения (RA).
  final int? achievementsEarnedHardcore;

  /// Тип награды ('mastered-hardcore', 'beaten-softcore', null).
  final String? awardKind;

  /// Timestamp получения award.
  final int? awardDate;

  /// Время игры в минутах (Steam).
  final int? playtimeMinutes;

  /// Timestamp последней активности.
  final int? lastPlayedAt;

  /// JSON для доп. данных.
  final Map<String, dynamic>? trackerData;

  /// Timestamp последнего sync.
  final int lastSyncedAt;

  /// Процент прохождения (0.0–1.0).
  double get completionRate {
    if (achievementsTotal == null ||
        achievementsTotal == 0 ||
        achievementsEarned == null) {
      return 0.0;
    }
    return achievementsEarned! / achievementsTotal!;
  }

  /// Процент hardcore прохождения (0.0–1.0, RA only).
  double get hardcoreCompletionRate {
    if (achievementsTotal == null ||
        achievementsTotal == 0 ||
        achievementsEarnedHardcore == null) {
      return 0.0;
    }
    return achievementsEarnedHardcore! / achievementsTotal!;
  }

  /// Есть ли award (beaten/mastered).
  bool get hasAward => awardKind != null;

  /// Mastered (все ачивки).
  bool get isMastered =>
      awardKind != null && awardKind!.contains('mastered');

  /// Beaten.
  bool get isBeaten =>
      awardKind != null && awardKind!.contains('beaten');

  /// Hardcore mode.
  bool get isHardcore =>
      awardKind != null && awardKind!.contains('hardcore');

  /// URL страницы игры на RA.
  String get raGameUrl =>
      'https://retroachievements.org/game/$trackerGameId';

  /// Преобразует в Map для БД.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'tracker_type': trackerType.value,
      'game_id': gameId,
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

  /// Создаёт копию с изменёнными полями.
  TrackerGameData copyWith({
    int? id,
    TrackerType? trackerType,
    int? gameId,
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
