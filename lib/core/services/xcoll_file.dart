// Модель файла экспорта/импорта коллекций (.xcoll, .xcollx).

import 'dart:convert';

/// Текущая версия формата.
const int xcollFormatVersion = 2;

/// Режим экспорта.
enum ExportFormat {
  /// Лёгкий экспорт — только метаданные и ID элементов.
  light('light'),

  /// Полный экспорт — метаданные + canvas + base64 images.
  full('full');

  const ExportFormat(this.value);

  /// Строковое значение для файла.
  final String value;

  /// Создаёт [ExportFormat] из строки.
  static ExportFormat fromString(String value) {
    return ExportFormat.values.firstWhere(
      (ExportFormat f) => f.value == value,
      orElse: () => ExportFormat.light,
    );
  }
}

/// Контейнер данных канваса для экспорта.
///
/// Содержит viewport, элементы и связи канваса.
class ExportCanvas {
  /// Создаёт экземпляр [ExportCanvas].
  const ExportCanvas({
    this.viewport,
    this.items = const <Map<String, dynamic>>[],
    this.connections = const <Map<String, dynamic>>[],
  });

  /// Создаёт [ExportCanvas] из JSON.
  factory ExportCanvas.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawConnections =
        json['connections'] as List<dynamic>? ?? <dynamic>[];

    return ExportCanvas(
      viewport: json['viewport'] as Map<String, dynamic>?,
      items: rawItems
          .map((dynamic item) => item as Map<String, dynamic>)
          .toList(),
      connections: rawConnections
          .map((dynamic conn) => conn as Map<String, dynamic>)
          .toList(),
    );
  }

  /// Данные viewport.
  final Map<String, dynamic>? viewport;

  /// Элементы канваса.
  final List<Map<String, dynamic>> items;

  /// Связи между элементами.
  final List<Map<String, dynamic>> connections;

  /// Преобразует в JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (viewport != null) 'viewport': viewport,
      'items': items,
      'connections': connections,
    };
  }
}

/// Модель файла экспорта/импорта коллекций.
///
/// Форматы файлов:
/// - `.xcoll` — лёгкий экспорт (метаданные + ID элементов)
/// - `.xcollx` — полный экспорт (+ canvas + base64 images)
class XcollFile {
  /// Создаёт экземпляр [XcollFile].
  const XcollFile({
    required this.version,
    required this.name,
    required this.author,
    required this.created,
    this.format = ExportFormat.light,
    this.description,
    this.items = const <Map<String, dynamic>>[],
    this.canvas,
    this.images = const <String, String>{},
  });

  /// Создаёт [XcollFile] из JSON строки.
  ///
  /// Автоматически определяет версию формата (v1 или v2).
  /// Throws [FormatException] если JSON невалидный.
  factory XcollFile.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return XcollFile.fromJson(json);
    } on FormatException {
      throw const FormatException('Invalid JSON format');
    } on TypeError catch (e) {
      throw FormatException('Invalid file structure: $e');
    }
  }

  /// Создаёт [XcollFile] из JSON Map.
  ///
  /// Throws [FormatException] если версия файла не поддерживается.
  factory XcollFile.fromJson(Map<String, dynamic> json) {
    final int version = json['version'] as int? ?? 1;

    if (version < xcollFormatVersion) {
      throw FormatException(
        'Unsupported file version: $version. '
        'Minimum supported: $xcollFormatVersion',
      );
    }

    if (version > xcollFormatVersion) {
      throw FormatException(
        'Unsupported file version: $version. '
        'Maximum supported: $xcollFormatVersion',
      );
    }

    final String name = json['name'] as String? ?? 'Unnamed Collection';
    final String author = json['author'] as String? ?? 'Unknown';
    final String? description = json['description'] as String?;
    final DateTime created = _parseCreatedDate(json['created']);

    return _parseV2(json, name, author, created, description);
  }

  /// Парсит v2 формат (.xcoll / .xcollx).
  static XcollFile _parseV2(
    Map<String, dynamic> json,
    String name,
    String author,
    DateTime created,
    String? description,
  ) {
    final ExportFormat format =
        ExportFormat.fromString(json['format'] as String? ?? 'light');

    // Items
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> items = rawItems
        .map((dynamic item) => item as Map<String, dynamic>)
        .toList();

    // Canvas (optional, full export only)
    ExportCanvas? canvas;
    final Map<String, dynamic>? canvasJson =
        json['canvas'] as Map<String, dynamic>?;
    if (canvasJson != null) {
      canvas = ExportCanvas.fromJson(canvasJson);
    }

    // Images (optional, full export only)
    final Map<String, dynamic>? rawImages =
        json['images'] as Map<String, dynamic>?;
    final Map<String, String> images = rawImages != null
        ? rawImages
            .map((String key, dynamic value) =>
                MapEntry<String, String>(key, value as String))
        : const <String, String>{};

    return XcollFile(
      version: 2,
      format: format,
      name: name,
      author: author,
      created: created,
      description: description,
      items: items,
      canvas: canvas,
      images: images,
    );
  }

  /// Парсит дату создания из строки или null.
  static DateTime _parseCreatedDate(Object? value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } on FormatException {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Версия формата.
  final int version;

  /// Режим экспорта (light / full).
  final ExportFormat format;

  /// Название коллекции.
  final String name;

  /// Автор коллекции.
  final String author;

  /// Дата создания.
  final DateTime created;

  /// Описание коллекции (опционально).
  final String? description;

  // -- v2 поля --

  /// Элементы коллекции (v2).
  final List<Map<String, dynamic>> items;

  /// Данные канваса коллекции (только full export).
  final ExportCanvas? canvas;

  /// Base64-изображения обложек (только full export).
  ///
  /// Ключ — '{ImageType.folder}/{externalId}' (например, 'game_covers/12345').
  /// Значение — base64-строка изображения.
  final Map<String, String> images;

  /// Является ли полным экспортом.
  bool get isFull => format == ExportFormat.full;

  /// Преобразует в JSON Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'format': format.value,
      'name': name,
      'author': author,
      'created': created.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      'items': items,
      if (canvas != null) 'canvas': canvas!.toJson(),
      if (images.isNotEmpty) 'images': images,
    };
  }

  /// Преобразует в JSON строку с форматированием.
  String toJsonString() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
