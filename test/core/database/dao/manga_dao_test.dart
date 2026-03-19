import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/dao/manga_dao.dart';
import 'package:xerabora/shared/models/manga.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockDatabase mockDb;
  late MangaDao dao;

  setUp(() {
    mockDb = MockDatabase();
    dao = MangaDao(() async => mockDb);
  });

  group('MangaDao', () {
    group('upsertManga', () {
      test('inserts manga with replace', () async {
        const Manga manga = Manga(
          id: 1,
          title: 'Test Manga',
        );
        when(
          () => mockDb.insert(
            'manga_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertManga(manga);

        verify(
          () => mockDb.insert(
            'manga_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('upsertMangas', () {
      test('skips when list is empty', () async {
        await dao.upsertMangas(<Manga>[]);
        verifyNever(() => mockDb.batch());
      });

      test('batch inserts multiple mangas', () async {
        final MockBatch mockBatch = MockBatch();
        when(() => mockDb.batch()).thenReturn(mockBatch);
        when(
          () => mockBatch.insert(
            any(),
            any(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'),
          ),
        ).thenReturn(null);
        when(() => mockBatch.commit(noResult: true))
            .thenAnswer((_) async => <Object?>[]);

        const List<Manga> mangas = <Manga>[
          Manga(id: 1, title: 'Manga1'),
          Manga(id: 2, title: 'Manga2'),
        ];

        await dao.upsertMangas(mangas);

        verify(
          () => mockBatch.insert(
            'manga_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('getManga', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'manga_cache',
            where: 'id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final Manga? result = await dao.getManga(999);
        expect(result, isNull);
      });

      test('returns manga when found', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'title': 'Test Manga',
          'title_english': 'Test Manga EN',
          'title_native': null,
          'description': null,
          'cover_url': null,
          'cover_url_medium': null,
          'average_score': 85,
          'mean_score': null,
          'popularity': null,
          'status': 'FINISHED',
          'start_year': 2020,
          'start_month': null,
          'start_day': null,
          'chapters': 100,
          'volumes': 10,
          'format': 'MANGA',
          'country_of_origin': 'JP',
          'genres': null,
          'authors': null,
          'external_url': 'https://anilist.co/manga/1',
          'updated_at': 1000,
        };
        when(
          () => mockDb.query(
            'manga_cache',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final Manga? result = await dao.getManga(1);
        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.title, 'Test Manga');
        expect(result.averageScore, 85);
        expect(result.chapters, 100);
      });
    });

    group('getMangaByIds', () {
      test('returns empty list for empty ids', () async {
        final List<Manga> result = await dao.getMangaByIds(<int>[]);
        expect(result, isEmpty);
      });

      test('queries with IN clause', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT * FROM manga_cache WHERE id IN (?,?)',
            <int>[1, 2],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Manga> result = await dao.getMangaByIds(<int>[1, 2]);
        expect(result, isEmpty);
      });

      test('returns mangas for matching ids', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'title': 'Manga1',
          'title_english': null,
          'title_native': null,
          'description': null,
          'cover_url': null,
          'cover_url_medium': null,
          'average_score': null,
          'mean_score': null,
          'popularity': null,
          'status': null,
          'start_year': null,
          'start_month': null,
          'start_day': null,
          'chapters': null,
          'volumes': null,
          'format': null,
          'country_of_origin': null,
          'genres': null,
          'authors': null,
          'external_url': null,
          'updated_at': 1000,
        };
        when(
          () => mockDb.rawQuery(
            'SELECT * FROM manga_cache WHERE id IN (?)',
            <int>[1],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final List<Manga> result = await dao.getMangaByIds(<int>[1]);
        expect(result, hasLength(1));
        expect(result.first.id, 1);
        expect(result.first.title, 'Manga1');
      });
    });
  });
}
