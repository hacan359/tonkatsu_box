// Профиль пользователя RetroAchievements.

/// Профиль пользователя RetroAchievements.
class RaUserProfile {
  /// Создаёт [RaUserProfile].
  const RaUserProfile({
    required this.user,
    required this.totalPoints,
    required this.memberSince,
    this.userPic,
    this.richPresenceMsg,
    this.totalTruePoints = 0,
    this.lastGameId,
  });

  /// Создаёт [RaUserProfile] из JSON ответа API.
  factory RaUserProfile.fromJson(Map<String, dynamic> json) {
    return RaUserProfile(
      user: json['User'] as String? ?? '',
      totalPoints: json['TotalPoints'] as int? ?? 0,
      memberSince: json['MemberSince'] as String? ?? '',
      userPic: json['UserPic'] as String?,
      richPresenceMsg: json['RichPresenceMsg'] as String?,
      totalTruePoints: json['TotalTruePoints'] as int? ?? 0,
      lastGameId: json['LastGameID'] as int?,
    );
  }

  /// Имя пользователя.
  final String user;

  /// Общее количество очков (softcore + hardcore).
  final int totalPoints;

  /// Дата регистрации (строка, напр. "2024-03-15 11:27:24").
  final String memberSince;

  /// Путь к аватарке (напр. "/UserPic/Hacan359.png").
  final String? userPic;

  /// Rich Presence — текущая активность.
  final String? richPresenceMsg;

  /// True Points (hardcore weighted).
  final int totalTruePoints;

  /// ID последней запущенной игры на RetroAchievements.
  final int? lastGameId;

  /// Полный URL аватарки.
  String? get userPicUrl =>
      userPic != null ? 'https://retroachievements.org$userPic' : null;
}
