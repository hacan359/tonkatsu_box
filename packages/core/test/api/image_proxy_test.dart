import 'package:core/api/image_proxy.dart';
import 'package:core/models/image_type.dart';
import 'package:test/test.dart';

void main() {
  group('imageProxyPath', () {
    test('should address the cache by folder and id', () {
      expect(
        imageProxyPath(type: ImageType.gameCover, imageId: '42'),
        '/img/game_covers/42',
      );
    });

    test('should carry the source URL as an encoded query parameter', () {
      final String path = imageProxyPath(
        type: ImageType.moviePoster,
        imageId: '7',
        sourceUrl: 'https://cdn.example.com/a b.jpg',
      );

      expect(path, startsWith('/img/movie_posters/7?src='));
      expect(
        Uri.parse(path).queryParameters[kImageSourceParam],
        'https://cdn.example.com/a b.jpg',
      );
    });
  });

  group('imageProxyUrl', () {
    test('should prefix the path with the server origin', () {
      expect(
        imageProxyUrl(
          baseUrl: 'http://localhost:8080',
          type: ImageType.collectionHero,
          imageId: 'hero_1_2.jpg',
        ),
        'http://localhost:8080/img/collection_heroes/hero_1_2.jpg',
      );
    });
  });

  group('imageTypeForFolder', () {
    test('should round-trip every ImageType through its folder', () {
      for (final ImageType type in ImageType.values) {
        expect(imageTypeForFolder(type.folder), type);
      }
    });

    test('should return null for an unknown folder', () {
      expect(imageTypeForFolder('nonsense'), isNull);
    });
  });
}
