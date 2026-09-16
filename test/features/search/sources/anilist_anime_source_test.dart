import 'package:core/models/anime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_studio_filter.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_anime_source.dart';

import '../../../helpers/test_helpers.dart';

final Provider<Ref> _refProvider = Provider<Ref>((Ref ref) => ref);

void main() {
  late AniListAnimeSource source;

  setUp(() {
    source = AniListAnimeSource();
  });

  group('AniListAnimeSource', () {
    group('filters', () {
      test('exposes exactly one exclusive filter, the studio', () {
        final List<SearchFilter> exclusive =
            source.filters.where((SearchFilter f) => f.exclusive).toList();
        expect(exclusive.single, isA<AniListStudioFilter>());
      });

      test('studio filter sits between tags and status', () {
        final int studio = source.filters
            .indexWhere((SearchFilter f) => f is AniListStudioFilter);
        expect(studio, 2);
      });
    });

    group('fetch', () {
      late MockAniListApi api;
      late Ref ref;

      Future<BrowseResult> run(Map<String, Object?> filterValues,
          {String? query}) {
        return source.fetch(
          ref,
          query: query,
          filterValues: filterValues,
          sortBy: 'POPULARITY_DESC',
          page: 2,
        );
      }

      setUp(() {
        api = MockAniListApi();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[aniListApiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);
        ref = container.read(_refProvider);
        when(() => api.browseAnimeByStudio(
              studio: any(named: 'studio'),
              sort: any(named: 'sort'),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            )).thenAnswer((_) async =>
            (<Anime>[createTestAnime(id: 1)], true, 5));
        when(() => api.browseAnime(
              query: any(named: 'query'),
              genres: any(named: 'genres'),
              tags: any(named: 'tags'),
              status: any(named: 'status'),
              format: any(named: 'format'),
              startYear: any(named: 'startYear'),
              endYear: any(named: 'endYear'),
              sort: any(named: 'sort'),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            )).thenAnswer((_) async => (<Anime>[], false, 1));
      });

      test('should query the studio page and ignore the other filters',
          () async {
        final BrowseResult r = await run(<String, Object?>{
          AniListStudioFilter.filterKey: 'Kyoto Animation',
          'genre': <String>['Drama'],
          'status': 'RELEASING',
        }, query: 'violet');

        verify(() => api.browseAnimeByStudio(
              studio: 'Kyoto Animation',
              sort: 'POPULARITY_DESC',
              page: 2,
              perPage: any(named: 'perPage'),
            )).called(1);
        verifyNever(() => api.browseAnime(
              query: any(named: 'query'),
              genres: any(named: 'genres'),
              tags: any(named: 'tags'),
              status: any(named: 'status'),
              format: any(named: 'format'),
              startYear: any(named: 'startYear'),
              endYear: any(named: 'endYear'),
              sort: any(named: 'sort'),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            ));
        expect(r.items, hasLength(1));
        expect(r.hasMore, isTrue);
        expect(r.totalPages, 5);
        expect(r.currentPage, 2);
      });

      test('should fall back to the regular search when the studio is blank',
          () async {
        await run(<String, Object?>{
          AniListStudioFilter.filterKey: '   ',
          'genre': <String>['Drama'],
        });

        verifyNever(() => api.browseAnimeByStudio(
              studio: any(named: 'studio'),
              sort: any(named: 'sort'),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            ));
        verify(() => api.browseAnime(
              query: any(named: 'query'),
              genres: <String>['Drama'],
              tags: any(named: 'tags'),
              status: any(named: 'status'),
              format: any(named: 'format'),
              startYear: any(named: 'startYear'),
              endYear: any(named: 'endYear'),
              sort: 'POPULARITY_DESC',
              page: 2,
              perPage: any(named: 'perPage'),
            )).called(1);
      });
    });
  });
}
