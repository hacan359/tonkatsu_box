// Модель визуальной новеллы из VNDB.

import 'dart:convert';

/// Модель визуальной новеллы из VNDB API.
///
/// Представляет визуальную новеллу с метаданными из VNDB.
class VisualNovel {
  /// Создаёт экземпляр [VisualNovel].
  const VisualNovel({
    required this.id,
    required this.title,
    this.altTitle,
    this.description,
    this.imageUrl,
    this.rating,
    this.voteCount,
    this.released,
    this.lengthMinutes,
    this.length,
    this.tags,
    this.developers,
    this.platforms,
    this.externalUrl,
    this.updatedAt,
  });

  /// Создаёт [VisualNovel] из JSON ответа VNDB API.
  factory VisualNovel.fromJson(Map<String, dynamic> json) {
    // Извлекаем URL обложки из вложенного объекта image
    String? imageUrl;
    if (json['image'] != null) {
      final Map<String, dynamic> image =
          json['image'] as Map<String, dynamic>;
      imageUrl = image['url'] as String?;
    }

    // Извлекаем теги (только имена, сортируем по rating)
    List<String>? tags;
    if (json['tags'] != null) {
      final List<dynamic> tagsList = json['tags'] as List<dynamic>;
      // Сортируем по rating (убывание) и берём имена
      final List<Map<String, dynamic>> sortedTags = tagsList
          .map((dynamic t) => t as Map<String, dynamic>)
          .toList()
        ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            ((b['rating'] as num?) ?? 0)
                .compareTo((a['rating'] as num?) ?? 0));
      tags = sortedTags
          .where((Map<String, dynamic> t) => t['name'] != null)
          .map((Map<String, dynamic> t) => t['name'] as String)
          .toList();
    }

    // Извлекаем разработчиков
    List<String>? developers;
    if (json['developers'] != null) {
      final List<dynamic> devList = json['developers'] as List<dynamic>;
      developers = devList
          .map((dynamic d) => d as Map<String, dynamic>)
          .where((Map<String, dynamic> d) => d['name'] != null)
          .map((Map<String, dynamic> d) => d['name'] as String)
          .toList();
    }

    // Извлекаем платформы
    List<String>? platforms;
    if (json['platforms'] != null) {
      final List<dynamic> platList = json['platforms'] as List<dynamic>;
      platforms = platList.map((dynamic p) => p as String).toList();
    }

    final String id = json['id'] as String;

    return VisualNovel(
      id: id,
      title: json['title'] as String,
      altTitle: json['alttitle'] as String?,
      description: _cleanDescription(json['description'] as String?),
      imageUrl: imageUrl,
      rating: (json['rating'] as num?)?.toDouble(),
      voteCount: json['votecount'] as int?,
      released: json['released'] as String?,
      lengthMinutes: json['length_minutes'] as int?,
      length: json['length'] as int?,
      tags: tags,
      developers: developers,
      platforms: platforms,
      externalUrl: 'https://vndb.org/$id',
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Создаёт [VisualNovel] из записи базы данных.
  factory VisualNovel.fromDb(Map<String, dynamic> row) {
    List<String>? tags;
    if (row['tags'] != null && (row['tags'] as String).isNotEmpty) {
      try {
        tags = (jsonDecode(row['tags'] as String) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
      } on FormatException {
        tags = null;
      }
    }

    List<String>? developers;
    if (row['developers'] != null &&
        (row['developers'] as String).isNotEmpty) {
      try {
        developers =
            (jsonDecode(row['developers'] as String) as List<dynamic>)
                .map((dynamic e) => e as String)
                .toList();
      } on FormatException {
        developers = null;
      }
    }

    List<String>? platforms;
    if (row['platforms'] != null &&
        (row['platforms'] as String).isNotEmpty) {
      try {
        platforms =
            (jsonDecode(row['platforms'] as String) as List<dynamic>)
                .map((dynamic e) => e as String)
                .toList();
      } on FormatException {
        platforms = null;
      }
    }

    return VisualNovel(
      id: row['id'] as String,
      title: row['title'] as String,
      altTitle: row['alt_title'] as String?,
      description: row['description'] as String?,
      imageUrl: row['image_url'] as String?,
      rating: row['rating'] as double?,
      voteCount: row['vote_count'] as int?,
      released: row['released'] as String?,
      lengthMinutes: row['length_minutes'] as int?,
      length: row['length'] as int?,
      tags: tags,
      developers: developers,
      platforms: platforms,
      externalUrl: row['external_url'] as String?,
      updatedAt: row['updated_at'] as int?,
    );
  }

  /// Уникальный идентификатор новеллы в VNDB (например "v2").
  final String id;

  /// Название новеллы.
  final String title;

  /// Альтернативное название (обычно оригинальное японское).
  final String? altTitle;

  /// Описание новеллы.
  final String? description;

  /// URL обложки.
  final String? imageUrl;

  /// Рейтинг VNDB (0-100).
  final double? rating;

  /// Количество голосов.
  final int? voteCount;

  /// Дата релиза ("2009-10-15" или partial "2024").
  final String? released;

  /// Время прохождения в минутах.
  final int? lengthMinutes;

  /// Категория длительности (1-5).
  final int? length;

  /// Список тегов (жанров).
  final List<String>? tags;

  /// Список разработчиков.
  final List<String>? developers;

  /// Список платформ (коды: "win", "ps3" и т.д.).
  final List<String>? platforms;

  /// URL страницы на VNDB.
  final String? externalUrl;

  /// Время кеширования (Unix timestamp).
  final int? updatedAt;

  /// Числовой ID для хранения в collection_items.external_id.
  int get numericId {
    final int? parsed = int.tryParse(id.replaceFirst('v', ''));
    if (parsed == null) {
      throw FormatException('Invalid VNDB id format: $id');
    }
    return parsed;
  }

  /// Рейтинг в шкале 0-10.
  double? get rating10 => rating != null ? rating! / 10 : null;

  /// Форматированный рейтинг (0-10).
  String? get formattedRating {
    if (rating10 == null) return null;
    return rating10!.toStringAsFixed(1);
  }

  /// Год релиза.
  int? get releaseYear {
    if (released == null || released!.length < 4) return null;
    return int.tryParse(released!.substring(0, 4));
  }

  /// Теги в виде строки через запятую.
  String? get genresString => tags?.join(', ');

  /// Человекочитаемая метка длительности.
  String? get lengthLabel => switch (length) {
        1 => '< 2h',
        2 => '2-10h',
        3 => '10-30h',
        4 => '30-50h',
        5 => '> 50h',
        _ => null,
      };

  /// Разработчики в виде строки через запятую.
  String? get developersString => developers?.join(', ');

  /// Платформы в виде строки через запятую.
  String? get platformsString =>
      platforms?.map(_platformLabel).join(', ');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisualNovel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VisualNovel(id: $id, title: $title)';

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'numeric_id': numericId,
      'title': title,
      'alt_title': altTitle,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'vote_count': voteCount,
      'released': released,
      'length_minutes': lengthMinutes,
      'length': length,
      'tags': tags != null ? jsonEncode(tags) : null,
      'developers': developers != null ? jsonEncode(developers) : null,
      'platforms': platforms != null ? jsonEncode(platforms) : null,
      'external_url': externalUrl,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в Map для экспорта коллекции.
  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('updated_at');
    return data;
  }

  /// Создаёт копию с изменёнными полями.
  VisualNovel copyWith({
    String? id,
    String? title,
    String? altTitle,
    String? description,
    String? imageUrl,
    double? rating,
    int? voteCount,
    String? released,
    int? lengthMinutes,
    int? length,
    List<String>? tags,
    List<String>? developers,
    List<String>? platforms,
    String? externalUrl,
    int? updatedAt,
  }) {
    return VisualNovel(
      id: id ?? this.id,
      title: title ?? this.title,
      altTitle: altTitle ?? this.altTitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      voteCount: voteCount ?? this.voteCount,
      released: released ?? this.released,
      lengthMinutes: lengthMinutes ?? this.lengthMinutes,
      length: length ?? this.length,
      tags: tags ?? this.tags,
      developers: developers ?? this.developers,
      platforms: platforms ?? this.platforms,
      externalUrl: externalUrl ?? this.externalUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final RegExp _urlPattern = RegExp(r'\[url=[^\]]*\]');
  static final RegExp _boldPattern = RegExp(r'\[b\]|\[/b\]');
  static final RegExp _italicPattern = RegExp(r'\[i\]|\[/i\]');

  /// Убирает VNDB-специфичную разметку из описания.
  static String? _cleanDescription(String? description) {
    if (description == null) return null;
    // VNDB использует [url=...]text[/url] и [spoiler]...[/spoiler]
    String clean = description;
    clean = clean.replaceAll(_urlPattern, '');
    clean = clean.replaceAll('[/url]', '');
    clean = clean.replaceAll('[spoiler]', '');
    clean = clean.replaceAll('[/spoiler]', '');
    clean = clean.replaceAll(_boldPattern, '');
    clean = clean.replaceAll(_italicPattern, '');
    clean = clean.trim();
    return clean.isEmpty ? null : clean;
  }

  /// Человекочитаемая метка платформы VNDB.
  static String _platformLabel(String code) => switch (code) {
        'win' => 'Windows',
        'lin' => 'Linux',
        'mac' => 'macOS',
        'and' => 'Android',
        'ios' => 'iOS',
        'swi' => 'Switch',
        'ps3' => 'PS3',
        'ps4' => 'PS4',
        'ps5' => 'PS5',
        'psv' => 'PS Vita',
        'psp' => 'PSP',
        'xb1' => 'Xbox One',
        'xbs' => 'Xbox Series',
        'web' => 'Web',
        'drc' => 'Dreamcast',
        'nes' => 'NES',
        'sfc' => 'SNES',
        'n64' => 'N64',
        'gba' => 'GBA',
        'nds' => 'NDS',
        'wii' => 'Wii',
        'p88' => 'PC-88',
        'p98' => 'PC-98',
        'x68' => 'X68000',
        'msx' => 'MSX',
        'sat' => 'Saturn',
        'ps1' => 'PS1',
        'ps2' => 'PS2',
        _ => code.toUpperCase(),
      };
}

/// Тег (жанр) VNDB.
class VndbTag {
  /// Создаёт экземпляр [VndbTag].
  const VndbTag({
    required this.id,
    required this.name,
  });

  /// Создаёт [VndbTag] из JSON ответа VNDB API.
  factory VndbTag.fromJson(Map<String, dynamic> json) {
    return VndbTag(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  /// Создаёт [VndbTag] из записи базы данных.
  factory VndbTag.fromDb(Map<String, dynamic> row) {
    return VndbTag(
      id: row['id'] as String,
      name: row['name'] as String,
    );
  }

  /// Уникальный идентификатор тега (например "g7").
  final String id;

  /// Название тега.
  final String name;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VndbTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VndbTag(id: $id, name: $name)';
}
