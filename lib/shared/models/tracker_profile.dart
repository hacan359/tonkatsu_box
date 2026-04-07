// Модель профиля внешнего трекера (RA, Steam, Trakt).

import 'dart:convert';

/// Тип трекера.
enum TrackerType {
  /// RetroAchievements.
  ra('ra'),

  /// Steam.
  steam('steam'),

  /// Trakt.tv.
  trakt('trakt');

  const TrackerType(this.value);

  /// Строковое значение для БД.
  final String value;

  /// Создаёт [TrackerType] из строки.
  static TrackerType fromString(String value) {
    return TrackerType.values.firstWhere(
      (TrackerType t) => t.value == value,
      orElse: () => TrackerType.ra,
    );
  }
}

/// Профиль подключённого аккаунта трекера.
class TrackerProfile {
  /// Создаёт [TrackerProfile].
  const TrackerProfile({
    required this.id,
    required this.trackerType,
    required this.userId,
    required this.displayName,
    required this.createdAt,
    this.avatarUrl,
    this.profileUrl,
    this.totalPoints,
    this.totalGames,
    this.totalAchievements,
    this.memberSince,
    this.profileData,
    this.linkedCollectionId,
    this.lastSyncedAt,
  });

  /// Создаёт [TrackerProfile] из записи БД.
  factory TrackerProfile.fromDb(Map<String, dynamic> row) {
    final String? dataString = row['profile_data'] as String?;
    Map<String, dynamic>? parsedData;
    if (dataString != null && dataString.isNotEmpty) {
      parsedData = json.decode(dataString) as Map<String, dynamic>;
    }

    return TrackerProfile(
      id: row['id'] as int,
      trackerType: TrackerType.fromString(row['tracker_type'] as String),
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      profileUrl: row['profile_url'] as String?,
      totalPoints: row['total_points'] as int?,
      totalGames: row['total_games'] as int?,
      totalAchievements: row['total_achievements'] as int?,
      memberSince: row['member_since'] as int?,
      profileData: parsedData,
      linkedCollectionId: row['linked_collection_id'] as int?,
      lastSyncedAt: row['last_synced_at'] as int?,
      createdAt: row['created_at'] as int,
    );
  }

  /// Уникальный ID.
  final int id;

  /// Тип трекера.
  final TrackerType trackerType;

  /// ID пользователя в трекере (RA username, Steam ID).
  final String userId;

  /// Отображаемое имя.
  final String displayName;

  /// URL аватарки.
  final String? avatarUrl;

  /// URL профиля.
  final String? profileUrl;

  /// Общие очки (RA points, Steam XP).
  final int? totalPoints;

  /// Количество игр в библиотеке.
  final int? totalGames;

  /// Общее количество полученных достижений.
  final int? totalAchievements;

  /// Timestamp регистрации.
  final int? memberSince;

  /// JSON с трекер-специфичными данными.
  final Map<String, dynamic>? profileData;

  /// ID коллекции для sync.
  final int? linkedCollectionId;

  /// Timestamp последнего sync.
  final int? lastSyncedAt;

  /// Timestamp создания записи.
  final int createdAt;

  /// Преобразует в Map для сохранения в БД.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'tracker_type': trackerType.value,
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'profile_url': profileUrl,
      'total_points': totalPoints,
      'total_games': totalGames,
      'total_achievements': totalAchievements,
      'member_since': memberSince,
      'profile_data': profileData != null ? json.encode(profileData) : null,
      'linked_collection_id': linkedCollectionId,
      'last_synced_at': lastSyncedAt,
      'created_at': createdAt,
    };
  }

  /// Создаёт копию с изменёнными полями.
  TrackerProfile copyWith({
    int? id,
    TrackerType? trackerType,
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? profileUrl,
    int? totalPoints,
    int? totalGames,
    int? totalAchievements,
    int? memberSince,
    Map<String, dynamic>? profileData,
    int? linkedCollectionId,
    int? lastSyncedAt,
    int? createdAt,
  }) {
    return TrackerProfile(
      id: id ?? this.id,
      trackerType: trackerType ?? this.trackerType,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileUrl: profileUrl ?? this.profileUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      totalGames: totalGames ?? this.totalGames,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      memberSince: memberSince ?? this.memberSince,
      profileData: profileData ?? this.profileData,
      linkedCollectionId: linkedCollectionId ?? this.linkedCollectionId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
