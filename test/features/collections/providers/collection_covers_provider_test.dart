import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/collections/providers/collection_covers_provider.dart';
import 'package:xerabora/shared/models/cover_info.dart';
import 'package:xerabora/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
    );
  }

  group('collectionCoversProvider', () {
    test('должен вернуть обложки для коллекции', () async {
      const List<CoverInfo> covers = <CoverInfo>[
        CoverInfo(
          externalId: 1,
          mediaType: MediaType.game,
          thumbnailUrl: 'https://images.igdb.com/cover1.jpg',
        ),
        CoverInfo(
          externalId: 2,
          mediaType: MediaType.movie,
          thumbnailUrl: 'https://image.tmdb.org/t/p/w154/poster.jpg',
        ),
      ];

      when(() => mockDb.getCollectionCovers(42, limit: 6))
          .thenAnswer((_) async => covers);

      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      // Ожидаем загрузки
      final AsyncValue<List<CoverInfo>> result =
          await container.read(collectionCoversProvider(42).future).then(
                (List<CoverInfo> data) => AsyncData<List<CoverInfo>>(data),
              );

      expect(result.value, covers);
      verify(() => mockDb.getCollectionCovers(42, limit: 6)).called(1);
    });

    test('должен вернуть пустой список для пустой коллекции', () async {
      when(() => mockDb.getCollectionCovers(99, limit: 6))
          .thenAnswer((_) async => <CoverInfo>[]);

      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      final List<CoverInfo> result =
          await container.read(collectionCoversProvider(99).future);

      expect(result, isEmpty);
    });

    test('должен поддерживать null collectionId (uncategorized)', () async {
      const List<CoverInfo> covers = <CoverInfo>[
        CoverInfo(
          externalId: 10,
          mediaType: MediaType.tvShow,
          thumbnailUrl: 'https://image.tmdb.org/t/p/w154/show.jpg',
        ),
      ];

      when(() => mockDb.getCollectionCovers(null, limit: 6))
          .thenAnswer((_) async => covers);

      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      final List<CoverInfo> result =
          await container.read(collectionCoversProvider(null).future);

      expect(result, covers);
      verify(() => mockDb.getCollectionCovers(null, limit: 6)).called(1);
    });

    test('должен вернуть ошибку при сбое БД', () async {
      when(() => mockDb.getCollectionCovers(1, limit: 6))
          .thenThrow(Exception('DB error'));

      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(collectionCoversProvider(1).future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
