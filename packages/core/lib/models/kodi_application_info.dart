/// Feeds the human-readable line in "Test connection" and the Kodi debug
/// panel: «Connected (Kodi 21.0 "Omega" on Living Room HTPC)».
class KodiApplicationInfo {
  const KodiApplicationInfo({
    required this.versionMajor,
    required this.versionMinor,
    this.versionTag,
    this.name,
  });

  /// Reads `{"version": {"major": 21, "minor": 0, "tag": "stable"},
  /// "name": "Kodi"}`.
  factory KodiApplicationInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? version =
        json['version'] as Map<String, dynamic>?;
    return KodiApplicationInfo(
      versionMajor: (version?['major'] as int?) ?? 0,
      versionMinor: (version?['minor'] as int?) ?? 0,
      versionTag: version?['tag'] as String?,
      name: json['name'] as String?,
    );
  }

  /// Major version, e.g. 21 for "Omega".
  final int versionMajor;

  final int versionMinor;

  /// Build tag: `stable`, `beta`, `alpha`, `releasecandidate`, `prealpha`.
  final String? versionTag;

  /// Instance name, usually `Kodi` but may be customised.
  final String? name;

  String get versionString {
    final String base = '$versionMajor.$versionMinor';
    if (versionTag == null || versionTag == 'stable') return base;
    return '$base $versionTag';
  }
}
