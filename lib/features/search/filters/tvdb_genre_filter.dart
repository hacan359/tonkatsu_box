import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tvdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// One flat genre list serves both movies and series on TheTVDB, so a single
/// filter is shared by both sources.
final FutureProvider<List<({int id, String name})>> tvdbGenresProvider =
    FutureProvider<List<({int id, String name})>>((Ref ref) async {
  final TvdbApi api = ref.read(tvdbApiProvider);
  if (!api.hasApiKey) return const <({int id, String name})>[];
  return api.getGenres();
});

class TvdbGenreFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => 'genre_tvdb';

  @override
  bool get searchable => true;

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
    final List<({int id, String name})> genres =
        await ref.read(tvdbGenresProvider.future);
    return <FilterOption>[
      for (final ({int id, String name}) g in genres)
        FilterOption(id: g.id.toString(), label: g.name, value: g.id),
    ];
  }
}
