import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:test/test.dart';

void main() {
  group('coverImageId', () {
    test('namespaces manga by source', () {
      expect(
        coverImageId(
          mediaType: MediaType.manga,
          externalId: 1995,
          source: DataSource.mangabaka,
        ),
        'mangabaka_1995',
      );
      expect(
        coverImageId(
          mediaType: MediaType.manga,
          externalId: 1995,
          source: DataSource.anilist,
        ),
        'anilist_1995',
      );
    });

    test('manga with null source defaults to anilist', () {
      expect(
        coverImageId(mediaType: MediaType.manga, externalId: 1995),
        'anilist_1995',
      );
    });

    test('namespaces anime by source', () {
      expect(
        coverImageId(
          mediaType: MediaType.anime,
          externalId: 7442,
          source: DataSource.kitsu,
        ),
        'kitsu_7442',
      );
      expect(
        coverImageId(mediaType: MediaType.anime, externalId: 7442),
        'anilist_7442',
      );
    });

    test('manga key contains exactly one separator usable for import split', () {
      final String id = coverImageId(
        mediaType: MediaType.manga,
        externalId: 1995,
        source: DataSource.mangabaka,
      );
      // Import splits `folder/imageId` on '/', so the id itself must not add
      // a second slash.
      expect(id.contains('/'), isFalse);
    });

    test('book without a cover URL keeps the source-namespaced base id', () {
      expect(
        coverImageId(
          mediaType: MediaType.book,
          externalId: 3104,
          source: DataSource.fantlab,
        ),
        'fantlab_3104',
      );
      expect(
        coverImageId(mediaType: MediaType.book, externalId: 27448),
        'openLibrary_27448',
      );
    });

    test('book key includes the Fantlab edition id from the cover URL', () {
      expect(
        coverImageId(
          mediaType: MediaType.book,
          externalId: 3104,
          source: DataSource.fantlab,
          coverUrl: 'https://fantlab.ru/images/editions/big/24724?r=1',
        ),
        'fantlab_3104_e24724',
      );
      // A different edition is a distinct key — no stale cover reuse.
      expect(
        coverImageId(
          mediaType: MediaType.book,
          externalId: 3104,
          source: DataSource.fantlab,
          coverUrl: 'https://fantlab.ru/images/editions/big/7337',
        ),
        'fantlab_3104_e7337',
      );
    });

    test('book key ignores a non-edition cover URL (OpenLibrary)', () {
      expect(
        coverImageId(
          mediaType: MediaType.book,
          externalId: 27448,
          source: DataSource.openLibrary,
          coverUrl: 'https://covers.openlibrary.org/b/id/123-L.jpg',
        ),
        'openLibrary_27448',
      );
    });

    test('namespaces TV shows by source', () {
      expect(
        coverImageId(
          mediaType: MediaType.tvShow,
          externalId: 1399,
          source: DataSource.tvmaze,
        ),
        'tvmaze_1399',
      );
      expect(
        coverImageId(
          mediaType: MediaType.tvShow,
          externalId: 1399,
          source: DataSource.tmdb,
        ),
        'tmdb_1399',
      );
    });

    test('TV show with null source defaults to tmdb', () {
      expect(
        coverImageId(mediaType: MediaType.tvShow, externalId: 1399),
        'tmdb_1399',
      );
    });

    test('animation stays bare — it only comes from TMDB', () {
      expect(
        coverImageId(
          mediaType: MediaType.animation,
          externalId: 1399,
          source: DataSource.tmdb,
        ),
        '1399',
      );
    });

    test('single-source types keep the bare external id', () {
      for (final MediaType type in <MediaType>[
        MediaType.game,
        MediaType.visualNovel,
        MediaType.custom,
      ]) {
        expect(
          coverImageId(mediaType: type, externalId: 42),
          '42',
        );
      }
    });
  });
}
