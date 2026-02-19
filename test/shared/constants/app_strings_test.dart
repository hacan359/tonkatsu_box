// Тесты для строковых констант приложения.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/constants/app_strings.dart';

void main() {
  group('AppStrings', () {
    test('appName должен быть Tonkatsu Box', () {
      expect(AppStrings.appName, equals('Tonkatsu Box'));
    });

    test('defaultAuthor должен быть User', () {
      expect(AppStrings.defaultAuthor, equals('User'));
    });

    test('unknown-строки не должны быть пустыми', () {
      expect(AppStrings.unknownGame, isNotEmpty);
      expect(AppStrings.unknownMovie, isNotEmpty);
      expect(AppStrings.unknownTvShow, isNotEmpty);
      expect(AppStrings.unknownAnimation, isNotEmpty);
      expect(AppStrings.unknownPlatform, isNotEmpty);
    });

    test('unknown-строки должны начинаться с Unknown', () {
      expect(AppStrings.unknownGame, startsWith('Unknown'));
      expect(AppStrings.unknownMovie, startsWith('Unknown'));
      expect(AppStrings.unknownTvShow, startsWith('Unknown'));
      expect(AppStrings.unknownAnimation, startsWith('Unknown'));
      expect(AppStrings.unknownPlatform, startsWith('Unknown'));
    });
  });
}
