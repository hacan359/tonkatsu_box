import 'package:test/test.dart';
import 'package:tonkatsu_server/src/request_log.dart';

void main() {
  group('redactedTarget', () {
    test('should mask every credential-bearing query parameter', () {
      final Uri uri = Uri.parse(
        'proxy/tmdb/3/search/movie'
        '?api_key=secret1&query=fox&y=secret2&sspassword=secret3',
      );

      final String target = redactedTarget(uri);

      expect(target, contains('api_key=***'));
      expect(target, contains('y=***'));
      expect(target, contains('sspassword=***'));
      expect(target, contains('query=fox'));
      expect(target, isNot(contains('secret')));
    });

    test('should mask case-insensitively', () {
      final Uri uri = Uri.parse('proxy/x?API_KEY=secret');

      expect(redactedTarget(uri), contains('API_KEY=***'));
    });

    test('should leave the image source URL readable', () {
      final Uri uri = Uri.parse(
        'img/movie_posters/1?src=https%3A%2F%2Fcdn.example%2Fa.jpg',
      );

      expect(redactedTarget(uri), contains('src=https'));
    });

    test('should print a bare path unchanged', () {
      expect(redactedTarget(Uri.parse('rpc')), '/rpc');
    });
  });
}
