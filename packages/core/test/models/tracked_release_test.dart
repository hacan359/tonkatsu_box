import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tracked_release.dart';
import 'package:test/test.dart';

void main() {
  group('TrackedRelease', () {
    final DateTime createdAt =
        DateTime.fromMillisecondsSinceEpoch(1700000000000);

    group('toDb', () {
      test('writes the identity triple and the subscription date', () {
        final TrackedRelease release = TrackedRelease(
          externalId: 42,
          source: DataSource.anilist,
          mediaType: MediaType.anime,
          createdAt: createdAt,
        );

        expect(release.toDb(), <String, dynamic>{
          'external_id': 42,
          'source': 'anilist',
          'media_type': 'anime',
          'created_at': 1700000000000,
        });
      });

      test('stores created_at in milliseconds, not seconds', () {
        final TrackedRelease release = TrackedRelease(
          externalId: 1,
          source: DataSource.tmdb,
          mediaType: MediaType.movie,
          createdAt: createdAt,
        );

        expect(release.toDb()['created_at'], createdAt.millisecondsSinceEpoch);
      });
    });

    group('fromDb', () {
      test('round-trips through toDb', () {
        final TrackedRelease original = TrackedRelease(
          externalId: 7,
          source: DataSource.mangabaka,
          mediaType: MediaType.manga,
          createdAt: createdAt,
        );

        final TrackedRelease back = TrackedRelease.fromDb(original.toDb());

        expect(back.externalId, original.externalId);
        expect(back.source, original.source);
        expect(back.mediaType, original.mediaType);
        expect(back.createdAt, original.createdAt);
      });

      test('falls back to a default source for a NULL source column', () {
        final TrackedRelease back = TrackedRelease.fromDb(<String, dynamic>{
          'external_id': 7,
          'source': null,
          'media_type': 'anime',
          'created_at': 1700000000000,
        });

        expect(back.source, DataSource.fromName(null));
      });
    });
  });
}
