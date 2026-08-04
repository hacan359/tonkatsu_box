
class RaUserProfile {
  const RaUserProfile({
    required this.user,
    required this.totalPoints,
    required this.memberSince,
    this.userPic,
    this.richPresenceMsg,
    this.totalTruePoints = 0,
    this.lastGameId,
  });

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

  final String user;

  /// Softcore and hardcore combined.
  final int totalPoints;

  /// RA sends a string, e.g. `2024-03-15 11:27:24`.
  final String memberSince;

  /// Path only, e.g. `/UserPic/Hacan359.png`.
  final String? userPic;

  final String? richPresenceMsg;

  /// True Points (hardcore weighted).
  final int totalTruePoints;

  final int? lastGameId;

  String? get userPicUrl =>
      userPic != null ? 'https://retroachievements.org$userPic' : null;
}
