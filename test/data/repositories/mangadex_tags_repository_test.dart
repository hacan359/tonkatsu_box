import 'package:core/models/mangadex_tag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/data/repositories/mangadex_tags_repository.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMangaDexApi api;
  late MockMangaDexTagDao dao;
  late MangaDexTagsRepository repo;

  const List<MangaDexTag> tags = <MangaDexTag>[
    MangaDexTag(id: 'u1', name: 'Action', group: 'genre'),
    MangaDexTag(id: 'u2', name: 'Demons', group: 'theme'),
  ];

  setUpAll(() {
    registerFallbackValue(<MangaDexTag>[]);
  });

  setUp(() {
    api = MockMangaDexApi();
    dao = MockMangaDexTagDao();
    repo = MangaDexTagsRepository(api: api, dao: dao);
  });

  group('MangaDexTagsRepository.getTags', () {
    test('returns cached when present — no API call', () async {
      when(dao.getAll).thenAnswer((_) async => tags);

      expect(await repo.getTags(), tags);
      verifyNever(() => api.fetchTags());
    });

    test('fetches from API and caches when empty', () async {
      when(dao.getAll).thenAnswer((_) async => <MangaDexTag>[]);
      when(() => api.fetchTags()).thenAnswer((_) async => tags);
      when(() => dao.replaceAll(any())).thenAnswer((_) async {});

      expect(await repo.getTags(), tags);
      verify(() => api.fetchTags()).called(1);
      verify(() => dao.replaceAll(tags)).called(1);
    });

    test('forceRefresh bypasses the cache', () async {
      when(dao.getAll).thenAnswer((_) async => tags);
      when(() => api.fetchTags()).thenAnswer((_) async => tags);
      when(() => dao.replaceAll(any())).thenAnswer((_) async {});

      await repo.getTags(forceRefresh: true);
      verify(() => api.fetchTags()).called(1);
    });

    test('API failure falls back to a non-empty cache', () async {
      when(dao.getAll).thenAnswer((_) async => tags);
      when(() => api.fetchTags()).thenThrow(Exception('down'));

      expect(await repo.getTags(forceRefresh: true), tags);
      verifyNever(() => dao.replaceAll(any()));
    });
  });
}
