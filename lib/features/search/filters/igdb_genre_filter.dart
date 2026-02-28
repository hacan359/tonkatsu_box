// Фильтр жанров IGDB — свой набор жанров для игр.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';
import '../providers/igdb_genre_provider.dart';

/// Модель жанра IGDB.
class IgdbGenre {
  /// Создаёт [IgdbGenre].
  const IgdbGenre({required this.id, required this.name});

  /// Создаёт [IgdbGenre] из JSON ответа IGDB API.
  factory IgdbGenre.fromJson(Map<String, dynamic> json) {
    return IgdbGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  /// ID жанра.
  final int id;

  /// Название жанра.
  final String name;
}

/// Фильтр жанров IGDB.
///
/// Загружает жанры из IGDB API через [igdbGenresProvider].
class IgdbGenreFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => '${key}_igdb';

  @override
  String placeholder(S l) => l.browseFilterGenre;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    final List<IgdbGenre> genres =
        await ref.read(igdbGenresProvider.future);
    return genres
        .map(
          (IgdbGenre g) => FilterOption(
            id: g.id.toString(),
            label: g.name,
            value: g.id,
          ),
        )
        .toList();
  }
}
