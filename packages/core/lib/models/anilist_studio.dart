/// A studio as returned by AniList's `studios(search:)`; never persisted, the
/// studio filter stores the name only.
class AniListStudio {
  const AniListStudio({
    required this.id,
    required this.name,
    this.isAnimationStudio = true,
  });

  factory AniListStudio.fromJson(Map<String, dynamic> json) => AniListStudio(
    id: json['id'] as int,
    name: json['name'] as String,
    isAnimationStudio: json['isAnimationStudio'] as bool? ?? true,
  );

  final int id;
  final String name;

  /// AniList lists producers and licensors as studios too; the filter only
  /// offers the ones that actually animate.
  final bool isAnimationStudio;
}
