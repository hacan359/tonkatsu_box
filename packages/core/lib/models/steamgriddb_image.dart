/// Covers grids, heroes, logos and icons alike — SteamGridDB returns the same
/// shape from `/grids`, `/heroes`, `/logos` and `/icons`.
class SteamGridDbImage {
  const SteamGridDbImage({
    required this.id,
    required this.score,
    required this.style,
    required this.url,
    required this.thumb,
    required this.width,
    required this.height,
    this.mime,
    this.author,
  });

  factory SteamGridDbImage.fromJson(Map<String, dynamic> json) {
    String? author;
    if (json['author'] != null) {
      final Map<String, dynamic> authorMap =
          json['author'] as Map<String, dynamic>;
      author = authorMap['name'] as String?;
    }

    return SteamGridDbImage(
      id: json['id'] as int,
      score: json['score'] as int,
      style: json['style'] as String,
      url: json['url'] as String,
      thumb: json['thumb'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      mime: json['mime'] as String?,
      author: author,
    );
  }

  final int id;

  /// Community vote score.
  final int score;

  /// SteamGridDB style token, e.g. `alternate`, `blurred`, `material`.
  final String style;

  final String url;

  final String thumb;

  final int width;

  final int height;

  /// MIME type, e.g. `image/png`.
  final String? mime;

  final String? author;

  String get dimensions => '${width}x$height';

  SteamGridDbImage copyWith({
    int? id,
    int? score,
    String? style,
    String? url,
    String? thumb,
    int? width,
    int? height,
    String? mime,
    String? author,
  }) {
    return SteamGridDbImage(
      id: id ?? this.id,
      score: score ?? this.score,
      style: style ?? this.style,
      url: url ?? this.url,
      thumb: thumb ?? this.thumb,
      width: width ?? this.width,
      height: height ?? this.height,
      mime: mime ?? this.mime,
      author: author ?? this.author,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SteamGridDbImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SteamGridDbImage(id: $id, style: $style, $dimensions)';
}
