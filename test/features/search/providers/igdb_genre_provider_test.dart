// Тесты для провайдера жанров IGDB (igdb_genre_provider.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/search/filters/igdb_genre_filter.dart';
import 'package:xerabora/features/search/providers/igdb_genre_provider.dart';

import '../../../helpers/test_helpers.dart';

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

  group('igdbGenresProvider', () {
    test('возвращает список жанров из БД', () async {
      final List<Map<String, dynamic>> dbRows = <Map<String, dynamic>>[
        <String, dynamic>{'id': 4, 'name': 'Fighting'},
        <String, dynamic>{'id': 5, 'name': 'Shooter'},
        <String, dynamic>{'id': 7, 'name': 'Music'},
      ];

      when(() => mockDb.getIgdbGenres()).thenAnswer((_) async => dbRows);

      final ProviderContainer container = createContainer();

      final List<IgdbGenre> result =
          await container.read(igdbGenresProvider.future);

      expect(result, hasLength(3));
      expect(result[0].id, equals(4));
      expect(result[0].name, equals('Fighting'));
      expect(result[1].id, equals(5));
      expect(result[1].name, equals('Shooter'));
      expect(result[2].id, equals(7));
      expect(result[2].name, equals('Music'));
    });

    test('возвращает пустой список когда БД пуста', () async {
      when(() => mockDb.getIgdbGenres())
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      final ProviderContainer container = createContainer();

      final List<IgdbGenre> result =
          await container.read(igdbGenresProvider.future);

      expect(result, isEmpty);
    });

    test('один жанр корректно конвертируется', () async {
      final List<Map<String, dynamic>> dbRows = <Map<String, dynamic>>[
        <String, dynamic>{'id': 31, 'name': 'Adventure'},
      ];

      when(() => mockDb.getIgdbGenres()).thenAnswer((_) async => dbRows);

      final ProviderContainer container = createContainer();

      final List<IgdbGenre> result =
          await container.read(igdbGenresProvider.future);

      expect(result, hasLength(1));
      expect(result.first.id, equals(31));
      expect(result.first.name, equals('Adventure'));
    });

    test('множество жанров сохраняют порядок из БД', () async {
      final List<Map<String, dynamic>> dbRows = <Map<String, dynamic>>[
        <String, dynamic>{'id': 2, 'name': 'Point-and-click'},
        <String, dynamic>{'id': 8, 'name': 'Platform'},
        <String, dynamic>{'id': 9, 'name': 'Puzzle'},
        <String, dynamic>{'id': 10, 'name': 'Racing'},
        <String, dynamic>{'id': 11, 'name': 'Real Time Strategy (RTS)'},
      ];

      when(() => mockDb.getIgdbGenres()).thenAnswer((_) async => dbRows);

      final ProviderContainer container = createContainer();

      final List<IgdbGenre> result =
          await container.read(igdbGenresProvider.future);

      expect(result, hasLength(5));
      expect(result[0].id, equals(2));
      expect(result[0].name, equals('Point-and-click'));
      expect(result[4].id, equals(11));
      expect(result[4].name, equals('Real Time Strategy (RTS)'));
    });

    test('вызывает getIgdbGenres на DatabaseService', () async {
      when(() => mockDb.getIgdbGenres())
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      final ProviderContainer container = createContainer();

      await container.read(igdbGenresProvider.future);

      verify(() => mockDb.getIgdbGenres()).called(1);
    });
  });
}
