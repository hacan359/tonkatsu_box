import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/genre_cloud/facet.dart';
import 'package:tonkatsu_box/features/genre_cloud/facet_value.dart';
import 'package:tonkatsu_box/features/genre_cloud/genre_cloud_aggregate.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/platform.dart';

import '../../helpers/test_helpers.dart';

CollectionItem _game({
  List<String>? genres,
  DateTime? release,
  Platform? platform,
  int id = 1,
}) =>
    createTestCollectionItem(
      id: id,
      mediaType: MediaType.game,
      platform: platform,
      game: createTestGame(genres: genres, releaseDate: release),
    );

CollectionItem _movie({List<String>? genres, int? year, int id = 1}) =>
    createTestCollectionItem(
      id: id,
      mediaType: MediaType.movie,
      movie: createTestMovie(genres: genres, releaseYear: year),
    );

CollectionItem _anime({List<String>? genres, int? startYear, int id = 1}) =>
    createTestCollectionItem(
      id: id,
      mediaType: MediaType.anime,
      anime: createTestAnime(genres: genres, startYear: startYear),
    );

CollectionItem _vn({List<String>? platforms, String? released, int id = 1}) =>
    createTestCollectionItem(
      id: id,
      mediaType: MediaType.visualNovel,
      visualNovel: createTestVisualNovel(
        platforms: platforms,
        released: released,
      ),
    );

Iterable<String> _values(List<FacetValue> values, Facet facet) => values
    .where((FacetValue v) => v.facet == facet)
    .map((FacetValue v) => v.label);

void main() {
  group('extractItemFacets', () {
    test('reads genre, decade and owned platform from a game', () {
      final List<FacetEntry> facets = extractItemFacets(
        _game(
          genres: <String>['Action', 'RPG'],
          release: DateTime(1998, 5, 1),
          platform: const Platform(id: 1, name: 'PlayStation'),
        ),
      );
      expect(
        facets
            .where((FacetEntry e) => e.facet == Facet.genre)
            .map((FacetEntry e) => e.value),
        containsAll(<String>['Action', 'RPG']),
      );
      expect(
        facets.firstWhere((FacetEntry e) => e.facet == Facet.decade).value,
        '1990s',
      );
      expect(
        facets.firstWhere((FacetEntry e) => e.facet == Facet.platform).value,
        'PlayStation',
      );
    });

    test('reads only genre and decade from anime', () {
      final Set<Facet> dims = extractItemFacets(
        _anime(genres: <String>['Action'], startYear: 2011),
      ).map((FacetEntry e) => e.facet).toSet();
      expect(dims, <Facet>{Facet.genre, Facet.decade});
    });

    test('reads platform and decade from a visual novel', () {
      final List<FacetEntry> facets = extractItemFacets(
        _vn(platforms: <String>['Windows'], released: '2009-10-30'),
      );
      expect(
        facets.firstWhere((FacetEntry e) => e.facet == Facet.platform).value,
        'Windows',
      );
      expect(
        facets.firstWhere((FacetEntry e) => e.facet == Facet.decade).value,
        '2000s',
      );
    });
  });

  group('aggregateFacets', () {
    test('returns empty for no items', () {
      expect(aggregateFacets(const <CollectionItem>[]), isEmpty);
    });

    test('counts a facet value across items', () {
      final List<FacetValue> result = aggregateFacets(<CollectionItem>[
        _game(genres: <String>['Action'], id: 1),
        _game(genres: <String>['Action', 'RPG'], id: 2),
      ]);
      expect(
        result
            .firstWhere(
                (FacetValue v) => v.facet == Facet.genre && v.label == 'Action')
            .count,
        2,
      );
    });

    test('same label in different facets stays separate', () {
      final List<FacetValue> result = aggregateFacets(<CollectionItem>[
        _game(genres: <String>['Action'], id: 1),
        _vn(platforms: <String>['Action'], id: 2),
      ]);
      expect(_values(result, Facet.genre), contains('Action'));
      expect(_values(result, Facet.platform), contains('Action'));
      expect(result.where((FacetValue v) => v.label == 'Action'), hasLength(2));
    });

    test('is case-insensitive within a facet', () {
      final List<FacetValue> result = aggregateFacets(<CollectionItem>[
        _game(genres: <String>['RPG'], id: 1),
        _game(genres: <String>['rpg'], id: 2),
      ]);
      expect(_values(result, Facet.genre), hasLength(1));
      expect(result.first.count, 2);
    });

    test('dominant media type is the one with the most items', () {
      final List<FacetValue> result = aggregateFacets(<CollectionItem>[
        _game(genres: <String>['Action'], id: 1),
        _game(genres: <String>['Action'], id: 2),
        _movie(genres: <String>['Action'], id: 3),
      ]);
      expect(result.single.type, MediaType.game);
    });

    test('includeFacets keeps only the listed dimensions', () {
      final List<FacetValue> result = aggregateFacets(
        <CollectionItem>[
          _game(
            genres: <String>['Action'],
            platform: const Platform(id: 1, name: 'PC'),
          ),
        ],
        includeFacets: <Facet>{Facet.genre},
      );
      expect(result.every((FacetValue v) => v.facet == Facet.genre), isTrue);
      expect(_values(result, Facet.platform), isEmpty);
    });

    test('includeTypes ignores items of other media types', () {
      final List<FacetValue> result = aggregateFacets(
        <CollectionItem>[
          _game(genres: <String>['Action'], id: 1),
          _movie(genres: <String>['Drama'], id: 2),
        ],
        includeTypes: <MediaType>{MediaType.game},
      );
      expect(_values(result, Facet.genre), <String>['Action']);
    });

    test('sorts by count descending', () {
      final List<FacetValue> result = aggregateFacets(<CollectionItem>[
        _game(genres: <String>['Rare'], id: 1),
        _game(genres: <String>['Common'], id: 2),
        _game(genres: <String>['Common'], id: 3),
      ]);
      expect(result.first.label, 'Common');
      expect(result.first.count, 2);
    });
  });

  group('present sets', () {
    test('presentFacets returns the dimensions present', () {
      final Set<Facet> facets = presentFacets(<CollectionItem>[
        _game(
          genres: <String>['Action'],
          platform: const Platform(id: 1, name: 'PC'),
        ),
        _anime(genres: <String>['Action'], id: 2),
      ]);
      expect(facets, <Facet>{Facet.genre, Facet.platform});
    });

    test('presentMediaTypes returns contributing types', () {
      final Set<MediaType> types = presentMediaTypes(<CollectionItem>[
        _game(genres: <String>['Action'], id: 1),
        _anime(genres: <String>['Comedy'], id: 2),
      ]);
      expect(types, <MediaType>{MediaType.game, MediaType.anime});
    });
  });
}
