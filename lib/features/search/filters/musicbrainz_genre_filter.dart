import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

// Curated slice of MusicBrainz's ~2000 folksonomy tags, covering most tagged
// albums; the names are MB vocabulary proper nouns and stay English.
const List<String> _genres = <String>[
  'rock',
  'pop',
  'electronic',
  'hip hop',
  'jazz',
  'metal',
  'classical',
  'folk',
  'punk',
  'blues',
  'country',
  'reggae',
  'soul',
  'funk',
  'disco',
  'r&b',
  'ambient',
  'techno',
  'house',
  'trance',
  'drum and bass',
  'indie rock',
  'alternative rock',
  'progressive rock',
  'psychedelic rock',
  'hard rock',
  'heavy metal',
  'black metal',
  'death metal',
  'doom metal',
  'thrash metal',
  'post-rock',
  'post-punk',
  'new wave',
  'synth-pop',
  'shoegaze',
  'grunge',
  'ska',
  'gospel',
  'latin',
  'k-pop',
  'j-pop',
  'soundtrack',
  'singer-songwriter',
  'experimental',
  'industrial',
  'lo-fi',
  'trip hop',
  'dubstep',
  'grime',
];

/// MusicBrainz `tag:` filter — genres are curated tags, so one Lucene field
/// serves both.
class MusicBrainzGenreFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => 'genre_musicbrainz';

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
    return <FilterOption>[
      for (final String genre in _genres)
        FilterOption(id: genre, label: genre, value: genre),
    ];
  }
}
