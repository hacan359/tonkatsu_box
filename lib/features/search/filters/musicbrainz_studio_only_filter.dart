import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// `-secondarytype:*` — drops live albums, compilations, soundtracks and
/// remixes, leaving the studio discography.
class MusicBrainzStudioOnlyFilter extends SearchFilter {
  @override
  String get key => 'studio';

  @override
  String get cacheKey => 'studio_musicbrainz';

  @override
  String placeholder(S l) => l.musicFilterEdition;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(
        id: 'studio',
        label: l.musicFilterStudioOnly,
        value: true,
      ),
    ];
  }
}
