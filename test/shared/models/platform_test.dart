import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/platform.dart';

void main() {
  group('Platform', () {
    const int testId = 1;
    const String testName = 'Super Nintendo Entertainment System';
    const String testAbbreviation = 'SNES';

    group('constructor', () {
      test('should create Platform с обязательными полями', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
        );

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, isNull);
      });

      test('should create Platform со всеми полями', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, equals(testAbbreviation));
      });
    });

    group('fromJson', () {
      test('should create Platform из JSON с полными данными', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': testAbbreviation,
        };

        final Platform platform = Platform.fromJson(json);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, equals(testAbbreviation));
      });

      test('should create Platform из JSON без abbreviation', () {
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
      test('should create Platform из записи БД с полными данными', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': testAbbreviation,
        };

        final Platform platform = Platform.fromDb(row);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, equals(testAbbreviation));
      });

      test('should create Platform из записи БД с null полями', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': testId,
          'name': testName,
          'abbreviation': null,
        };

        final Platform platform = Platform.fromDb(row);

        expect(platform.id, equals(testId));
        expect(platform.name, equals(testName));
        expect(platform.abbreviation, isNull);
      });
    });

    group('toDb', () {
      test('должен конвертировать в Map для БД', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        final Map<String, dynamic> result = platform.toDb();

        expect(result['id'], equals(testId));
        expect(result['name'], equals(testName));
        expect(result['abbreviation'], equals(testAbbreviation));
      });

      test('should preserve null значения', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
        );

        final Map<String, dynamic> result = platform.toDb();

        expect(result['abbreviation'], isNull);
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
      });
    });

    group('displayName', () {
      test('should return abbreviation когда оно есть', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        expect(platform.displayName, equals(testAbbreviation));
      });

      test('should return name когда abbreviation null', () {
        const Platform platform = Platform(
          id: testId,
          name: testName,
        );

        expect(platform.displayName, equals(testName));
      });
    });

    group('equality', () {
      test('should be equal другому Platform с тем же id', () {
        const Platform platform1 = Platform(id: testId, name: testName);
        const Platform platform2 = Platform(id: testId, name: 'Other Name');

        expect(platform1, equals(platform2));
      });

      test('не should be equal Platform с другим id', () {
        const Platform platform1 = Platform(id: 1, name: testName);
        const Platform platform2 = Platform(id: 2, name: testName);

        expect(platform1, isNot(equals(platform2)));
      });

      test('should be equal самому себе', () {
        const Platform platform = Platform(id: testId, name: testName);

        expect(platform == platform, isTrue);
      });

      test('не should be equal объекту другого типа', () {
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
      test('should return строковое представление', () {
        const Platform platform = Platform(id: testId, name: testName);

        expect(platform.toString(), equals('Platform(id: $testId, name: $testName)'));
      });
    });

    group('copyWith', () {
      test('should create копию с изменённым id', () {
        const Platform original = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        final Platform copy = original.copyWith(id: 999);

        expect(copy.id, equals(999));
        expect(copy.name, equals(testName));
        expect(copy.abbreviation, equals(testAbbreviation));
      });

      test('should create копию с изменённым name', () {
        const Platform original = Platform(id: testId, name: testName);

        final Platform copy = original.copyWith(name: 'New Name');

        expect(copy.id, equals(testId));
        expect(copy.name, equals('New Name'));
      });

      test('should create копию с изменённым abbreviation', () {
        const Platform original = Platform(id: testId, name: testName);

        final Platform copy = original.copyWith(abbreviation: 'NEW');

        expect(copy.abbreviation, equals('NEW'));
      });

      test('should preserve все поля when empty copyWith', () {
        const Platform original = Platform(
          id: testId,
          name: testName,
          abbreviation: testAbbreviation,
        );

        final Platform copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.name, equals(original.name));
        expect(copy.abbreviation, equals(original.abbreviation));
      });
    });
  });
}
