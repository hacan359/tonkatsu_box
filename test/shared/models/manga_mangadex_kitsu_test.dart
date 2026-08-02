import 'package:core/models/data_source.dart';
import 'package:core/models/manga.dart';
import 'package:core/utils/stable_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Manga.fromMangaDex', () {
    const String uuid = 'a1c7c817-4e59-43b7-9365-09675a149a6f';

    Map<String, dynamic> mangaDexJson() => <String, dynamic>{
          'id': uuid,
          'type': 'manga',
          'attributes': <String, dynamic>{
            'title': <String, dynamic>{'en': 'Chainsaw Man'},
            'altTitles': <Map<String, dynamic>>[
              <String, dynamic>{'ja-ro': 'Chensō Man'},
              <String, dynamic>{'ja': 'チェンソーマン'},
            ],
            'description': <String, dynamic>{'en': 'Denji is <b>poor</b>.'},
            'status': 'ongoing',
            'year': 2018,
            'originalLanguage': 'ja',
            'lastChapter': '97',
            'lastVolume': '11',
            'tags': <Map<String, dynamic>>[
              <String, dynamic>{
                'attributes': <String, dynamic>{
                  'group': 'genre',
                  'name': <String, dynamic>{'en': 'Action'},
                },
              },
              <String, dynamic>{
                'attributes': <String, dynamic>{
                  'group': 'theme',
                  'name': <String, dynamic>{'en': 'Demons'},
                },
              },
            ],
          },
          'relationships': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'cover_art',
              'attributes': <String, dynamic>{'fileName': 'cover.jpg'},
            },
            <String, dynamic>{
              'type': 'author',
              'attributes': <String, dynamic>{'name': 'Tatsuki Fujimoto'},
            },
          ],
        };

    test('hashes the UUID into the numeric id and keeps it in externalUrl', () {
      final Manga m = Manga.fromMangaDex(mangaDexJson());
      expect(m.id, fnv1a64(uuid));
      expect(m.externalUrl, 'https://mangadex.org/title/$uuid');
      expect(m.source, DataSource.mangadex);
    });

    test('maps title slots, cover, status, format and tag groups', () {
      final Manga m = Manga.fromMangaDex(mangaDexJson());
      expect(m.title, 'Chensō Man');
      expect(m.titleEnglish, 'Chainsaw Man');
      expect(m.titleNative, 'チェンソーマン');
      expect(
        m.coverUrl,
        'https://uploads.mangadex.org/covers/$uuid/cover.jpg.512.jpg',
      );
      expect(m.description, 'Denji is poor.');
      expect(m.status, 'RELEASING');
      expect(m.startYear, 2018);
      expect(m.chapters, 97);
      expect(m.volumes, 11);
      expect(m.format, 'MANGA');
      expect(m.genres, <String>['Action']);
      expect(m.tags, <String>['Demons']);
      expect(m.authors, <String>['Tatsuki Fujimoto']);
    });

    test('falls back to English title when no romaji alt title exists', () {
      final Map<String, dynamic> json = mangaDexJson();
      (json['attributes'] as Map<String, dynamic>)['altTitles'] =
          <Map<String, dynamic>>[];
      final Manga m = Manga.fromMangaDex(json);
      expect(m.title, 'Chainsaw Man');
    });

    test('infers manhwa / manhua from originalLanguage', () {
      final Map<String, dynamic> ko = mangaDexJson();
      (ko['attributes'] as Map<String, dynamic>)['originalLanguage'] = 'ko';
      expect(Manga.fromMangaDex(ko).format, 'MANHWA');

      final Map<String, dynamic> zh = mangaDexJson();
      (zh['attributes'] as Map<String, dynamic>)['originalLanguage'] = 'zh';
      expect(Manga.fromMangaDex(zh).format, 'MANHUA');
    });
  });

  group('Manga.fromKitsu', () {
    Map<String, dynamic> kitsuJson() => <String, dynamic>{
          'id': '7442',
          'type': 'manga',
          'attributes': <String, dynamic>{
            'canonicalTitle': 'Vinland Saga',
            'titles': <String, dynamic>{
              'en': 'Vinland Saga',
              'en_jp': 'Vinland Saga',
              'ja_jp': 'ヴィンランド・サガ',
            },
            'synopsis': 'For a thousand years...',
            'posterImage': <String, dynamic>{
              'original': 'https://media.kitsu.io/original.jpg',
              'medium': 'https://media.kitsu.io/medium.jpg',
            },
            'coverImage': <String, dynamic>{
              'original': 'https://media.kitsu.io/banner.jpg',
            },
            'startDate': '2005-04-13',
            'averageRating': '82.55',
            'status': 'current',
            'subtype': 'manga',
            'chapterCount': 199,
            'volumeCount': 27,
            'slug': 'vinland-saga',
          },
        };

    test('maps id, source, titles, rating, counts and status', () {
      final Manga m = Manga.fromKitsu(kitsuJson());
      expect(m.id, 7442);
      expect(m.source, DataSource.kitsu);
      expect(m.title, 'Vinland Saga');
      expect(m.titleNative, 'ヴィンランド・サガ');
      expect(m.coverUrl, 'https://media.kitsu.io/original.jpg');
      expect(m.coverUrlMedium, 'https://media.kitsu.io/medium.jpg');
      expect(m.bannerUrl, 'https://media.kitsu.io/banner.jpg');
      expect(m.startYear, 2005);
      expect(m.averageScore, 83); // 82.55 rounded
      expect(m.chapters, 199);
      expect(m.volumes, 27);
      expect(m.status, 'RELEASING');
      expect(m.format, 'MANGA');
      expect(m.externalUrl, 'https://kitsu.io/manga/vinland-saga');
    });

    test('falls back to id in the URL when slug is absent', () {
      final Map<String, dynamic> json = kitsuJson();
      (json['attributes'] as Map<String, dynamic>).remove('slug');
      expect(Manga.fromKitsu(json).externalUrl, 'https://kitsu.io/manga/7442');
    });
  });
}
