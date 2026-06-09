import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';
import '../providers/igdb_genre_provider.dart';

class IgdbGenre {
  const IgdbGenre({required this.id, required this.name});

  /// From an IGDB API JSON object.
  factory IgdbGenre.fromJson(Map<String, dynamic> json) {
    return IgdbGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

/// IGDB genres, loaded via [igdbGenresProvider].
class IgdbGenreFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => '${key}_igdb';

  @override
  bool get searchable => true;

  @override
  bool get multiSelect => true;

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
