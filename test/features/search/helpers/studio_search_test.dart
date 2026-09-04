import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_studio_filter.dart';
import 'package:tonkatsu_box/features/search/helpers/studio_search.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_anime_source.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';

void main() {
  group('studioSearchRequest', () {
    test('targets the AniList anime source with the studio preset', () {
      final SearchTabRequest r = studioSearchRequest('MAPPA');

      expect(r.sourceId, AniListAnimeSource.sourceId);
      expect(r.filterValues, <String, Object?>{
        AniListStudioFilter.filterKey: 'MAPPA',
      });
      expect(r.query, isNull);
      expect(r.collectionId, isNull);
    });
  });
}
