import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/anilist_tags_repository.dart';
import 'package:xerabora/shared/models/anilist_tag.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAniListApi api;
  late MockAniListTagDao dao;
  late AniListTagsRepository repo;

  const List<AniListTag> apiTags = <AniListTag>[
    AniListTag(id: 1, name: 'Magic', category: 'Theme'),
    AniListTag(id: 2, name: 'School', category: 'Setting'),
  ];

  setUpAll(() {
    registerFallbackValue(<AniListTag>[]);
  });

  setUp(() {
    api = MockAniListApi();
    dao = MockAniListTagDao();
    repo = AniListTagsRepository(api: api, dao: dao);
  });

  group('AniListTagsRepository.getTags', () {
    test('returns cached when present — no API call', () async {
      when(dao.getAll).thenAnswer((_) async => apiTags);

      final List<AniListTag> result = await repo.getTags();
      expect(result, apiTags);
      verifyNever(() => api.fetchTagCollection());
    });

    test('fetches from API when cache is empty', () async {
      when(dao.getAll).thenAnswer((_) async => <AniListTag>[]);
      when(() => api.fetchTagCollection())
          .thenAnswer((_) async => apiTags);
      when(() => dao.replaceAll(any())).thenAnswer((_) async {});

      final List<AniListTag> result = await repo.getTags();
      expect(result, apiTags);
      verify(() => api.fetchTagCollection()).called(1);
      verify(() => dao.replaceAll(apiTags)).called(1);
    });

    test('forceRefresh bypasses cache and hits API', () async {
      when(dao.getAll).thenAnswer((_) async => apiTags);
      when(() => api.fetchTagCollection())
          .thenAnswer((_) async => apiTags);
      when(() => dao.replaceAll(any())).thenAnswer((_) async {});

      await repo.getTags(forceRefresh: true);
      verify(() => api.fetchTagCollection()).called(1);
    });

    test('API failure with non-empty cache falls back to cache', () async {
      when(dao.getAll).thenAnswer((_) async => apiTags);
      when(() => api.fetchTagCollection())
          .thenThrow(Exception('network down'));

      final List<AniListTag> result = await repo.getTags(forceRefresh: true);
      expect(result, apiTags);
      verifyNever(() => dao.replaceAll(any()));
    });

    test('API failure with empty cache rethrows', () async {
      when(dao.getAll).thenAnswer((_) async => <AniListTag>[]);
      when(() => api.fetchTagCollection())
          .thenThrow(Exception('network down'));

      expect(() => repo.getTags(), throwsException);
    });
  });
}
