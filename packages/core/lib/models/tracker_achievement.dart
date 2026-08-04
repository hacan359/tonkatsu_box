
import 'tracker_profile.dart';

class TrackerAchievement {
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

  /// [json] is one value of the `Achievements` map in
  /// `GetGameInfoAndUserProgress`.
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

  final int id;

  final TrackerType trackerType;

  /// RA GameID or Steam AppID.
  final String trackerGameId;

  final String achievementId;

  final String title;

  final String? description;

  final int? points;

  final String? badgeName;

  /// RA type token: `missable`, `progression`, `win_condition`, or null.
  final String? type;

  final int displayOrder;

  final bool earned;

  final int? earnedAt;

  String? get badgeUrl => badgeName != null
      ? 'https://media.retroachievements.org/Badge/$badgeName.png'
      : null;

  String? get lockedBadgeUrl => badgeName != null
      ? 'https://media.retroachievements.org/Badge/${badgeName}_lock.png'
      : null;

  bool get isMissable => type == 'missable';

  bool get isProgression => type == 'progression';

  bool get isWinCondition => type == 'win_condition';

  DateTime? get earnedDateTime => earnedAt != null
      ? DateTime.fromMillisecondsSinceEpoch(earnedAt! * 1000)
      : null;

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
