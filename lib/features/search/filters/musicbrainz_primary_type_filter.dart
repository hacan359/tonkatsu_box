import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Sentinel for "no primary-type clause": unset defaults to albums instead,
/// or the Single minted for every promo track would drown the results.
const String kMusicBrainzAnyPrimaryType = '';

/// MusicBrainz `primarytype:`. Unset means AudioItem (see the sentinel above);
/// EPs and singles surface only on explicit request.
class MusicBrainzPrimaryTypeFilter extends SearchFilter {
  @override
  String get key => 'type';

  @override
  String get cacheKey => 'type_musicbrainz';

  @override
  String placeholder(S l) => l.musicFilterAlbumsDefault;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Albums',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'ep', label: l.musicFilterTypeEp, value: 'ep'),
      FilterOption(
        id: 'single',
        label: l.musicFilterTypeSingle,
        value: 'single',
      ),
      FilterOption(
        id: 'broadcast',
        label: l.musicFilterTypeBroadcast,
        value: 'broadcast',
      ),
      FilterOption(id: 'other', label: l.musicFilterTypeOther, value: 'other'),
      FilterOption(
        id: 'all_types',
        label: l.musicFilterAllTypes,
        value: kMusicBrainzAnyPrimaryType,
      ),
    ];
  }
}
