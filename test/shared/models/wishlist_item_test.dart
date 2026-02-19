import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

void main() {
  group('WishlistItem', () {
    final DateTime testDate = DateTime(2024, 6, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;
    final DateTime resolvedDate = DateTime(2024, 6, 20, 18, 0, 0);
    final int resolvedTimestamp = resolvedDate.millisecondsSinceEpoch ~/ 1000;

    WishlistItem createTestItem({
      int id = 1,
      String text = 'Chrono Trigger',
      MediaType? mediaTypeHint,
      String? note,
      bool isResolved = false,
      DateTime? createdAt,
      DateTime? resolvedAt,
    }) {
      return WishlistItem(
        id: id,
        text: text,
        mediaTypeHint: mediaTypeHint,
        note: note,
        isResolved: isResolved,
        createdAt: createdAt ?? testDate,
        resolvedAt: resolvedAt,
      );
    }

    group('constructor', () {
      test('должен создавать экземпляр с обязательными полями', () {
        final WishlistItem item = createTestItem();

        expect(item.id, 1);
        expect(item.text, 'Chrono Trigger');
        expect(item.mediaTypeHint, null);
        expect(item.note, null);
        expect(item.isResolved, false);
        expect(item.createdAt, testDate);
        expect(item.resolvedAt, null);
      });

      test('должен создавать экземпляр со всеми полями', () {
        final WishlistItem item = createTestItem(
          mediaTypeHint: MediaType.game,
          note: 'SNES RPG, посоветовал друг',
          isResolved: true,
          resolvedAt: resolvedDate,
        );

        expect(item.mediaTypeHint, MediaType.game);
        expect(item.note, 'SNES RPG, посоветовал друг');
        expect(item.isResolved, true);
        expect(item.resolvedAt, resolvedDate);
      });
    });

    group('hasNote', () {
      test('должен возвращать false для null заметки', () {
        final WishlistItem item = createTestItem();
        expect(item.hasNote, false);
      });

      test('должен возвращать false для пустой заметки', () {
        final WishlistItem item = createTestItem(note: '');
        expect(item.hasNote, false);
      });

      test('должен возвращать true для непустой заметки', () {
        final WishlistItem item = createTestItem(note: 'Some note');
        expect(item.hasNote, true);
      });
    });

    group('fromDb', () {
      test('должен создавать WishlistItem из записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'text': 'Chrono Trigger',
          'media_type_hint': null,
          'note': null,
          'is_resolved': 0,
          'created_at': testTimestamp,
          'resolved_at': null,
        };

        final WishlistItem item = WishlistItem.fromDb(row);

        expect(item.id, 1);
        expect(item.text, 'Chrono Trigger');
        expect(item.mediaTypeHint, null);
        expect(item.note, null);
        expect(item.isResolved, false);
        expect(
          item.createdAt.millisecondsSinceEpoch ~/ 1000,
          testTimestamp,
        );
        expect(item.resolvedAt, null);
      });

      test('должен создавать resolved WishlistItem из записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 2,
          'text': 'The Matrix',
          'media_type_hint': 'movie',
          'note': 'Классика',
          'is_resolved': 1,
          'created_at': testTimestamp,
          'resolved_at': resolvedTimestamp,
        };

        final WishlistItem item = WishlistItem.fromDb(row);

        expect(item.id, 2);
        expect(item.text, 'The Matrix');
        expect(item.mediaTypeHint, MediaType.movie);
        expect(item.note, 'Классика');
        expect(item.isResolved, true);
        expect(
          item.resolvedAt!.millisecondsSinceEpoch ~/ 1000,
          resolvedTimestamp,
        );
      });

      test('должен обрабатывать все типы медиа', () {
        for (final MediaType type in MediaType.values) {
          final Map<String, dynamic> row = <String, dynamic>{
            'id': 1,
            'text': 'Test',
            'media_type_hint': type.value,
            'note': null,
            'is_resolved': 0,
            'created_at': testTimestamp,
            'resolved_at': null,
          };

          final WishlistItem item = WishlistItem.fromDb(row);
          expect(item.mediaTypeHint, type);
        }
      });
    });

    group('toDb', () {
      test('должен возвращать корректную Map для БД', () {
        final WishlistItem item = createTestItem();
        final Map<String, dynamic> db = item.toDb();

        expect(db['id'], 1);
        expect(db['text'], 'Chrono Trigger');
        expect(db['media_type_hint'], null);
        expect(db['note'], null);
        expect(db['is_resolved'], 0);
        expect(db['created_at'], testTimestamp);
        expect(db['resolved_at'], null);
      });

      test('должен включать все поля', () {
        final WishlistItem item = createTestItem(
          mediaTypeHint: MediaType.tvShow,
          note: 'Заметка',
          isResolved: true,
          resolvedAt: resolvedDate,
        );
        final Map<String, dynamic> db = item.toDb();

        expect(db['media_type_hint'], 'tv_show');
        expect(db['note'], 'Заметка');
        expect(db['is_resolved'], 1);
        expect(db['resolved_at'], resolvedTimestamp);
      });
    });

    group('fromDb → toDb roundtrip', () {
      test('должен быть обратимым для минимального элемента', () {
        final WishlistItem original = createTestItem();
        final Map<String, dynamic> db = original.toDb();
        final WishlistItem restored = WishlistItem.fromDb(db);

        expect(restored.id, original.id);
        expect(restored.text, original.text);
        expect(restored.mediaTypeHint, original.mediaTypeHint);
        expect(restored.note, original.note);
        expect(restored.isResolved, original.isResolved);
        expect(restored.resolvedAt, original.resolvedAt);
      });

      test('должен быть обратимым для полного элемента', () {
        final WishlistItem original = createTestItem(
          mediaTypeHint: MediaType.animation,
          note: 'Аниме',
          isResolved: true,
          resolvedAt: resolvedDate,
        );
        final Map<String, dynamic> db = original.toDb();
        final WishlistItem restored = WishlistItem.fromDb(db);

        expect(restored.id, original.id);
        expect(restored.text, original.text);
        expect(restored.mediaTypeHint, original.mediaTypeHint);
        expect(restored.note, original.note);
        expect(restored.isResolved, original.isResolved);
        expect(
          restored.resolvedAt!.millisecondsSinceEpoch ~/ 1000,
          original.resolvedAt!.millisecondsSinceEpoch ~/ 1000,
        );
      });
    });

    group('copyWith', () {
      test('должен создавать копию с изменённым текстом', () {
        final WishlistItem original = createTestItem();
        final WishlistItem copy = original.copyWith(text: 'New Title');

        expect(copy.text, 'New Title');
        expect(copy.id, original.id);
        expect(copy.createdAt, original.createdAt);
      });

      test('должен создавать копию с изменённым mediaTypeHint', () {
        final WishlistItem original = createTestItem();
        final WishlistItem copy =
            original.copyWith(mediaTypeHint: MediaType.movie);

        expect(copy.mediaTypeHint, MediaType.movie);
        expect(copy.text, original.text);
      });

      test('должен очищать mediaTypeHint через clearMediaTypeHint', () {
        final WishlistItem original =
            createTestItem(mediaTypeHint: MediaType.game);
        final WishlistItem copy =
            original.copyWith(clearMediaTypeHint: true);

        expect(copy.mediaTypeHint, null);
      });

      test('должен очищать note через clearNote', () {
        final WishlistItem original = createTestItem(note: 'Заметка');
        final WishlistItem copy = original.copyWith(clearNote: true);

        expect(copy.note, null);
      });

      test('должен очищать resolvedAt через clearResolvedAt', () {
        final WishlistItem original =
            createTestItem(resolvedAt: resolvedDate);
        final WishlistItem copy =
            original.copyWith(clearResolvedAt: true);

        expect(copy.resolvedAt, null);
      });

      test('должен создавать копию со всеми изменёнными полями', () {
        final WishlistItem original = createTestItem();
        final DateTime newDate = DateTime(2025, 1, 1);
        final WishlistItem copy = original.copyWith(
          id: 99,
          text: 'New Text',
          mediaTypeHint: MediaType.tvShow,
          note: 'New note',
          isResolved: true,
          createdAt: newDate,
          resolvedAt: resolvedDate,
        );

        expect(copy.id, 99);
        expect(copy.text, 'New Text');
        expect(copy.mediaTypeHint, MediaType.tvShow);
        expect(copy.note, 'New note');
        expect(copy.isResolved, true);
        expect(copy.createdAt, newDate);
        expect(copy.resolvedAt, resolvedDate);
      });

      test('должен сохранять все поля при пустом copyWith', () {
        final WishlistItem original = createTestItem(
          mediaTypeHint: MediaType.game,
          note: 'Заметка',
          isResolved: true,
          resolvedAt: resolvedDate,
        );
        final WishlistItem copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.text, original.text);
        expect(copy.mediaTypeHint, original.mediaTypeHint);
        expect(copy.note, original.note);
        expect(copy.isResolved, original.isResolved);
        expect(copy.resolvedAt, original.resolvedAt);
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковом id', () {
        final WishlistItem a = createTestItem(id: 1, text: 'A');
        final WishlistItem b = createTestItem(id: 1, text: 'B');

        expect(a == b, true);
        expect(a.hashCode, b.hashCode);
      });

      test('должен быть не равен при разных id', () {
        final WishlistItem a = createTestItem(id: 1);
        final WishlistItem b = createTestItem(id: 2);

        expect(a == b, false);
      });

      test('должен быть равен самому себе', () {
        final WishlistItem item = createTestItem();
        expect(item == item, true);
      });

      test('должен быть не равен объекту другого типа', () {
        final WishlistItem item = createTestItem();
        // ignore: unrelated_type_equality_checks
        expect(item == 'string', false);
      });
    });

    group('toString', () {
      test('должен возвращать корректную строку', () {
        final WishlistItem item = createTestItem(id: 5, text: 'Test Game');

        expect(
          item.toString(),
          'WishlistItem(id: 5, text: Test Game, resolved: false)',
        );
      });

      test('должен показывать resolved статус', () {
        final WishlistItem item = createTestItem(isResolved: true);

        expect(item.toString(), contains('resolved: true'));
      });
    });
  });
}
