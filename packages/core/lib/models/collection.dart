import 'exportable.dart';

enum CollectionType {
  own('own'),

  /// Imported from a shared file.
  imported('imported'),

  /// Editable fork of an imported collection.
  fork('fork');

  const CollectionType(this.value);

  /// Value stored in the database.
  final String value;

  static CollectionType fromString(String value) {
    return CollectionType.values.firstWhere(
      (CollectionType type) => type.value == value,
      orElse: () => CollectionType.own,
    );
  }
}

class Collection with Exportable {
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
    this.isHidden = false,
  });

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
      isHidden: (row['is_hidden'] as int?) == 1,
    );
  }

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

  final int id;

  final String name;

  final String author;

  final CollectionType type;

  final DateTime createdAt;

  /// Original collection snapshot; forks only.
  final String? originalSnapshot;

  /// Original author; forks only.
  final String? forkedFromAuthor;

  /// Original title; forks only.
  final String? forkedFromName;

  /// Path under `<appDocs>/`, e.g. `collections/hero_17.jpg`. Local, so it is
  /// absent from the JSON — the binary rides in `.xcollx` separately.
  final String? heroImagePath;

  /// Tagline for the rich hero.
  final String? description;

  /// Keeps the collection in the list but stops it from showing its content:
  /// no cover mosaic on the card, no items in the All Items selection.
  final bool isHidden;

  /// Always true — imported collections behave like ordinary ones.
  bool get isEditable => true;


  @override
  Set<String> get internalDbFields => const <String>{
        'id',
        'type',
        'original_snapshot',
        'forked_from_author',
        'forked_from_name',
        // The local path is not exported; the binary rides in the `.xcollx`
        // `images` section instead.
        'hero_image_path',
        // A local preference: the receiver of a shared collection has no
        // reason to inherit that it was hidden here.
        'is_hidden',
      };

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'created_at': 'created'};

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
      'is_hidden': isHidden ? 1 : 0,
    };
  }

  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'name': name,
      'author': author,
      'created': createdAt.toIso8601String(),
      'description': description,
    };
  }

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
    bool? isHidden,
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
      isHidden: isHidden ?? this.isHidden,
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
