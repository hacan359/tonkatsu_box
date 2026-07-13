import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/shared/constants/source_catalog.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

void main() {
  group('kDataSourceCatalog', () {
    test('every search-source group is mapped to its sources', () {
      for (final SourceGroupEntry g in groupedSearchSources) {
        expect(
          kSearchGroupToSources.containsKey(g.groupId),
          isTrue,
          reason: 'group "${g.groupId}" is not mapped in kSearchGroupToSources',
        );
      }
    });

    test('mirrors the mapped search-group sources', () {
      final Set<DataSource> catalogSources = kDataSourceCatalog
          .map((SourceInfo info) => info.source)
          .toSet();

      final Set<DataSource> searchSourcesMapped = kSearchGroupToSources.values
          .expand((List<DataSource> sources) => sources)
          .toSet();

      expect(catalogSources, searchSourcesMapped);
    });

    test('has no duplicate sources', () {
      final List<DataSource> sources =
          kDataSourceCatalog.map((SourceInfo i) => i.source).toList();
      expect(sources.length, sources.toSet().length);
    });

    test('every entry lists at least one media type', () {
      for (final SourceInfo info in kDataSourceCatalog) {
        expect(info.mediaTypes, isNotEmpty);
      }
    });

    test('only IGDB, TMDB, ComicVine, Google Books and Hardcover prompt '
        'for a key', () {
      final Set<DataSource> needKey = kDataSourceCatalog
          .where((SourceInfo i) =>
              i.keyRequirement != SourceKeyRequirement.none)
          .map((SourceInfo i) => i.source)
          .toSet();

      expect(
        needKey,
        <DataSource>{
          DataSource.igdb,
          DataSource.tmdb,
          DataSource.comicVine,
          DataSource.googleBooks,
          DataSource.hardcover,
        },
      );
    });

    test('excludes the non-searchable SteamGridDB and VGMaps', () {
      final Set<DataSource> sources =
          kDataSourceCatalog.map((SourceInfo i) => i.source).toSet();

      expect(sources.contains(DataSource.steamGridDb), isFalse);
      expect(sources.contains(DataSource.vgMaps), isFalse);
    });

    test('includes both book providers — OpenLibrary and Fantlab', () {
      final Set<DataSource> sources =
          kDataSourceCatalog.map((SourceInfo i) => i.source).toSet();

      expect(sources.contains(DataSource.openLibrary), isTrue);
      expect(sources.contains(DataSource.fantlab), isTrue);
    });
  });
}
