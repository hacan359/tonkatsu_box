import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/search_sources.dart';

void main() {
  group('groupedSearchSources', () {
    test('groups sources by groupId', () {
      final List<String> groupIds =
          groupedSearchSources.map((SourceGroupEntry g) => g.groupId).toList();

      expect(groupIds, contains('tmdb'));
      expect(groupIds, contains('igdb'));
      expect(groupIds, contains('anilist'));
      expect(groupIds, contains('vndb'));
    });

    test('preserves order — tmdb first, vndb last', () {
      expect(groupedSearchSources.first.groupId, 'tmdb');
      expect(groupedSearchSources.last.groupId, 'vndb');
    });

    test('tmdb group has 3 sources', () {
      final SourceGroupEntry tmdb = groupedSearchSources
          .firstWhere((SourceGroupEntry g) => g.groupId == 'tmdb');
      expect(tmdb.sources.length, 3);
      expect(
        tmdb.sources.map((SearchSource s) => s.id).toList(),
        <String>['movies', 'tv', 'anime'],
      );
    });

    test('igdb group has 1 source', () {
      final SourceGroupEntry igdb = groupedSearchSources
          .firstWhere((SourceGroupEntry g) => g.groupId == 'igdb');
      expect(igdb.sources.length, 1);
      expect(igdb.sources.first.id, 'games');
    });

    test('anilist group has 2 sources', () {
      final SourceGroupEntry anilist = groupedSearchSources
          .firstWhere((SourceGroupEntry g) => g.groupId == 'anilist');
      expect(anilist.sources.length, 2);
      expect(anilist.sources[0].id, 'anilist_anime');
      expect(anilist.sources[1].id, 'manga');
    });

    test('vndb group has 1 source', () {
      final SourceGroupEntry vndb = groupedSearchSources
          .firstWhere((SourceGroupEntry g) => g.groupId == 'vndb');
      expect(vndb.sources.length, 1);
      expect(vndb.sources.first.id, 'visual_novels');
    });

    test('total sources in groups matches searchSources', () {
      final int totalInGroups = groupedSearchSources.fold<int>(
        0,
        (int sum, SourceGroupEntry g) => sum + g.sources.length,
      );
      expect(totalInGroups, searchSources.length);
    });

    test('each group has correct groupName and groupIcon', () {
      for (final SourceGroupEntry group in groupedSearchSources) {
        for (final SearchSource source in group.sources) {
          expect(source.groupId, group.groupId);
          expect(source.groupName, group.groupName);
          expect(source.groupIcon, group.groupIcon);
        }
      }
    });
  });

  group('getSearchSourceById', () {
    test('returns first source for unknown id', () {
      final SearchSource source = getSearchSourceById('nonexistent');
      expect(source.id, searchSources.first.id);
    });
  });
}
