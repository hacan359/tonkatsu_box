import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/collected_item_info.dart';

void main() {
  group('CollectedItemInfo', () {
    group('constructor', () {
      test('should create с обязательными полями', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 1,
          collectionId: 10,
          collectionName: 'RPG Games',
        );

        expect(info.recordId, 1);
        expect(info.collectionId, 10);
        expect(info.collectionName, 'RPG Games');
      });

      test('should create с null collectionId и collectionName', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 42,
          collectionId: null,
          collectionName: null,
        );

        expect(info.recordId, 42);
        expect(info.collectionId, isNull);
        expect(info.collectionName, isNull);
      });
    });

    group('toString', () {
      test('should return читаемое представление со всеми полями', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 1,
          collectionId: 10,
          collectionName: 'RPG Games',
        );

        final String result = info.toString();

        expect(result, contains('CollectedItemInfo'));
        expect(result, contains('recordId: 1'));
        expect(result, contains('collectionId: 10'));
        expect(result, contains('collectionName: RPG Games'));
      });

      test('должен корректно отображать null значения', () {
        const CollectedItemInfo info = CollectedItemInfo(
          recordId: 42,
          collectionId: null,
          collectionName: null,
        );

        final String result = info.toString();

        expect(result, contains('recordId: 42'));
        expect(result, contains('collectionId: null'));
        expect(result, contains('collectionName: null'));
      });
    });
  });
}
