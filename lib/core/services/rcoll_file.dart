import 'dart:convert';

/// Версия формата .rcoll файла.
const int rcollFormatVersion = 1;

/// Игра в .rcoll файле.
class RcollGame {
  /// Создаёт экземпляр [RcollGame].
  const RcollGame({
    required this.igdbId,
    required this.platformId,
    this.comment,
  });

  /// Создаёт [RcollGame] из JSON.
  factory RcollGame.fromJson(Map<String, dynamic> json) {
    return RcollGame(
      igdbId: json['igdb_id'] as int,
      platformId: json['platform_id'] as int,
      comment: json['comment'] as String?,
    );
  }

  /// ID игры в IGDB.
  final int igdbId;

  /// ID платформы.
  final int platformId;

  /// Комментарий автора.
  final String? comment;

  /// Преобразует в JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'igdb_id': igdbId,
      'platform_id': platformId,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}

/// Модель .rcoll файла для экспорта/импорта коллекций.
///
/// Формат файла:
/// ```json
/// {
///   "version": 1,
///   "name": "Collection Name",
///   "author": "username",
///   "created": "2025-02-02T12:00:00Z",
///   "description": null,
///   "games": [
///     {"igdb_id": 1234, "platform_id": 19, "comment": "..."}
///   ]
/// }
/// ```
class RcollFile {
  /// Создаёт экземпляр [RcollFile].
  const RcollFile({
    required this.version,
    required this.name,
    required this.author,
    required this.created,
    required this.games,
    this.description,
  });

  /// Создаёт [RcollFile] из JSON строки.
  ///
  /// Throws [FormatException] если JSON невалидный.
  factory RcollFile.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return RcollFile.fromJson(json);
    } on FormatException {
      throw const FormatException('Invalid JSON format');
    } on TypeError catch (e) {
      throw FormatException('Invalid .rcoll structure: $e');
    }
  }

  /// Создаёт [RcollFile] из JSON Map.
  factory RcollFile.fromJson(Map<String, dynamic> json) {
    final int version = json['version'] as int? ?? 1;

    if (version > rcollFormatVersion) {
      throw FormatException(
        'Unsupported .rcoll version: $version. '
        'Maximum supported: $rcollFormatVersion',
      );
    }

    final String name = json['name'] as String? ?? 'Unnamed Collection';
    final String author = json['author'] as String? ?? 'Unknown';
    final String? createdString = json['created'] as String?;
    DateTime created;
    if (createdString != null) {
      try {
        created = DateTime.parse(createdString);
      } on FormatException {
        created = DateTime.now();
      }
    } else {
      created = DateTime.now();
    }
    final String? description = json['description'] as String?;

    final List<dynamic> gamesJson = json['games'] as List<dynamic>? ?? <dynamic>[];
    final List<RcollGame> games = gamesJson
        .map((dynamic g) => RcollGame.fromJson(g as Map<String, dynamic>))
        .toList();

    return RcollFile(
      version: version,
      name: name,
      author: author,
      created: created,
      description: description,
      games: games,
    );
  }

  /// Версия формата.
  final int version;

  /// Название коллекции.
  final String name;

  /// Автор коллекции.
  final String author;

  /// Дата создания.
  final DateTime created;

  /// Описание коллекции (опционально).
  final String? description;

  /// Список игр.
  final List<RcollGame> games;

  /// Возвращает список IGDB ID всех игр.
  List<int> get gameIds => games.map((RcollGame g) => g.igdbId).toList();

  /// Преобразует в JSON Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'name': name,
      'author': author,
      'created': created.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      'games': games.map((RcollGame g) => g.toJson()).toList(),
    };
  }

  /// Преобразует в JSON строку с форматированием.
  String toJsonString() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
