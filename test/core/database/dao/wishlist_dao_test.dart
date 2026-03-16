import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/dao/wishlist_dao.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockDatabase mockDb;
  late WishlistDao dao;

  setUp(() {
    mockDb = MockDatabase();
    dao = WishlistDao(() async => mockDb);
  });

  group('WishlistDao', () {
    group('addWishlistItem', () {
      test('inserts item and returns it with id', () async {
        when(
          () => mockDb.insert('wishlist', any()),
        ).thenAnswer((_) async => 42);

        final WishlistItem result = await dao.addWishlistItem(
          text: 'Chrono Trigger',
          mediaTypeHint: MediaType.game,
          note: 'SNES version',
        );

        expect(result.id, 42);
        expect(result.text, 'Chrono Trigger');
        expect(result.mediaTypeHint, MediaType.game);
        expect(result.note, 'SNES version');
        expect(result.isResolved, false);
      });

      test('inserts item without optional fields', () async {
        when(
          () => mockDb.insert('wishlist', any()),
        ).thenAnswer((_) async => 1);

        final WishlistItem result = await dao.addWishlistItem(text: 'Test');

        expect(result.id, 1);
        expect(result.mediaTypeHint, isNull);
        expect(result.note, isNull);
      });
    });

    group('getWishlistItems', () {
      test('returns all items including resolved', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT * FROM wishlist  '
            'ORDER BY is_resolved ASC, created_at DESC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'text': 'Item 1',
              'media_type_hint': null,
              'note': null,
              'is_resolved': 0,
              'created_at': 1705320000,
              'resolved_at': null,
            },
          ],
        );

        final List<WishlistItem> result = await dao.getWishlistItems();

        expect(result.length, 1);
        expect(result.first.text, 'Item 1');
      });

      test('filters resolved when includeResolved is false', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT * FROM wishlist WHERE is_resolved = 0 '
            'ORDER BY is_resolved ASC, created_at DESC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<WishlistItem> result =
            await dao.getWishlistItems(includeResolved: false);

        expect(result, isEmpty);
      });
    });

    group('getWishlistItemCount', () {
      test('returns active count by default', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as count FROM wishlist WHERE is_resolved = 0',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 5},
          ],
        );

        expect(await dao.getWishlistItemCount(), 5);
      });

      test('returns total count when onlyActive is false', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as count FROM wishlist ',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 8},
          ],
        );

        expect(await dao.getWishlistItemCount(onlyActive: false), 8);
      });
    });

    group('updateWishlistItem', () {
      test('updates text', () async {
        when(
          () => mockDb.update(
            'wishlist',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateWishlistItem(1, text: 'Updated');

        verify(
          () => mockDb.update(
            'wishlist',
            <String, dynamic>{'text': 'Updated'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('sets mediaTypeHint', () async {
        when(
          () => mockDb.update(
            'wishlist',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateWishlistItem(1, mediaTypeHint: MediaType.movie);

        verify(
          () => mockDb.update(
            'wishlist',
            <String, dynamic>{'media_type_hint': 'movie'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears mediaTypeHint when clearMediaTypeHint is true', () async {
        when(
          () => mockDb.update(
            'wishlist',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateWishlistItem(1, clearMediaTypeHint: true);

        verify(
          () => mockDb.update(
            'wishlist',
            <String, dynamic>{'media_type_hint': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears note when clearNote is true', () async {
        when(
          () => mockDb.update(
            'wishlist',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateWishlistItem(1, clearNote: true);

        verify(
          () => mockDb.update(
            'wishlist',
            <String, dynamic>{'note': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('skips update when no fields provided', () async {
        await dao.updateWishlistItem(1);

        verifyNever(
          () => mockDb.update(any(), any(), where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs')),
        );
      });
    });

    group('resolveWishlistItem', () {
      test('sets is_resolved and resolved_at', () async {
        when(
          () => mockDb.update(
            'wishlist',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.resolveWishlistItem(1);

        final VerificationResult captured = verify(
          () => mockDb.update(
            'wishlist',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );
        captured.called(1);

        final Map<String, dynamic> data =
            captured.captured.first as Map<String, dynamic>;
        expect(data['is_resolved'], 1);
        expect(data['resolved_at'], isA<int>());
      });
    });

    group('unresolveWishlistItem', () {
      test('clears resolved state', () async {
        when(
          () => mockDb.update(
            'wishlist',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.unresolveWishlistItem(1);

        verify(
          () => mockDb.update(
            'wishlist',
            <String, dynamic>{'is_resolved': 0, 'resolved_at': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('deleteWishlistItem', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'wishlist',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteWishlistItem(1);

        verify(
          () => mockDb.delete(
            'wishlist',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('clearResolvedWishlistItems', () {
      test('deletes resolved items and returns count', () async {
        when(
          () => mockDb.delete(
            'wishlist',
            where: 'is_resolved = 1',
          ),
        ).thenAnswer((_) async => 3);

        final int count = await dao.clearResolvedWishlistItems();

        expect(count, 3);
      });
    });

    group('findUnresolvedByText', () {
      test('should return matching unresolved item', () async {
        when(
          () => mockDb.query(
            'wishlist',
            where: 'text = ? AND is_resolved = 0',
            whereArgs: <Object?>['Chrono Trigger'],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 5,
              'text': 'Chrono Trigger',
              'media_type_hint': 'game',
              'note': 'SNES',
              'is_resolved': 0,
              'created_at': 1705320000,
              'resolved_at': null,
            },
          ],
        );

        final WishlistItem? result =
            await dao.findUnresolvedByText('Chrono Trigger');

        expect(result, isNotNull);
        expect(result!.id, 5);
        expect(result.text, 'Chrono Trigger');
      });

      test('should return null when no match found', () async {
        when(
          () => mockDb.query(
            'wishlist',
            where: 'text = ? AND is_resolved = 0',
            whereArgs: <Object?>['Nonexistent'],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final WishlistItem? result =
            await dao.findUnresolvedByText('Nonexistent');

        expect(result, isNull);
      });
    });
  });
}
