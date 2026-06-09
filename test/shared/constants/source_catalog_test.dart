import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/shared/constants/source_catalog.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

void main() {
  group('kDataSourceCatalog', () {
    test('has one entry per search-source group', () {
      expect(kDataSourceCatalog.length, groupedSearchSources.length);
    });

    test('mirrors the search screen provider groups one-to-one', () {
      final Set<DataSource> catalogSources = kDataSourceCatalog
          .map((SourceInfo info) => info.source)
          .toSet();

      final Set<DataSource?> searchSourcesMapped = groupedSearchSources
          .map((SourceGroupEntry g) => kSearchGroupToSource[g.groupId])
          .toSet();

      // Every search group must be mapped (no nulls leaking through).
      expect(searchSourcesMapped.contains(null), isFalse);
      expect(catalogSources, searchSourcesMapped);
    });

    test('every entry lists at least one media type', () {
      for (final SourceInfo info in kDataSourceCatalog) {
        expect(info.mediaTypes, isNotEmpty);
      }
    });

    test('only IGDB and TMDB require a key', () {
      final Set<DataSource> needKey = kDataSourceCatalog
          .where((SourceInfo i) =>
              i.keyRequirement != SourceKeyRequirement.none)
          .map((SourceInfo i) => i.source)
          .toSet();

      expect(needKey, <DataSource>{DataSource.igdb, DataSource.tmdb});
    });

    test('excludes SteamGridDB, Fantlab and VGMaps', () {
      final Set<DataSource> sources =
          kDataSourceCatalog.map((SourceInfo i) => i.source).toSet();

      expect(sources.contains(DataSource.steamGridDb), isFalse);
      expect(sources.contains(DataSource.fantlab), isFalse);
      expect(sources.contains(DataSource.vgMaps), isFalse);
    });
  });
}
