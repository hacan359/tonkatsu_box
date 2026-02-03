import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/platform.dart';

void main() {
  group('Platform', () {
    const int testId = 1;
    const String testName = 'Super Nintendo Entertainment System';
    const String testAbbreviation = 'SNES';
    const int testSyncedAt = 1700000000;

    group('constructor', () {
      test('должен создать Platform с обязательными полями', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
        );

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, isNull);
        expect(platform.syncedAt, isNull);
      });

      test('должен создать Platform со всеми полями', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
          syncedAt: testSyncedAt,
        );

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, equals(testAbbreviation));
        expect(platform.syncedAt, equals(testSyncedAt));
      });
    });

    group('fromJson', () {
      test('должен создать Platform из JSON с полными данными', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': testAbbreviation,
        };

        final Platform platform = Platform.fromJson(json);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, equals(testAbbreviation));
        expect(platform.syncedAt, isNotNull);
      });

      test('должен создать Platform из JSON без abbreviation', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': null,
        };

        final Platform platform = Platform.fromJson(json);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, isNull);
      });
    });

    group('fromDb', () {
      test('должен создать Platform из записи БД с полными данными', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': testAbbreviation,
          'synced_at': testSyncedAt,
        };

        final Platform platform = Platform.fromDb(row);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, equals(testAbbreviation));
        expect(platform.syncedAt, equals(testSyncedAt));
      });

      test('должен создать Platform из записи БД с null полями', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': null,
          'synced_at': null,
        };

        final Platform platform = Platform.fromDb(row);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, isNull);
        expect(platform.syncedAt, isNull);
      });
    });

    group('toDb', () {
      test('должен конвертировать в Map для БД', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
          syncedAt: testSyncedAt,
        );

        final Map<String, dynamic> result = platform.toDb();

        expect(result['id'], equals(testId));
        expect(result['name'], equals(testName));
        expect(result['abbreviation'], equals(testAbbreviation));
        expect(result['synced_at'], equals(testSyncedAt));
      });

      test('должен сохранять null значения', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
        );

        final Map<String, dynamic> result = platform.toDb();

        expect(result['abbreviation'], isNull);
        expect(result['synced_at'], isNull);
      });
    });

    group('toJson', () {
      test('должен конвертировать в JSON', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        final Map<String, dynamic> result = platform.toJson();

        expect(result['id'], equals(testId));
        expect(result['name'], equals(testName));
        expect(result['abbreviation'], equals(testAbbreviation));
        expect(result.containsKey('synced_at'), isFalse);
      });
    });

    group('displayName', () {
      test('должен вернуть abbreviation когда оно есть', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        expect(platform.displayName, equals(testAbbreviation));
      });

      test('должен вернуть name когда abbreviation null', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
        );

        expect(platform.displayName, equals(testName));
      });
    });

    group('equality', () {
      test('должен быть равен другому Platform с тем же id', () {
        const Platform platform1 = Platform(id: testId, name: testName);
        const Platform platform2 = Platform(id: testId, name: 'Other Name');

        expect(platform1, equals(platform2));
      });

      test('не должен быть равен Platform с другим id', () {
        const Platform platform1 = Platform(id: 1, name: testName);
        const Platform platform2 = Platform(id: 2, name: testName);

        expect(platform1, isNot(equals(platform2)));
      });

      test('должен быть равен самому себе', () {
        const Platform platform = Platform(id: testId, name: testName);

        expect(platform == platform, isTrue);
      });

      test('не должен быть равен объекту другого типа', () {
        const Platform platform = Platform(id: testId, name: testName);
        const Object other = 'not a platform';

        expect(platform == other, isFalse);
      });
    });

    group('hashCode', () {
      test('должен иметь одинаковый hashCode для равных объектов', () {
        const Platform platform1 = Platform(id: testId, name: testName);
        const Platform platform2 = Platform(id: testId, name: 'Other Name');

        expect(platform1.hashCode, equals(platform2.hashCode));
      });
    });

    group('toString', () {
      test('должен вернуть строковое представление', () {
        const Platform platform = Platform(id: testId, name: testName);

        expect(platform.toString(), equals('Platform(id: $testId, name: $testName)'));
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменённым id', () {
        const Platform original = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
          syncedAt: testSyncedAt,
        );

        final Platform copy = original.copyWith(id: 999);

        expect(copy.id, equals(999));
        expect(copy.name, equals(testName));
        expect(copy.abbreviation, equals(testAbbreviation));
        expect(copy.syncedAt, equals(testSyncedAt));
      });

      test('должен создать копию с изменённым name', () {
        const Platform original = Platform(id: testId, name: testName);

        final Platform copy = original.copyWith(name: 'New Name');

        expect(copy.id, equals(testId));
        expect(copy.name, equals('New Name'));
      });

      test('должен создать копию с изменённым abbreviation', () {
        const Platform original = Platform(id: testId, name: testName);

        final Platform copy = original.copyWith(abbreviation: 'NEW');

        expect(copy.abbreviation, equals('NEW'));
      });

      test('должен создать копию с изменённым syncedAt', () {
        const Platform original = Platform(id: testId, name: testName);

        final Platform copy = original.copyWith(syncedAt: 9999);

        expect(copy.syncedAt, equals(9999));
      });

      test('должен сохранить все поля при пустом copyWith', () {
        const Platform original = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
          syncedAt: testSyncedAt,
        );

        final Platform copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.name, equals(original.name));
        expect(copy.abbreviation, equals(original.abbreviation));
        expect(copy.syncedAt, equals(original.syncedAt));
      });
    });
  });
}
