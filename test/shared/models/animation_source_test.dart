// Тесты для модели AnimationSource

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  group('AnimationSource', () {
    test('movie должен равняться 0', () {
      expect(AnimationSource.movie, 0);
    });

    test('tvShow должен равняться 1', () {
      expect(AnimationSource.tvShow, 1);
    });

    test('movie и tvShow должны быть различными значениями', () {
      expect(AnimationSource.movie, isNot(equals(AnimationSource.tvShow)));
    });
  });
}
