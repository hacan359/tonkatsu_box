import 'dart:convert';

/// User profile with an isolated database and settings.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Unique identifier (slug or UUID); doubles as the profile folder name.
  final String id;

  final String name;

  /// Profile color as a hex string (e.g. '#EF7B44').
  final String color;

  final DateTime createdAt;

  String get folderName => id;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? name,
    String? color,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}

/// Contents of profiles.json: the profile list and the active profile id.
class ProfilesData {
  const ProfilesData({
    required this.version,
    required this.currentProfileId,
    required this.profiles,
  });

  factory ProfilesData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> profilesList = json['profiles'] as List<dynamic>;
    return ProfilesData(
      version: json['version'] as int,
      currentProfileId: json['currentProfileId'] as String,
      profiles: profilesList
          .map((dynamic p) =>
              Profile.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ProfilesData.fromJsonString(String jsonString) {
    return ProfilesData.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Initial data for the first launch.
  factory ProfilesData.defaultData({String authorName = 'Default'}) {
    return ProfilesData(
      version: 1,
      currentProfileId: 'default',
      profiles: <Profile>[
        Profile(
          id: 'default',
          name: authorName,
          color: '#EF7B44',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  /// Format version.
  final int version;

  final String currentProfileId;

  final List<Profile> profiles;

  /// Falls back to the first profile when [currentProfileId] is not found.
  Profile get currentProfile => profiles.firstWhere(
        (Profile p) => p.id == currentProfileId,
        orElse: () => profiles.first,
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'currentProfileId': currentProfileId,
      'profiles':
          profiles.map((Profile p) => p.toJson()).toList(),
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  ProfilesData copyWith({
    String? currentProfileId,
    List<Profile>? profiles,
  }) {
    return ProfilesData(
      version: version,
      currentProfileId: currentProfileId ?? this.currentProfileId,
      profiles: profiles ?? this.profiles,
    );
  }
}

/// Per-profile collection statistics.
class ProfileStats {
  const ProfileStats({
    required this.collectionsCount,
    required this.itemsCount,
  });

  static const ProfileStats empty = ProfileStats(
    collectionsCount: 0,
    itemsCount: 0,
  );

  final int collectionsCount;

  final int itemsCount;
}

/// Preset profile colors.
abstract final class ProfileColors {
  static const List<String> values = <String>[
    '#EF7B44', // Brand orange
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];
}
