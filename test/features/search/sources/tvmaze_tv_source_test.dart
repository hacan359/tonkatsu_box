import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tvmaze_api.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/tvmaze_tv_source.dart';

import '../../../helpers/test_helpers.dart';

final Provider<Ref> _refProvider = Provider<Ref>((Ref ref) => ref);

void main() {
  late TvMazeTvSource source;

  setUp(() {
    source = TvMazeTvSource();
  });

  group('properties', () {
    test('id and browse support', () {
      expect(source.id, 'tvmaze_tv');
      expect(source.outputMediaType, MediaType.tvShow);
      expect(source.supportsBrowse, isFalse);
      expect(source.iconAsset, isNotNull);
    });

    test('exposes no filters — TVmaze search is title-only', () {
      expect(source.filters, isEmpty);
    });
  });

  group('fetch', () {
    late MockTvMazeApi mockApi;
    late Ref ref;

    TvShow show(String name) =>
        TvShow(tmdbId: name.hashCode, title: name, source: DataSource.tvmaze);

    Future<BrowseResult> run({required String? query, int page = 1}) {
      return source.fetch(
        ref,
        query: query,
        filterValues: const <String, Object?>{},
        sortBy: 'relevance',
        page: page,
      );
    }

    setUp(() {
      mockApi = MockTvMazeApi();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          tvMazeApiProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);
      ref = container.read(_refProvider);
    });

    test('returns empty without calling the API when query is empty', () async {
      final BrowseResult result = await run(query: '');
      expect(result.items, isEmpty);
      verifyNever(() => mockApi.searchShows(any()));
    });

    test('returns title search results as tv shows', () async {
      when(() => mockApi.searchShows('x'))
          .thenAnswer((_) async => <TvShow>[show('A'), show('B')]);

      final BrowseResult result = await run(query: 'x');
      expect(result.items, hasLength(2));
      expect(result.mediaType, MediaType.tvShow);
    });

    test('paginates by slicing with hasMore', () async {
      final List<TvShow> many =
          List<TvShow>.generate(25, (int i) => show('S$i'));
      when(() => mockApi.searchShows('x')).thenAnswer((_) async => many);

      final BrowseResult page1 = await run(query: 'x');
      expect(page1.items, hasLength(20));
      expect(page1.hasMore, isTrue);

      final BrowseResult page2 = await run(query: 'x', page: 2);
      expect(page2.items, hasLength(5));
      expect(page2.hasMore, isFalse);
    });

    test('returns empty for a page past the end', () async {
      when(() => mockApi.searchShows('x'))
          .thenAnswer((_) async => <TvShow>[show('A')]);

      final BrowseResult result = await run(query: 'x', page: 5);
      expect(result.items, isEmpty);
    });
  });
}
