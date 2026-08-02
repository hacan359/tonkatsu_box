import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/utils/url_launch.dart';

void main() {
  group('openUrlCallback', () {
    test('should return null when url is null', () {
      expect(openUrlCallback(null), isNull);
    });

    test('should return null when url is empty', () {
      expect(openUrlCallback(''), isNull);
    });

    test('should return a handler when url is present', () {
      expect(openUrlCallback('https://anilist.co/manga/30002'),
          isA<VoidCallback>());
    });
  });
}
