import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/cover_info.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  group('CoverInfo', () {
    group('конструктор', () {
      test('должен создать экземпляр со всеми полями', () {
        const CoverInfo info = CoverInfo(
          externalId: 123,
          mediaType: MediaType.game,
          platformId: 6,
          thumbnailUrl: 'https://example.com/cover.jpg',
        );

        expect(info.externalId, 123);
        expect(info.mediaType, MediaType.game);
        expect(info.platformId, 6);
        expect(info.thumbnailUrl, 'https://example.com/cover.jpg');
      });

      test('должен создать экземпляр с nullable полями как null', () {
        const CoverInfo info = CoverInfo(
          externalId: 456,
          mediaType: MediaType.movie,
        );

        expect(info.platformId, isNull);
        expect(info.thumbnailUrl, isNull);
      });
    });

    group('fromDb', () {
      test('должен создать CoverInfo для игры без конвертации URL', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 100,
          'media_type': 'game',
          'platform_id': 6,
          'thumbnail_url': 'https://images.igdb.com/t_cover_big/co1234.jpg',
        });

        expect(info.externalId, 100);
        expect(info.mediaType, MediaType.game);
        expect(info.platformId, 6);
        expect(
          info.thumbnailUrl,
          'https://images.igdb.com/t_cover_big/co1234.jpg',
        );
      });

      test('должен конвертировать URL фильма в thumbnail (w154)', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 200,
          'media_type': 'movie',
          'platform_id': null,
          'thumbnail_url': 'https://image.tmdb.org/t/p/w342/poster.jpg',
        });

        expect(info.mediaType, MediaType.movie);
        expect(
          info.thumbnailUrl,
          'https://image.tmdb.org/t/p/w154/poster.jpg',
        );
      });

      test('должен конвертировать URL сериала в thumbnail (w154)', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 300,
          'media_type': 'tv_show',
          'platform_id': null,
          'thumbnail_url': 'https://image.tmdb.org/t/p/w342/poster.jpg',
        });

        expect(info.mediaType, MediaType.tvShow);
        expect(
          info.thumbnailUrl,
          'https://image.tmdb.org/t/p/w154/poster.jpg',
        );
      });

      test('должен конвертировать URL анимации в thumbnail (w154)', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 400,
          'media_type': 'animation',
          'platform_id': 1,
          'thumbnail_url': 'https://image.tmdb.org/t/p/w342/poster.jpg',
        });

        expect(info.mediaType, MediaType.animation);
        expect(info.platformId, 1);
        expect(
          info.thumbnailUrl,
          'https://image.tmdb.org/t/p/w154/poster.jpg',
        );
      });

      test('должен оставить URL визуальной новеллы без изменений', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 500,
          'media_type': 'visual_novel',
          'platform_id': null,
          'thumbnail_url': 'https://t.vndb.org/cv/12/34567.jpg',
        });

        expect(info.mediaType, MediaType.visualNovel);
        expect(
          info.thumbnailUrl,
          'https://t.vndb.org/cv/12/34567.jpg',
        );
      });

      test('должен обработать null thumbnail_url', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 600,
          'media_type': 'game',
          'platform_id': null,
          'thumbnail_url': null,
        });

        expect(info.thumbnailUrl, isNull);
      });

      test('должен обработать анимацию с источником movie (platformId=0)', () {
        final CoverInfo info = CoverInfo.fromDb(<String, Object?>{
          'external_id': 700,
          'media_type': 'animation',
          'platform_id': 0,
          'thumbnail_url': 'https://image.tmdb.org/t/p/w780/movie.jpg',
        });

        expect(info.platformId, 0);
        expect(
          info.thumbnailUrl,
          'https://image.tmdb.org/t/p/w154/movie.jpg',
        );
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковых полях', () {
        const CoverInfo a = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          platformId: 6,
          thumbnailUrl: 'url',
        );
        const CoverInfo b = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          platformId: 6,
          thumbnailUrl: 'url',
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('не должен быть равен при разных externalId', () {
        const CoverInfo a = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
        );
        const CoverInfo b = CoverInfo(
          externalId: 2,
          mediaType: MediaType.game,
        );

        expect(a, isNot(equals(b)));
      });

      test('не должен быть равен при разных mediaType', () {
        const CoverInfo a = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
        );
        const CoverInfo b = CoverInfo(
          externalId: 1,
          mediaType: MediaType.movie,
        );

        expect(a, isNot(equals(b)));
      });

      test('не должен быть равен при разных platformId', () {
        const CoverInfo a = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          platformId: 6,
        );
        const CoverInfo b = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          platformId: 7,
        );

        expect(a, isNot(equals(b)));
      });

      test('не должен быть равен при разных thumbnailUrl', () {
        const CoverInfo a = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          thumbnailUrl: 'url1',
        );
        const CoverInfo b = CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          thumbnailUrl: 'url2',
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('должен содержать все поля', () {
        const CoverInfo info = CoverInfo(
          externalId: 42,
          mediaType: MediaType.movie,
          platformId: null,
          thumbnailUrl: 'https://example.com/poster.jpg',
        );

        final String result = info.toString();

        expect(result, contains('externalId: 42'));
        expect(result, contains('mediaType: MediaType.movie'));
        expect(result, contains('thumbnailUrl: https://example.com/poster.jpg'));
      });
    });
  });
}
