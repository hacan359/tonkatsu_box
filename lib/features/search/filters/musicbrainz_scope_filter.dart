import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Lucene field the query matches: free text ("All"), release-group title,
/// or artist — an artist query returns the discography, not mentions.
class MusicBrainzScopeFilter extends SearchFilter {
  @override
  String get key => 'scope';

  @override
  String get cacheKey => 'scope_musicbrainz';

  @override
  String placeholder(S l) => l.bookFilterSearchBy;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'title', label: l.title, value: 'releasegroup'),
      FilterOption(id: 'artist', label: l.musicSearchArtist, value: 'artist'),
    ];
  }
}
