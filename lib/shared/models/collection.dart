import 'exportable.dart';

/// Тип коллекции.
enum CollectionType {
  /// Собственная коллекция пользователя.
  own('own'),

  /// Импортированная коллекция (только для чтения).
  imported('imported'),

  /// Форк импортированной коллекции (редактируемый).
  fork('fork');

  const CollectionType(this.value);

  /// Строковое значение для базы данных.
  final String value;

  /// Создаёт [CollectionType] из строки.
  static CollectionType fromString(String value) {
    return CollectionType.values.firstWhere(
      (CollectionType type) => type.value == value,
      orElse: () => CollectionType.own,
    );
  }
}

/// Модель коллекции игр.
///
/// Представляет коллекцию игр пользователя с метаданными.
class Collection with Exportable {
  /// Создаёт экземпляр [Collection].
  const Collection({
    required this.id,
    required this.name,
    required this.author,
    required this.type,
    required this.createdAt,
    this.originalSnapshot,
    this.forkedFromAuthor,
    this.forkedFromName,
    this.heroImagePath,
    this.description,
  });

  /// Создаёт [Collection] из записи базы данных.
  factory Collection.fromDb(Map<String, dynamic> row) {
    return Collection(
      id: row['id'] as int,
      name: row['name'] as String,
      author: row['author'] as String,
      type: CollectionType.fromString(row['type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
      originalSnapshot: row['original_snapshot'] as String?,
      forkedFromAuthor: row['forked_from_author'] as String?,
      forkedFromName: row['forked_from_name'] as String?,
      heroImagePath: row['hero_image_path'] as String?,
      description: row['description'] as String?,
    );
  }

  /// Создаёт [Collection] из экспортных данных.
  factory Collection.fromExport(
    Map<String, dynamic> json, {
    int id = 0,
    CollectionType type = CollectionType.imported,
  }) {
    return Collection(
      id: id,
      name: json['name'] as String,
      author: json['author'] as String,
      type: type,
      createdAt: DateTime.parse(json['created'] as String),
      description: json['description'] as String?,
    );
  }

  /// Уникальный идентификатор коллекции.
  final int id;

  /// Название коллекции.
  final String name;

  /// Автор коллекции.
  final String author;

  /// Тип коллекции.
  final CollectionType type;

  /// Дата создания.
  final DateTime createdAt;

  /// Снимок оригинальной коллекции (для форков).
  final String? originalSnapshot;

  /// Автор оригинальной коллекции (для форков).
  final String? forkedFromAuthor;

  /// Название оригинальной коллекции (для форков).
  final String? forkedFromName;

  /// Относительный путь к hero-изображению в `<appDocs>/`.
  ///
  /// Например: `collections/hero_17.jpg`. Путь локальный — не экспортируется
  /// в JSON; бинарник вкладывается в `.xcollx` отдельно.
  final String? heroImagePath;

  /// Краткое описание коллекции (tagline для rich hero).
  final String? description;

  /// Возвращает true, если коллекция редактируемая.
  ///
  /// Все коллекции редактируемые (импортированные ведут себя как обычные).
  bool get isEditable => true;

  // -- Exportable контракт --

  @override
  Set<String> get internalDbFields => const <String>{
        'id',
        'type',
        'original_snapshot',
        'forked_from_author',
        'forked_from_name',
        // Локальный путь картинки не экспортируется: сам бинарник
        // вкладывается в секцию `images` .xcollx отдельно.
        'hero_image_path',
      };

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'created_at': 'created'};

  /// Преобразует в Map для сохранения в базу данных.
  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'author': author,
      'type': type.value,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'original_snapshot': originalSnapshot,
      'forked_from_author': forkedFromAuthor,
      'forked_from_name': forkedFromName,
      'hero_image_path': heroImagePath,
      'description': description,
    };
  }

  /// Преобразует в Map для экспорта.
  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'name': name,
      'author': author,
      'created': createdAt.toIso8601String(),
      'description': description,
    };
  }

  /// Создаёт копию с изменёнными полями.
  Collection copyWith({
    int? id,
    String? name,
    String? author,
    CollectionType? type,
    DateTime? createdAt,
    String? originalSnapshot,
    String? forkedFromAuthor,
    String? forkedFromName,
    String? heroImagePath,
    String? description,
    bool clearHeroImage = false,
    bool clearDescription = false,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      originalSnapshot: originalSnapshot ?? this.originalSnapshot,
      forkedFromAuthor: forkedFromAuthor ?? this.forkedFromAuthor,
      forkedFromName: forkedFromName ?? this.forkedFromName,
      heroImagePath:
          clearHeroImage ? null : (heroImagePath ?? this.heroImagePath),
      description: clearDescription ? null : (description ?? this.description),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Collection(id: $id, name: $name, type: ${type.value})';
}
