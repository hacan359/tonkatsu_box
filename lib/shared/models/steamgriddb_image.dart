// Модель изображения из SteamGridDB API.

/// Изображение из SteamGridDB (grid, hero, logo или icon).
///
/// Используется для всех типов изображений, так как структура ответа
/// одинаковая для эндпоинтов `/grids`, `/heroes`, `/logos`, `/icons`.
class SteamGridDbImage {
  /// Создаёт экземпляр [SteamGridDbImage].
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

  /// Создаёт [SteamGridDbImage] из JSON ответа SteamGridDB API.
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

  /// Уникальный идентификатор изображения.
  final int id;

  /// Оценка (голоса сообщества).
  final int score;

  /// Визуальный стиль (например, "alternate", "blurred", "material").
  final String style;

  /// URL полноразмерного изображения.
  final String url;

  /// URL превью изображения.
  final String thumb;

  /// Ширина в пикселях.
  final int width;

  /// Высота в пикселях.
  final int height;

  /// MIME-тип (например, "image/png", "image/jpeg").
  final String? mime;

  /// Имя автора изображения.
  final String? author;

  /// Возвращает строку размера в формате "WxH".
  String get dimensions => '${width}x$height';

  /// Создаёт копию с изменёнными полями.
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
