// Модель конкретного достижения от внешнего трекера.

import 'tracker_profile.dart';

/// Конкретное достижение per-game от трекера (RA, Steam).
class TrackerAchievement {
  /// Создаёт [TrackerAchievement].
  const TrackerAchievement({
    required this.id,
    required this.trackerType,
    required this.trackerGameId,
    required this.achievementId,
    required this.title,
    required this.displayOrder,
    required this.earned,
    this.description,
    this.points,
    this.badgeName,
    this.type,
    this.earnedAt,
  });

  /// Создаёт [TrackerAchievement] из записи БД.
  factory TrackerAchievement.fromDb(Map<String, dynamic> row) {
    return TrackerAchievement(
      id: row['id'] as int,
      trackerType: TrackerType.fromString(row['tracker_type'] as String),
      trackerGameId: row['tracker_game_id'] as String,
      achievementId: row['achievement_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      points: row['points'] as int?,
      badgeName: row['badge_name'] as String?,
      type: row['type'] as String?,
      displayOrder: row['display_order'] as int? ?? 0,
      earned: (row['earned'] as int? ?? 0) == 1,
      earnedAt: row['earned_at'] as int?,
    );
  }

  /// Создаёт [TrackerAchievement] из RA API JSON.
  ///
  /// [json] — значение из `Achievements` map в `GetGameInfoAndUserProgress`.
  /// [trackerGameId] — RA GameID.
  factory TrackerAchievement.fromRaJson(
    Map<String, dynamic> json, {
    required String trackerGameId,
  }) {
    final String? dateEarnedHardcore =
        json['DateEarnedHardcore'] as String?;
    final String? dateEarned = json['DateEarned'] as String?;
    final String? earnedDateStr = dateEarnedHardcore ?? dateEarned;

    int? earnedAtTimestamp;
    if (earnedDateStr != null && earnedDateStr.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(earnedDateStr);
      if (parsed != null) {
        earnedAtTimestamp = parsed.millisecondsSinceEpoch ~/ 1000;
      }
    }

    final bool isEarned = earnedAtTimestamp != null;

    return TrackerAchievement(
      id: 0,
      trackerType: TrackerType.ra,
      trackerGameId: trackerGameId,
      achievementId: (json['ID'] as int).toString(),
      title: json['Title'] as String? ?? '',
      description: json['Description'] as String?,
      points: json['Points'] as int?,
      badgeName: json['BadgeName'] as String?,
      type: json['Type'] as String?,
      displayOrder: json['DisplayOrder'] as int? ?? 0,
      earned: isEarned,
      earnedAt: earnedAtTimestamp,
    );
  }

  /// Уникальный ID.
  final int id;

  /// Тип трекера.
  final TrackerType trackerType;

  /// ID игры в трекере (RA GameID / Steam AppID).
  final String trackerGameId;

  /// ID достижения в трекере.
  final String achievementId;

  /// Название достижения.
  final String title;

  /// Описание достижения.
  final String? description;

  /// Очки за достижение (RA Points).
  final int? points;

  /// Имя бейджа для иконки (RA BadgeName).
  final String? badgeName;

  /// Тип достижения ('missable', 'progression', null).
  final String? type;

  /// Порядок отображения.
  final int displayOrder;

  /// Заработано ли.
  final bool earned;

  /// Timestamp разблокировки.
  final int? earnedAt;

  /// URL иконки достижения (RA).
  String? get badgeUrl => badgeName != null
      ? 'https://media.retroachievements.org/Badge/$badgeName.png'
      : null;

  /// URL иконки заблокированного достижения (RA).
  String? get lockedBadgeUrl => badgeName != null
      ? 'https://media.retroachievements.org/Badge/${badgeName}_lock.png'
      : null;

  /// Является ли missable (можно пропустить).
  bool get isMissable => type == 'missable';

  /// Является ли progression (прогрессионное).
  bool get isProgression => type == 'progression';

  /// Является ли win condition (обязательное для beaten).
  bool get isWinCondition => type == 'win_condition';

  /// DateTime разблокировки.
  DateTime? get earnedDateTime => earnedAt != null
      ? DateTime.fromMillisecondsSinceEpoch(earnedAt! * 1000)
      : null;

  /// Преобразует в Map для БД.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'tracker_type': trackerType.value,
      'tracker_game_id': trackerGameId,
      'achievement_id': achievementId,
      'title': title,
      'description': description,
      'points': points,
      'badge_name': badgeName,
      'type': type,
      'display_order': displayOrder,
      'earned': earned ? 1 : 0,
      'earned_at': earnedAt,
    };
  }

  /// Создаёт копию с изменёнными полями.
  TrackerAchievement copyWith({
    int? id,
    TrackerType? trackerType,
    String? trackerGameId,
    String? achievementId,
    String? title,
    String? description,
    int? points,
    String? badgeName,
    String? type,
    int? displayOrder,
    bool? earned,
    int? earnedAt,
  }) {
    return TrackerAchievement(
      id: id ?? this.id,
      trackerType: trackerType ?? this.trackerType,
      trackerGameId: trackerGameId ?? this.trackerGameId,
      achievementId: achievementId ?? this.achievementId,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      badgeName: badgeName ?? this.badgeName,
      type: type ?? this.type,
      displayOrder: displayOrder ?? this.displayOrder,
      earned: earned ?? this.earned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }
}
