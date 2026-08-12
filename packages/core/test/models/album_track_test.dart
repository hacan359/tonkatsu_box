import 'package:core/models/album_track.dart';
import 'package:core/models/data_source.dart';
import 'package:test/test.dart';

void main() {
  group('AlbumTrack', () {
    group('fromMusicBrainzTrack', () {
      test('parses a release media track', () {
        final AlbumTrack track = AlbumTrack.fromMusicBrainzTrack(
          <String, dynamic>{
            'position': 6,
            'title': 'Money',
            'length': 382000,
            'recording': <String, dynamic>{
              'id': '7fef22bd-1111-2222-3333-444455556666',
              'title': 'Money',
              'length': 382834,
            },
          },
          albumId: 42,
          discNumber: 1,
        );

        expect(track.albumId, 42);
        expect(track.discNumber, 1);
        expect(track.position, 6);
        expect(track.title, 'Money');
        expect(track.recordingMbid, '7fef22bd-1111-2222-3333-444455556666');
        // The track-level length wins over the recording's.
        expect(track.lengthMs, 382000);
        expect(track.artists, isEmpty);
        expect(track.source, DataSource.musicBrainz);
      });

      test('falls back to the recording title and length', () {
        final AlbumTrack track = AlbumTrack.fromMusicBrainzTrack(
          <String, dynamic>{
            'position': 1,
            'recording': <String, dynamic>{
              'id': 'rec-1',
              'title': 'Speak to Me',
              'length': 68000,
            },
          },
          albumId: 42,
          discNumber: 2,
        );

        expect(track.title, 'Speak to Me');
        expect(track.lengthMs, 68000);
        expect(track.discNumber, 2);
      });

      test('keeps track-level artist credit for splits', () {
        final AlbumTrack track = AlbumTrack.fromMusicBrainzTrack(
          <String, dynamic>{
            'position': 1,
            'title': 'Split Side A',
            'artist-credit': <dynamic>[
              <String, dynamic>{'name': 'Artist A'},
              <String, dynamic>{'name': 'Artist B'},
            ],
          },
          albumId: 1,
          discNumber: 1,
        );

        expect(track.artists, <String>['Artist A', 'Artist B']);
      });
    });

    test('toDb / fromDb round-trips', () {
      const AlbumTrack track = AlbumTrack(
        albumId: 42,
        discNumber: 2,
        position: 3,
        title: 'Us and Them',
        recordingMbid: 'rec-3',
        lengthMs: 469000,
        artists: <String>['Pink Floyd'],
      );

      final AlbumTrack restored = AlbumTrack.fromDb(track.toDb());

      expect(restored.albumId, 42);
      expect(restored.discNumber, 2);
      expect(restored.position, 3);
      expect(restored.title, 'Us and Them');
      expect(restored.recordingMbid, 'rec-3');
      expect(restored.lengthMs, 469000);
      expect(restored.artists, <String>['Pink Floyd']);
      expect(restored.source, DataSource.musicBrainz);
    });

    test('equality is (source, albumId, disc, position)', () {
      const AlbumTrack a = AlbumTrack(
        albumId: 1,
        discNumber: 1,
        position: 1,
        title: 'a',
      );
      const AlbumTrack b = AlbumTrack(
        albumId: 1,
        discNumber: 1,
        position: 1,
        title: 'b',
      );
      const AlbumTrack c = AlbumTrack(
        albumId: 1,
        discNumber: 2,
        position: 1,
        title: 'a',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
