import 'package:core/models/audio_track.dart';
import 'package:core/models/data_source.dart';
import 'package:test/test.dart';

void main() {
  group('AudioTrack', () {
    group('fromMusicBrainzTrack', () {
      test('parses a release media track', () {
        final AudioTrack track = AudioTrack.fromMusicBrainzTrack(
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
          audioId: 42,
          discNumber: 1,
        );

        expect(track.audioId, 42);
        expect(track.discNumber, 1);
        expect(track.position, 6);
        expect(track.title, 'Money');
        expect(track.nativeId, '7fef22bd-1111-2222-3333-444455556666');
        // The track-level length wins over the recording's.
        expect(track.lengthMs, 382000);
        expect(track.artists, isEmpty);
        expect(track.source, DataSource.musicBrainz);
      });

      test('falls back to the recording title and length', () {
        final AudioTrack track = AudioTrack.fromMusicBrainzTrack(
          <String, dynamic>{
            'position': 1,
            'recording': <String, dynamic>{
              'id': 'rec-1',
              'title': 'Speak to Me',
              'length': 68000,
            },
          },
          audioId: 42,
          discNumber: 2,
        );

        expect(track.title, 'Speak to Me');
        expect(track.lengthMs, 68000);
        expect(track.discNumber, 2);
      });

      test('keeps track-level artist credit for splits', () {
        final AudioTrack track = AudioTrack.fromMusicBrainzTrack(
          <String, dynamic>{
            'position': 1,
            'title': 'Split Side A',
            'artist-credit': <dynamic>[
              <String, dynamic>{'name': 'Artist A'},
              <String, dynamic>{'name': 'Artist B'},
            ],
          },
          audioId: 1,
          discNumber: 1,
        );

        expect(track.artists, <String>['Artist A', 'Artist B']);
      });
    });

    test('toDb / fromDb round-trips', () {
      const AudioTrack track = AudioTrack(
        audioId: 42,
        discNumber: 2,
        position: 3,
        title: 'Us and Them',
        nativeId: 'rec-3',
        lengthMs: 469000,
        artists: <String>['Pink Floyd'],
      );

      final AudioTrack restored = AudioTrack.fromDb(track.toDb());

      expect(restored.audioId, 42);
      expect(restored.discNumber, 2);
      expect(restored.position, 3);
      expect(restored.title, 'Us and Them');
      expect(restored.nativeId, 'rec-3');
      expect(restored.lengthMs, 469000);
      expect(restored.artists, <String>['Pink Floyd']);
      expect(restored.source, DataSource.musicBrainz);
    });

    test('equality is (source, audioId, disc, position)', () {
      const AudioTrack a = AudioTrack(
        audioId: 1,
        discNumber: 1,
        position: 1,
        title: 'a',
      );
      const AudioTrack b = AudioTrack(
        audioId: 1,
        discNumber: 1,
        position: 1,
        title: 'b',
      );
      const AudioTrack c = AudioTrack(
        audioId: 1,
        discNumber: 2,
        position: 1,
        title: 'a',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    group('fromPodcastIndexEpisode', () {
      test('keys the episode by its Podcast Index id at disc 0', () {
        final AudioTrack episode = AudioTrack.fromPodcastIndexEpisode(
          <String, dynamic>{
            'id': 58680086814,
            'guid': '51c2832f-b830-4368-868f-6a87a987f516',
            'title': 'Red Herring',
            'datePublished': 1786111200,
            'duration': 2164,
            'season': 0,
            'episode': 706,
          },
          audioId: 197123,
        );

        expect(episode.audioId, 197123);
        expect(episode.discNumber, 0);
        expect(episode.position, 58680086814);
        expect(episode.nativeId, '51c2832f-b830-4368-868f-6a87a987f516');
        expect(episode.lengthMs, 2164000);
        expect(episode.datePublished, 1786111200);
        expect(episode.source, DataSource.podcastIndex);
      });

      test('zero duration stays null and a missing id lands on 0', () {
        final AudioTrack episode = AudioTrack.fromPodcastIndexEpisode(
          <String, dynamic>{'title': 'Broken', 'duration': 0},
          audioId: 1,
        );
        expect(episode.position, 0);
        expect(episode.lengthMs, isNull);
      });

      test('round-trips date_published through toDb / fromDb', () {
        final AudioTrack episode = AudioTrack.fromPodcastIndexEpisode(
          <String, dynamic>{
            'id': 5,
            'title': 'Ep',
            'datePublished': 1786111200,
          },
          audioId: 7,
        );
        final AudioTrack restored = AudioTrack.fromDb(episode.toDb());
        expect(restored.datePublished, 1786111200);
        expect(restored.position, 5);
        expect(restored.discNumber, 0);
        expect(restored.source, DataSource.podcastIndex);
      });
    });
  });
}
