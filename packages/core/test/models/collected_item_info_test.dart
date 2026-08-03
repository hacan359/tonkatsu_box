import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:test/test.dart';

void main() {
  group('CollectedItemInfo', () {
    group('constructor', () {
      test('should create с обязательными полями', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 1,
          collectionId: 10,
          collectionName: 'RPG Games',
        );

        expect(info.recordId, 1);
        expect(info.collectionId, 10);
        expect(info.collectionName, 'RPG Games');
      });

      test('should create с null collectionId и collectionName', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 42,
          collectionId: null,
          collectionName: null,
        );

        expect(info.recordId, 42);
        expect(info.collectionId, isNull);
        expect(info.collectionName, isNull);
      });
    });

    group('toString', () {
      test('should return читаемое представление со всеми полями', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 1,
          collectionId: 10,
          collectionName: 'RPG Games',
        );

        final String result = info.toString();

        expect(result, contains('CollectedItemInfo'));
        expect(result, contains('recordId: 1'));
        expect(result, contains('collectionId: 10'));
        expect(result, contains('collectionName: RPG Games'));
      });

      test('должен корректно отображать null значения', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 42,
          collectionId: null,
          collectionName: null,
        );

        final String result = info.toString();

        expect(result, contains('recordId: 42'));
        expect(result, contains('collectionId: null'));
        expect(result, contains('collectionName: null'));
      });
    });
  });

  group('CollectedPlacements.forSource', () {
    const CollectedItemInfo anilistPlacement = CollectedItemInfo(
      recordId: 1,
      collectionId: 10,
      collectionName: 'AniList',
      source: DataSource.anilist,
    );
    const CollectedItemInfo kitsuPlacement = CollectedItemInfo(
      recordId: 2,
      collectionId: 20,
      collectionName: 'Kitsu',
      source: DataSource.kitsu,
    );
    const List<CollectedItemInfo> bothProviders = <CollectedItemInfo>[
      anilistPlacement,
      kitsuPlacement,
    ];

    test('should keep only the requested source for a multi-source type', () {
      final List<CollectedItemInfo> result = bothProviders.forSource(
        MediaType.anime,
        DataSource.kitsu,
      );

      expect(result, <CollectedItemInfo>[kitsuPlacement]);
    });

    test('should return an empty list when no placement matches the source',
        () {
      final List<CollectedItemInfo> result =
          <CollectedItemInfo>[anilistPlacement].forSource(
        MediaType.anime,
        DataSource.kitsu,
      );

      expect(result, isEmpty);
    });

    test('should keep every placement when the source is null', () {
      final List<CollectedItemInfo> result = bothProviders.forSource(
        MediaType.anime,
        null,
      );

      expect(result, bothProviders);
    });

    test('should keep every placement for a single-source type', () {
      // Movies come from TMDB alone, so their ids never need narrowing.
      final List<CollectedItemInfo> result = bothProviders.forSource(
        MediaType.movie,
        DataSource.tmdb,
      );

      expect(result, bothProviders);
    });

    test('should return an empty list for no placements', () {
      expect(
        const <CollectedItemInfo>[].forSource(
          MediaType.book,
          DataSource.fantlab,
        ),
        isEmpty,
      );
    });
  });

  group('CollectedPlacementIndex', () {
    const Map<int, List<CollectedItemInfo>> placements =
        <int, List<CollectedItemInfo>>{
      27448: <CollectedItemInfo>[
        CollectedItemInfo(
          recordId: 1,
          collectionId: 10,
          collectionName: 'Books',
          source: DataSource.openLibrary,
        ),
      ],
      3104: <CollectedItemInfo>[
        CollectedItemInfo(
          recordId: 2,
          collectionId: 20,
          collectionName: 'Fantlab',
          source: DataSource.fantlab,
        ),
        CollectedItemInfo(
          recordId: 3,
          collectionId: 30,
          collectionName: 'Google',
          source: DataSource.googleBooks,
        ),
      ],
    };

    group('sourceKeys', () {
      test('should pair every placement with its own external id', () {
        expect(placements.sourceKeys, <(DataSource, int)>{
          (DataSource.openLibrary, 27448),
          (DataSource.fantlab, 3104),
          (DataSource.googleBooks, 3104),
        });
      });

      test('should not pair an id with a source that does not hold it', () {
        expect(
          placements.sourceKeys.contains((DataSource.fantlab, 27448)),
          isFalse,
        );
      });

      test('should be empty for no placements', () {
        expect(
          const <int, List<CollectedItemInfo>>{}.sourceKeys,
          isEmpty,
        );
      });
    });

    group('idsFromSource', () {
      test('should return only the ids held by the given source', () {
        expect(placements.idsFromSource(DataSource.fantlab), <int>{3104});
      });

      test('should return an id when any of its placements matches', () {
        expect(placements.idsFromSource(DataSource.googleBooks), <int>{3104});
      });

      test('should return nothing for a source with no placements', () {
        expect(placements.idsFromSource(DataSource.kitsu), isEmpty);
      });
    });
  });
}
