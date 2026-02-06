import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/steamgriddb_image.dart';

void main() {
  group('SteamGridDbImage', () {
    group('fromJson', () {
      test('парсит полный JSON с author корректно', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 12345,
          'score': 5,
          'style': 'alternate',
          'url': 'https://cdn2.steamgriddb.com/file/full.png',
          'thumb': 'https://cdn2.steamgriddb.com/file/thumb.png',
          'width': 600,
          'height': 900,
          'mime': 'image/png',
          'author': <String, dynamic>{
            'name': 'ArtistName',
            'steam64': '76561198000000000',
            'avatar': 'https://example.com/avatar.jpg',
          },
        };

        final SteamGridDbImage image = SteamGridDbImage.fromJson(json);

        expect(image.id, 12345);
        expect(image.score, 5);
        expect(image.style, 'alternate');
        expect(image.url, 'https://cdn2.steamgriddb.com/file/full.png');
        expect(image.thumb, 'https://cdn2.steamgriddb.com/file/thumb.png');
        expect(image.width, 600);
        expect(image.height, 900);
        expect(image.mime, 'image/png');
        expect(image.author, 'ArtistName');
      });

      test('парсит минимальный JSON без author', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 999,
          'score': 0,
          'style': 'material',
          'url': 'https://cdn2.steamgriddb.com/file/img.jpg',
          'thumb': 'https://cdn2.steamgriddb.com/file/thumb.jpg',
          'width': 460,
          'height': 215,
        };

        final SteamGridDbImage image = SteamGridDbImage.fromJson(json);

        expect(image.id, 999);
        expect(image.mime, isNull);
        expect(image.author, isNull);
      });

      test('обрабатывает null author', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 100,
          'score': 3,
          'style': 'blurred',
          'url': 'https://example.com/img.png',
          'thumb': 'https://example.com/thumb.png',
          'width': 920,
          'height': 430,
          'author': null,
        };

        final SteamGridDbImage image = SteamGridDbImage.fromJson(json);

        expect(image.author, isNull);
      });

      test('обрабатывает author без name', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 200,
          'score': 1,
          'style': 'white_logo',
          'url': 'https://example.com/img.png',
          'thumb': 'https://example.com/thumb.png',
          'width': 512,
          'height': 512,
          'author': <String, dynamic>{
            'steam64': '76561198000000000',
          },
        };

        final SteamGridDbImage image = SteamGridDbImage.fromJson(json);

        expect(image.author, isNull);
      });

      test('обрабатывает null mime', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 300,
          'score': 2,
          'style': 'alternate',
          'url': 'https://example.com/img.webp',
          'thumb': 'https://example.com/thumb.webp',
          'width': 342,
          'height': 482,
          'mime': null,
        };

        final SteamGridDbImage image = SteamGridDbImage.fromJson(json);

        expect(image.mime, isNull);
      });
    });

    group('dimensions', () {
      test('возвращает строку размера', () {
        const SteamGridDbImage image = SteamGridDbImage(
          id: 1,
          score: 0,
          style: 'alt',
          url: 'url',
          thumb: 'thumb',
          width: 600,
          height: 900,
        );

        expect(image.dimensions, '600x900');
      });
    });

    group('copyWith', () {
      test('создаёт копию с изменёнными полями', () {
        const SteamGridDbImage original = SteamGridDbImage(
          id: 1,
          score: 5,
          style: 'alternate',
          url: 'https://old.com/img.png',
          thumb: 'https://old.com/thumb.png',
          width: 600,
          height: 900,
          mime: 'image/png',
          author: 'OldAuthor',
        );

        final SteamGridDbImage copy = original.copyWith(
          score: 10,
          author: 'NewAuthor',
        );

        expect(copy.id, 1);
        expect(copy.score, 10);
        expect(copy.style, 'alternate');
        expect(copy.author, 'NewAuthor');
      });

      test('сохраняет неизменённые поля', () {
        const SteamGridDbImage original = SteamGridDbImage(
          id: 1,
          score: 5,
          style: 'material',
          url: 'https://example.com/img.png',
          thumb: 'https://example.com/thumb.png',
          width: 460,
          height: 215,
          mime: 'image/jpeg',
        );

        final SteamGridDbImage copy = original.copyWith(score: 99);

        expect(copy.url, 'https://example.com/img.png');
        expect(copy.mime, 'image/jpeg');
        expect(copy.width, 460);
      });
    });

    group('equality', () {
      test('изображения с одинаковым id равны', () {
        const SteamGridDbImage img1 = SteamGridDbImage(
          id: 1,
          score: 5,
          style: 'a',
          url: 'url1',
          thumb: 'thumb1',
          width: 100,
          height: 200,
        );
        const SteamGridDbImage img2 = SteamGridDbImage(
          id: 1,
          score: 10,
          style: 'b',
          url: 'url2',
          thumb: 'thumb2',
          width: 300,
          height: 400,
        );

        expect(img1, equals(img2));
        expect(img1.hashCode, equals(img2.hashCode));
      });

      test('изображения с разными id не равны', () {
        const SteamGridDbImage img1 = SteamGridDbImage(
          id: 1,
          score: 5,
          style: 'a',
          url: 'url',
          thumb: 'thumb',
          width: 100,
          height: 200,
        );
        const SteamGridDbImage img2 = SteamGridDbImage(
          id: 2,
          score: 5,
          style: 'a',
          url: 'url',
          thumb: 'thumb',
          width: 100,
          height: 200,
        );

        expect(img1, isNot(equals(img2)));
      });
    });

    group('toString', () {
      test('возвращает читаемое представление', () {
        const SteamGridDbImage image = SteamGridDbImage(
          id: 42,
          score: 3,
          style: 'material',
          url: 'url',
          thumb: 'thumb',
          width: 600,
          height: 900,
        );

        expect(
          image.toString(),
          'SteamGridDbImage(id: 42, style: material, 600x900)',
        );
      });
    });
  });
}
