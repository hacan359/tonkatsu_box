import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';

void main() {
  Map<String, dynamic> resource(Map<String, dynamic> attributes) =>
      <String, dynamic>{
        'id': '104938',
        'type': 'episodes',
        'attributes': attributes,
      };

  group('TvEpisode.tryFromKitsu', () {
    test('maps every field and stamps the kitsu source', () {
      final TvEpisode? ep = TvEpisode.tryFromKitsu(
        resource(<String, dynamic>{
          'seasonNumber': 2,
          'number': 3,
          'canonicalTitle': 'To You Two Thousand Years Later',
          'titles': <String, dynamic>{'en_jp': 'Ni Sen-Nen-Go no Kimi e'},
          'synopsis': 'The Fall of Shiganshina.',
          'airdate': '2013-04-06',
          'length': 24,
          'thumbnail': <String, dynamic>{
            'original': 'https://media.kitsu.app/e/original.jpg',
          },
        }),
        showId: 7442,
      );

      expect(ep, isNotNull);
      expect(ep!.tmdbShowId, 7442);
      expect(ep.seasonNumber, 2);
      expect(ep.episodeNumber, 3);
      expect(ep.name, 'To You Two Thousand Years Later');
      expect(ep.overview, 'The Fall of Shiganshina.');
      expect(ep.airDate, '2013-04-06');
      expect(ep.runtime, 24);
      expect(ep.stillUrl, 'https://media.kitsu.app/e/original.jpg');
      expect(ep.source, DataSource.kitsu);
    });

    test('falls back through the title map when canonicalTitle is absent', () {
      final TvEpisode? ep = TvEpisode.tryFromKitsu(
        resource(<String, dynamic>{
          'number': 1,
          'titles': <String, dynamic>{'en_jp': 'Romaji', 'ja_jp': 'Native'},
        }),
        showId: 1,
      );

      expect(ep!.name, 'Romaji');
    });

    test('defaults a missing season number to the synthesized season 1', () {
      final TvEpisode? ep = TvEpisode.tryFromKitsu(
        resource(<String, dynamic>{'number': 5}),
        showId: 1,
      );

      expect(ep!.seasonNumber, 1);
      expect(ep.episodeNumber, 5);
    });

    test('returns null when the episode number is missing', () {
      expect(
        TvEpisode.tryFromKitsu(
          resource(<String, dynamic>{'seasonNumber': 1}),
          showId: 1,
        ),
        isNull,
      );
    });

    test('empty strings and absent nested images read as null', () {
      final TvEpisode? ep = TvEpisode.tryFromKitsu(
        resource(<String, dynamic>{
          'number': 2,
          'canonicalTitle': '',
          'synopsis': '',
          'airdate': '',
          'thumbnail': null,
        }),
        showId: 1,
      );

      expect(ep!.name, '');
      expect(ep.overview, isNull);
      expect(ep.airDate, isNull);
      expect(ep.stillUrl, isNull);
    });

    test('attributes may be absent entirely', () {
      expect(
        TvEpisode.tryFromKitsu(
          <String, dynamic>{'id': '1', 'type': 'episodes'},
          showId: 1,
        ),
        isNull,
      );
    });
  });
}
