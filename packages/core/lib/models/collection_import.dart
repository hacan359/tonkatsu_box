import 'dart:convert';

import 'import_source_kind.dart';

/// Keys of [CollectionImport.options]; credentials never go in there, they
/// stay in the settings store.
abstract final class CollectionImportOption {
  static const String mode = 'mode';
  static const String includeAnime = 'include_anime';
  static const String includeManga = 'include_manga';
  static const String addToWishlist = 'add_to_wishlist';
  static const String isWishlist = 'is_wishlist';
  static const String importNotes = 'import_notes';
  static const String status = 'status';
  static const String platformId = 'platform_id';
  static const String importWatched = 'import_watched';
  static const String importRatings = 'import_ratings';
  static const String importWatchlist = 'import_watchlist';
  static const String overwriteExisting = 'overwrite_existing';
}

/// The last run of one source into one collection, with the switches it was
/// started with, so the run can be repeated from the collection itself.
class CollectionImport {
  const CollectionImport({
    required this.collectionId,
    required this.source,
    required this.lastRunAt,
    this.options = const <String, Object?>{},
  });

  /// Throws [ArgumentError] on a source key this build does not know.
  factory CollectionImport.fromDb(Map<String, dynamic> row) {
    final String key = row['source'] as String;
    final ImportSourceKind? source = ImportSourceKind.tryFromKey(key);
    if (source == null) {
      throw ArgumentError.value(key, 'source', 'Unknown import source');
    }
    return CollectionImport(
      collectionId: row['collection_id'] as int,
      source: source,
      options: _decodeOptions(row['options']),
      lastRunAt: DateTime.fromMillisecondsSinceEpoch(
        (row['last_run_at'] as int) * 1000,
      ),
    );
  }

  final int collectionId;
  final ImportSourceKind source;
  final Map<String, Object?> options;
  final DateTime lastRunAt;

  bool flag(String key, {required bool orElse}) {
    final Object? value = options[key];
    return value is bool ? value : orElse;
  }

  String? text(String key) {
    final Object? value = options[key];
    return value is String ? value : null;
  }

  int? integer(String key) {
    final Object? value = options[key];
    return value is int ? value : null;
  }

  Map<String, dynamic> toDb() => <String, dynamic>{
    'collection_id': collectionId,
    'source': source.key,
    'options': jsonEncode(options),
    'last_run_at': lastRunAt.millisecondsSinceEpoch ~/ 1000,
  };

  CollectionImport copyWith({
    int? collectionId,
    ImportSourceKind? source,
    Map<String, Object?>? options,
    DateTime? lastRunAt,
  }) => CollectionImport(
    collectionId: collectionId ?? this.collectionId,
    source: source ?? this.source,
    options: options ?? this.options,
    lastRunAt: lastRunAt ?? this.lastRunAt,
  );

  // A hand-edited or truncated cell must not take the whole list down.
  static Map<String, Object?> _decodeOptions(Object? raw) {
    if (raw is! String || raw.isEmpty) return const <String, Object?>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      // fall through
    }
    return const <String, Object?>{};
  }
}
