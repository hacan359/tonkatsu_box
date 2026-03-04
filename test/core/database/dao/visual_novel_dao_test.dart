import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/dao/visual_novel_dao.dart';
import 'package:xerabora/shared/models/visual_novel.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockDatabase mockDb;
  late VisualNovelDao dao;

  setUp(() {
    mockDb = MockDatabase();
    dao = VisualNovelDao(() async => mockDb);
  });

  group('VisualNovelDao', () {
    group('upsertVisualNovel', () {
      test('inserts visual novel with replace', () async {
        const VisualNovel vn = VisualNovel(
          id: 'v1',
          title: 'Test VN',
        );
        when(
          () => mockDb.insert(
            'visual_novels_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertVisualNovel(vn);

        verify(
          () => mockDb.insert(
            'visual_novels_cache',
            vn.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('upsertVisualNovels', () {
      test('skips when list is empty', () async {
        await dao.upsertVisualNovels(<VisualNovel>[]);
        verifyNever(() => mockDb.batch());
      });

      test('batch inserts multiple visual novels', () async {
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

        const List<VisualNovel> vns = <VisualNovel>[
          VisualNovel(id: 'v1', title: 'VN1'),
          VisualNovel(id: 'v2', title: 'VN2'),
        ];

        await dao.upsertVisualNovels(vns);

        verify(
          () => mockBatch.insert(
            'visual_novels_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('getVisualNovel', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'visual_novels_cache',
            where: 'numeric_id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final VisualNovel? result = await dao.getVisualNovel(999);
        expect(result, isNull);
      });

      test('returns visual novel when found', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 'v1',
          'title': 'Test VN',
          'alt_title': null,
          'description': null,
          'image_url': null,
          'rating': null,
          'vote_count': null,
          'released': null,
          'length_minutes': null,
          'length': null,
          'tags': null,
          'developers': null,
          'platforms': null,
          'external_url': null,
          'updated_at': 1000,
        };
        when(
          () => mockDb.query(
            'visual_novels_cache',
            where: 'numeric_id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final VisualNovel? result = await dao.getVisualNovel(1);
        expect(result, isNotNull);
        expect(result!.numericId, 1);
        expect(result.title, 'Test VN');
      });
    });

    group('getVisualNovelsByNumericIds', () {
      test('returns empty list for empty ids', () async {
        final List<VisualNovel> result =
            await dao.getVisualNovelsByNumericIds(<int>[]);
        expect(result, isEmpty);
      });

      test('queries with IN clause', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT * FROM visual_novels_cache WHERE numeric_id IN (?,?)',
            <int>[1, 2],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<VisualNovel> result =
            await dao.getVisualNovelsByNumericIds(<int>[1, 2]);
        expect(result, isEmpty);
      });
    });

    group('getVndbTags', () {
      test('returns tags ordered by name', () async {
        when(
          () => mockDb.query('vndb_tags', orderBy: 'name ASC'),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'g1',
              'name': 'Action',
            },
          ],
        );

        final List<VndbTag> result = await dao.getVndbTags();
        expect(result.length, 1);
        expect(result.first.name, 'Action');
      });
    });
  });
}
