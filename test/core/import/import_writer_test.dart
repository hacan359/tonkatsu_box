import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/import_writer.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockCollectionRepository mockCollections;
  late MockWishlistRepository mockWishlist;
  late ImportWriter writer;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  setUp(() {
    mockCollections = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();
    writer = ImportWriter(collections: mockCollections, wishlist: mockWishlist);

    when(() => mockCollections.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockCollections.addItemsBatch(any(), any())).thenAnswer(
        (Invocation i) async =>
            (i.positionalArguments[1] as List<dynamic>).length);
    when(() => mockCollections.updateItemFieldsBatch(any()))
        .thenAnswer((_) async {});
    when(() => mockWishlist.getAll(
          includeResolved: any(named: 'includeResolved'),
        )).thenAnswer((_) async => <WishlistItem>[]);
    when(() => mockWishlist.addWishlistItemsBatch(any())).thenAnswer(
        (Invocation i) async =>
            (i.positionalArguments[0] as List<dynamic>).length);
  });

  ImportCandidate candidate({
    required int externalId,
    MediaType mediaType = MediaType.movie,
    int? platformId,
    Map<String, dynamic> Function(CollectionItem existing)? changed,
  }) {
    return ImportCandidate(
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      insertRow: <String, dynamic>{
        'external_id': externalId,
        'media_type': mediaType.value,
      },
      changedFields:
          changed ?? ((CollectionItem existing) => <String, dynamic>{}),
    );
  }

  group('ImportWriter', () {
    group('resolveCollection', () {
      test('returns the existing collection when an id is given', () async {
        when(() => mockCollections.getById(5))
            .thenAnswer((_) async => createTestCollection(id: 5));

        final Collection? c = await writer.resolveCollection(
          collectionId: 5,
          newCollectionName: 'X',
          author: 'A',
        );

        expect(c!.id, 5);
        verifyNever(() => mockCollections.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
            ));
      });

      test('creates a new collection when the id is null', () async {
        when(() => mockCollections.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
            )).thenAnswer((_) async => createTestCollection(id: 9));

        final Collection? c = await writer.resolveCollection(
          collectionId: null,
          newCollectionName: 'New',
          author: 'Imp',
        );

        expect(c!.id, 9);
        verify(() => mockCollections.create(name: 'New', author: 'Imp'))
            .called(1);
      });
    });

    group('writeItems', () {
      test('batch-inserts new items and tallies by type', () async {
        final ImportWriteResult r = await writer.writeItems(
          collectionId: 1,
          candidates: <ImportCandidate>[
            candidate(externalId: 1),
            candidate(externalId: 2, mediaType: MediaType.tvShow),
          ],
        );

        expect(r.importedByType[MediaType.movie], 1);
        expect(r.importedByType[MediaType.tvShow], 1);
        expect(r.skipped, 0);
        final List<dynamic> captured =
            verify(() => mockCollections.addItemsBatch(1, captureAny()))
                .captured;
        expect(captured.single as List<dynamic>, hasLength(2));
      });

      test('updates an existing item only with its changed fields', () async {
        when(() => mockCollections.getItems(any())).thenAnswer(
          (_) async => <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.movie,
              externalId: 1,
            ),
          ],
        );

        final ImportWriteResult r = await writer.writeItems(
          collectionId: 1,
          candidates: <ImportCandidate>[
            candidate(
              externalId: 1,
              changed: (CollectionItem existing) =>
                  <String, dynamic>{'user_rating': 9.0},
            ),
          ],
        );

        expect(r.importedByType, isEmpty);
        expect(r.updatedByType[MediaType.movie], 1);
        final List<dynamic> captured =
            verify(() => mockCollections.updateItemFieldsBatch(captureAny()))
                .captured;
        final List<(int, Map<String, dynamic>)> updates =
            captured.single as List<(int, Map<String, dynamic>)>;
        expect(updates.single.$1, 7);
        expect(updates.single.$2['user_rating'], 9.0);
      });

      test('skips an existing item whose changed fields are empty', () async {
        when(() => mockCollections.getItems(any())).thenAnswer(
          (_) async => <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.movie,
              externalId: 1,
            ),
          ],
        );

        final ImportWriteResult r = await writer.writeItems(
          collectionId: 1,
          candidates: <ImportCandidate>[candidate(externalId: 1)],
        );

        expect(r.skipped, 1);
        expect(r.importedByType, isEmpty);
        expect(r.updatedByType, isEmpty);
      });

      test('drops in-batch duplicates of the same logical item', () async {
        final ImportWriteResult r = await writer.writeItems(
          collectionId: 1,
          candidates: <ImportCandidate>[
            candidate(externalId: 1),
            candidate(externalId: 1),
          ],
        );

        expect(r.importedByType[MediaType.movie], 1);
        expect(r.skipped, 1);
      });
    });

    group('writeWishlist', () {
      test('returns empty and writes nothing for no entries', () async {
        final Map<MediaType, int> result = await writer.writeWishlist(
          entries: <WishlistCandidate>[],
          tag: 'T',
        );

        expect(result, isEmpty);
        verifyNever(() => mockWishlist.addWishlistItemsBatch(any()));
      });

      test('dedups against existing and within the batch, applies the tag',
          () async {
        when(() => mockWishlist.getAll(
              includeResolved: any(named: 'includeResolved'),
            )).thenAnswer(
          (_) async => <WishlistItem>[createTestWishlistItem(text: 'Dup')],
        );

        final Map<MediaType, int> result = await writer.writeWishlist(
          tag: 'Kinorium',
          entries: const <WishlistCandidate>[
            WishlistCandidate(text: 'Dup', mediaType: MediaType.movie),
            WishlistCandidate(text: 'New', mediaType: MediaType.movie),
            WishlistCandidate(text: 'New', mediaType: MediaType.movie),
          ],
        );

        expect(result[MediaType.movie], 1);
        final List<dynamic> captured =
            verify(() => mockWishlist.addWishlistItemsBatch(captureAny()))
                .captured;
        final List<dynamic> inserted = captured.single as List<dynamic>;
        expect(inserted, hasLength(1));
        expect((inserted.single as Map<String, dynamic>)['text'], 'New');
        expect((inserted.single as Map<String, dynamic>)['tag'], 'Kinorium');
      });
    });

    group('writeItems onItem', () {
      test('fires per candidate with running imported/updated tallies and label',
          () async {
        when(() => mockCollections.getItems(any())).thenAnswer((_) async =>
            <CollectionItem>[
              createTestCollectionItem(
                id: 7,
                mediaType: MediaType.movie,
                externalId: 2,
              ),
            ]);

        final List<(int, int, int, int, String?)> events =
            <(int, int, int, int, String?)>[];

        await writer.writeItems(
          collectionId: 1,
          candidates: <ImportCandidate>[
            ImportCandidate(
              mediaType: MediaType.movie,
              externalId: 1,
              platformId: null,
              label: 'New One',
              insertRow: <String, dynamic>{
                'external_id': 1,
                'media_type': MediaType.movie.value,
              },
              changedFields: (CollectionItem e) => <String, dynamic>{},
            ),
            ImportCandidate(
              mediaType: MediaType.movie,
              externalId: 2,
              platformId: null,
              label: 'Existing Changed',
              insertRow: <String, dynamic>{
                'external_id': 2,
                'media_type': MediaType.movie.value,
              },
              changedFields: (CollectionItem e) =>
                  <String, dynamic>{'user_rating': 9.0},
            ),
          ],
          onItem: (int processed, int total, int imported, int updated,
              String? label) {
            events.add((processed, total, imported, updated, label));
          },
        );

        expect(events, hasLength(2));
        expect(events[0], (1, 2, 1, 0, 'New One'));
        expect(events[1], (2, 2, 1, 1, 'Existing Changed'));
      });
    });
  });
}
