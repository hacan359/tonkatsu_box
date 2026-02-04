import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection.dart';

void main() {
  group('CollectionType', () {
    test('должен иметь правильные строковые значения', () {
      expect(CollectionType.own.value, 'own');
      expect(CollectionType.imported.value, 'imported');
      expect(CollectionType.fork.value, 'fork');
    });

    test('fromString должен возвращать правильный тип', () {
      expect(CollectionType.fromString('own'), CollectionType.own);
      expect(CollectionType.fromString('imported'), CollectionType.imported);
      expect(CollectionType.fromString('fork'), CollectionType.fork);
    });

    test('fromString должен возвращать own для неизвестного значения', () {
      expect(CollectionType.fromString('unknown'), CollectionType.own);
      expect(CollectionType.fromString(''), CollectionType.own);
    });
  });

  group('Collection', () {
    final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    Collection createTestCollection({
      int id = 1,
      String name = 'Test Collection',
      String author = 'Test Author',
      CollectionType type = CollectionType.own,
      DateTime? createdAt,
      String? originalSnapshot,
      String? forkedFromAuthor,
      String? forkedFromName,
    }) {
      return Collection(
        id: id,
        name: name,
        author: author,
        type: type,
        createdAt: createdAt ?? testDate,
        originalSnapshot: originalSnapshot,
        forkedFromAuthor: forkedFromAuthor,
        forkedFromName: forkedFromName,
      );
    }

    group('constructor', () {
      test('должен создавать экземпляр с обязательными полями', () {
        final Collection collection = createTestCollection();

        expect(collection.id, 1);
        expect(collection.name, 'Test Collection');
        expect(collection.author, 'Test Author');
        expect(collection.type, CollectionType.own);
        expect(collection.createdAt, testDate);
      });

      test('должен создавать экземпляр с опциональными полями', () {
        final Collection collection = createTestCollection(
          originalSnapshot: '{"games": []}',
          forkedFromAuthor: 'Original Author',
          forkedFromName: 'Original Collection',
        );

        expect(collection.originalSnapshot, '{"games": []}');
        expect(collection.forkedFromAuthor, 'Original Author');
        expect(collection.forkedFromName, 'Original Collection');
      });
    });

    group('fromDb', () {
      test('должен создавать Collection из записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'name': 'My Collection',
          'author': 'Author',
          'type': 'own',
          'created_at': testTimestamp,
          'original_snapshot': null,
          'forked_from_author': null,
          'forked_from_name': null,
        };

        final Collection collection = Collection.fromDb(row);

        expect(collection.id, 1);
        expect(collection.name, 'My Collection');
        expect(collection.author, 'Author');
        expect(collection.type, CollectionType.own);
        expect(collection.createdAt.millisecondsSinceEpoch ~/ 1000, testTimestamp);
      });

      test('должен создавать fork Collection из записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 2,
          'name': 'Forked Collection',
          'author': 'Fork Author',
          'type': 'fork',
          'created_at': testTimestamp,
          'original_snapshot': '{"games": [1, 2, 3]}',
          'forked_from_author': 'Original Author',
          'forked_from_name': 'Original Name',
        };

        final Collection collection = Collection.fromDb(row);

        expect(collection.id, 2);
        expect(collection.type, CollectionType.fork);
        expect(collection.originalSnapshot, '{"games": [1, 2, 3]}');
        expect(collection.forkedFromAuthor, 'Original Author');
        expect(collection.forkedFromName, 'Original Name');
      });

      test('должен обрабатывать imported тип', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 3,
          'name': 'Imported',
          'author': 'Someone',
          'type': 'imported',
          'created_at': testTimestamp,
          'original_snapshot': null,
          'forked_from_author': null,
          'forked_from_name': null,
        };

        final Collection collection = Collection.fromDb(row);
        expect(collection.type, CollectionType.imported);
      });
    });

    group('isEditable', () {
      test('должен возвращать true для own коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.own);
        expect(collection.isEditable, true);
      });

      test('должен возвращать true для fork коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.fork);
        expect(collection.isEditable, true);
      });

      test('должен возвращать false для imported коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.imported);
        expect(collection.isEditable, false);
      });
    });

    group('isFork', () {
      test('должен возвращать true для fork коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.fork);
        expect(collection.isFork, true);
      });

      test('должен возвращать false для own коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.own);
        expect(collection.isFork, false);
      });
    });

    group('isImported', () {
      test('должен возвращать true для imported коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.imported);
        expect(collection.isImported, true);
      });

      test('должен возвращать false для own коллекции', () {
        final Collection collection = createTestCollection(type: CollectionType.own);
        expect(collection.isImported, false);
      });
    });

    group('toDb', () {
      test('должен возвращать корректную Map для БД', () {
        final Collection collection = createTestCollection();
        final Map<String, dynamic> db = collection.toDb();

        expect(db['id'], 1);
        expect(db['name'], 'Test Collection');
        expect(db['author'], 'Test Author');
        expect(db['type'], 'own');
        expect(db['created_at'], testTimestamp);
        expect(db['original_snapshot'], null);
        expect(db['forked_from_author'], null);
        expect(db['forked_from_name'], null);
      });

      test('должен включать fork поля', () {
        final Collection collection = createTestCollection(
          type: CollectionType.fork,
          originalSnapshot: '{}',
          forkedFromAuthor: 'Author',
          forkedFromName: 'Name',
        );
        final Map<String, dynamic> db = collection.toDb();

        expect(db['type'], 'fork');
        expect(db['original_snapshot'], '{}');
        expect(db['forked_from_author'], 'Author');
        expect(db['forked_from_name'], 'Name');
      });
    });

    group('toJson', () {
      test('должен возвращать корректный JSON для экспорта', () {
        final Collection collection = createTestCollection();
        final Map<String, dynamic> json = collection.toJson();

        expect(json['name'], 'Test Collection');
        expect(json['author'], 'Test Author');
        expect(json['created'], testDate.toIso8601String());
        expect(json.containsKey('id'), false);
        expect(json.containsKey('type'), false);
      });
    });

    group('copyWith', () {
      test('должен создавать копию с изменённым именем', () {
        final Collection original = createTestCollection();
        final Collection copy = original.copyWith(name: 'New Name');

        expect(copy.id, original.id);
        expect(copy.name, 'New Name');
        expect(copy.author, original.author);
        expect(copy.type, original.type);
      });

      test('должен создавать копию с изменённым типом', () {
        final Collection original = createTestCollection();
        final Collection copy = original.copyWith(type: CollectionType.fork);

        expect(copy.type, CollectionType.fork);
        expect(copy.name, original.name);
      });

      test('должен создавать копию со всеми изменёнными полями', () {
        final Collection original = createTestCollection();
        final DateTime newDate = DateTime(2025, 1, 1);
        final Collection copy = original.copyWith(
          id: 99,
          name: 'New Name',
          author: 'New Author',
          type: CollectionType.imported,
          createdAt: newDate,
          originalSnapshot: 'snapshot',
          forkedFromAuthor: 'Fork Author',
          forkedFromName: 'Fork Name',
        );

        expect(copy.id, 99);
        expect(copy.name, 'New Name');
        expect(copy.author, 'New Author');
        expect(copy.type, CollectionType.imported);
        expect(copy.createdAt, newDate);
        expect(copy.originalSnapshot, 'snapshot');
        expect(copy.forkedFromAuthor, 'Fork Author');
        expect(copy.forkedFromName, 'Fork Name');
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковом id', () {
        final Collection a = createTestCollection(id: 1, name: 'A');
        final Collection b = createTestCollection(id: 1, name: 'B');

        expect(a == b, true);
        expect(a.hashCode, b.hashCode);
      });

      test('должен быть не равен при разных id', () {
        final Collection a = createTestCollection(id: 1);
        final Collection b = createTestCollection(id: 2);

        expect(a == b, false);
      });

      test('должен быть равен самому себе', () {
        final Collection collection = createTestCollection();
        expect(collection == collection, true);
      });

      test('должен быть не равен объекту другого типа', () {
        final Collection collection = createTestCollection();
        expect(collection == 'string', false);
      });
    });

    group('toString', () {
      test('должен возвращать корректную строку', () {
        final Collection collection = createTestCollection(
          id: 5,
          name: 'Test',
          type: CollectionType.fork,
        );

        expect(collection.toString(), 'Collection(id: 5, name: Test, type: fork)');
      });
    });
  });
}
