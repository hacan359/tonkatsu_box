import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

void main() {
  group('Anime.fromKitsu', () {
    Map<String, dynamic> kitsuJson() => <String, dynamic>{
          'id': '7442',
          'type': 'anime',
          'attributes': <String, dynamic>{
            'canonicalTitle': 'Frieren',
            'titles': <String, dynamic>{
              'en': 'Frieren: Beyond Journey\'s End',
              'en_jp': 'Sousou no Frieren',
              'ja_jp': '葬送のフリーレン',
            },
            'synopsis': 'The elf mage Frieren...',
            'posterImage': <String, dynamic>{
              'original': 'https://media.kitsu.io/original.jpg',
              'medium': 'https://media.kitsu.io/medium.jpg',
            },
            'coverImage': <String, dynamic>{
              'original': 'https://media.kitsu.io/banner.jpg',
            },
            'startDate': '2023-09-29',
            'averageRating': '86.10',
            'status': 'finished',
            'subtype': 'TV',
            'episodeCount': 28,
            'episodeLength': 24,
            'slug': 'frieren',
          },
        };

    test('maps id, titles, rating, episodes, status and format', () {
      final Anime a = Anime.fromKitsu(kitsuJson());
      expect(a.id, 7442);
      expect(a.source, DataSource.kitsu);
      expect(a.title, 'Sousou no Frieren');
      expect(a.titleEnglish, "Frieren: Beyond Journey's End");
      expect(a.titleNative, '葬送のフリーレン');
      expect(a.coverUrl, 'https://media.kitsu.io/original.jpg');
      expect(a.bannerUrl, 'https://media.kitsu.io/banner.jpg');
      expect(a.startYear, 2023);
      expect(a.averageScore, 86);
      expect(a.episodes, 28);
      expect(a.duration, 24);
      expect(a.status, 'FINISHED');
      expect(a.format, 'TV');
      expect(a.externalUrl, 'https://kitsu.io/anime/frieren');
    });
  });
}
