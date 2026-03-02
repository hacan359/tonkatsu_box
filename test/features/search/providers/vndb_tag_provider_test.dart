// Тесты для провайдера тегов VNDB (vndb_tag_provider.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/search/providers/vndb_tag_provider.dart';
import 'package:xerabora/shared/models/visual_novel.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
  });

  /// Создаёт [ProviderContainer] с мок-зависимостями.
  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('vndbTagsProvider', () {
    test('возвращает список тегов из БД', () async {
      final List<VndbTag> expectedTags = <VndbTag>[
        const VndbTag(id: 'g7', name: 'Drama'),
        const VndbTag(id: 'g14', name: 'Comedy'),
        const VndbTag(id: 'g24', name: 'Romance'),
      ];

      when(() => mockDb.getVndbTags()).thenAnswer((_) async => expectedTags);

      final ProviderContainer container = createContainer();

      final List<VndbTag> result =
          await container.read(vndbTagsProvider.future);

      expect(result, hasLength(3));
      expect(result[0].id, equals('g7'));
      expect(result[0].name, equals('Drama'));
      expect(result[1].id, equals('g14'));
      expect(result[1].name, equals('Comedy'));
      expect(result[2].id, equals('g24'));
      expect(result[2].name, equals('Romance'));
    });

    test('возвращает пустой список когда БД пуста', () async {
      when(() => mockDb.getVndbTags())
          .thenAnswer((_) async => <VndbTag>[]);

      final ProviderContainer container = createContainer();

      final List<VndbTag> result =
          await container.read(vndbTagsProvider.future);

      expect(result, isEmpty);
    });

    test('один тег корректно возвращается', () async {
      final List<VndbTag> expectedTags = <VndbTag>[
        const VndbTag(id: 'g6', name: 'Mystery'),
      ];

      when(() => mockDb.getVndbTags()).thenAnswer((_) async => expectedTags);

      final ProviderContainer container = createContainer();

      final List<VndbTag> result =
          await container.read(vndbTagsProvider.future);

      expect(result, hasLength(1));
      expect(result.first.id, equals('g6'));
      expect(result.first.name, equals('Mystery'));
    });

    test('теги сохраняют порядок из БД', () async {
      final List<VndbTag> expectedTags = <VndbTag>[
        const VndbTag(id: 'g1', name: 'Action'),
        const VndbTag(id: 'g2', name: 'Adventure'),
        const VndbTag(id: 'g3', name: 'Fantasy'),
        const VndbTag(id: 'g4', name: 'Horror'),
        const VndbTag(id: 'g5', name: 'Sci-Fi'),
      ];

      when(() => mockDb.getVndbTags()).thenAnswer((_) async => expectedTags);

      final ProviderContainer container = createContainer();

      final List<VndbTag> result =
          await container.read(vndbTagsProvider.future);

      expect(result, hasLength(5));
      expect(result[0].id, equals('g1'));
      expect(result[0].name, equals('Action'));
      expect(result[4].id, equals('g5'));
      expect(result[4].name, equals('Sci-Fi'));
    });

    test('вызывает getVndbTags на DatabaseService', () async {
      when(() => mockDb.getVndbTags())
          .thenAnswer((_) async => <VndbTag>[]);

      final ProviderContainer container = createContainer();

      await container.read(vndbTagsProvider.future);

      verify(() => mockDb.getVndbTags()).called(1);
    });
  });
}
