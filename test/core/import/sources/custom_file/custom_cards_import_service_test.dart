import 'dart:convert';

import 'package:core/database/dao/global_tag_dao.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart' as model;
import 'package:core/models/universal_import_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/movie.dart';
import 'package:tonkatsu_box/core/import/import_writer.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_card_entry.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_cards_import_service.dart';
import 'package:tonkatsu_box/core/import/title_lookup/lookup_candidate.dart';
import 'package:tonkatsu_box/core/import/title_lookup/title_resolver.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late CustomCardsImportService sut;
  late MockDatabaseService mockDb;
  late MockCustomMediaDao mockCustomDao;
  late MockGameDao mockGameDao;
  late MockGlobalTagDao mockTagDao;
  late MockCollectionRepository mockRepo;
  late MockImageCacheService mockImageCache;
  late MockImportWriter mockWriter;
  late MockTitleResolver mockResolver;
  late MockMediaCacheWriter mockMediaCache;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<CustomMedia>[]);
    registerFallbackValue(<Object>[]);
    registerFallbackValue(<ImportCandidate>[]);
    registerFallbackValue(const TitleQuery(title: ''));
    registerFallbackValue(MediaType.game);
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<int>{});
    registerFallbackValue(<int>[]);
    registerFallbackValue(<TagSeed>[]);
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockCustomDao = MockCustomMediaDao();
    mockGameDao = MockGameDao();
    mockTagDao = MockGlobalTagDao();
    mockRepo = MockCollectionRepository();
    mockImageCache = MockImageCacheService();
    when(() => mockDb.customMediaDao).thenReturn(mockCustomDao);
    when(() => mockDb.gameDao).thenReturn(mockGameDao);
    when(() => mockDb.globalTagDao).thenReturn(mockTagDao);
    when(() => mockTagDao.resolveOrCreateAll(any()))
        .thenAnswer((_) async => <String, int>{});
    when(() => mockTagDao.addTagsToItems(any(), any()))
        .thenAnswer((_) async {});

    mockWriter = MockImportWriter();
    mockResolver = MockTitleResolver();
    mockMediaCache = MockMediaCacheWriter();
    when(() => mockMediaCache.upsertAll(any())).thenAnswer((_) async {});

    sut = CustomCardsImportService(
      database: mockDb,
      repository: mockRepo,
      imageCache: mockImageCache,
      writer: mockWriter,
      resolver: mockResolver,
      mediaCache: mockMediaCache,
    );


    when(() => mockGameDao.getAllPlatforms()).thenAnswer(
      (_) async => <model.Platform>[
        const model.Platform(
          id: 19,
          name: 'Super Nintendo Entertainment System',
          abbreviation: 'SNES',
        ),
        const model.Platform(id: 6, name: 'PC (Microsoft Windows)'),
      ],
    );
    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: 7));
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockCustomDao.createAll(any())).thenAnswer(
        (Invocation inv) async => List<int>.generate(
            (inv.positionalArguments[0] as List<CustomMedia>).length,
            (int i) => 100 + i));
    when(() => mockRepo.addItemsBatchReturningIds(any(), any())).thenAnswer(
        (Invocation inv) async => List<int?>.generate(
            (inv.positionalArguments[1] as List<dynamic>).length,
            (int i) => 200 + i));
    when(() => mockImageCache.downloadImage(
          type: any(named: 'type'),
          imageId: any(named: 'imageId'),
          remoteUrl: any(named: 'remoteUrl'),
        )).thenAnswer((_) async => true);
  });

  CustomCardEntry entry({
    String title = 'Card',
    MediaType type = MediaType.game,
    String? altTitle,
    int? year,
    String? description,
    String? genres,
    String? link,
    int? unitTotal,
    String? platform,
    String? coverUrl,
    ItemStatus? status,
    double? rating,
    String? comment,
    int? rewatchCount,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeSpentMinutes,
    bool? favorite,
    int? currentEpisode,
    int? currentSeason,
    List<String> tags = const <String>[],
  }) {
    return CustomCardEntry(
      title: title,
      type: type,
      altTitle: altTitle,
      year: year,
      description: description,
      genres: genres,
      link: link,
      unitTotal: unitTotal,
      platform: platform,
      coverUrl: coverUrl,
      status: status,
      rating: rating,
      comment: comment,
      rewatchCount: rewatchCount,
      startedAt: startedAt,
      completedAt: completedAt,
      timeSpentMinutes: timeSpentMinutes,
      favorite: favorite,
      currentEpisode: currentEpisode,
      currentSeason: currentSeason,
      tags: tags,
    );
  }

  group('CustomCardsImportService', () {
    group('parseFile', () {
      test('parses JSON bytes', () {
        final List<CustomCardRow> rows = sut.parseFile(
          utf8.encode('[{"title": "A", "type": "game"}]'),
          fileName: 'cards.json',
        );

        expect(rows.single.isValid, isTrue);
      });

      test('parses CSV bytes', () {
        final List<CustomCardRow> rows = sut.parseFile(
          utf8.encode('title,type\nA,book\n'),
          fileName: 'cards.csv',
        );

        expect(rows.single.entry!.type, MediaType.book);
      });
    });

    group('duplicateRowIndexes', () {
      List<CustomCardRow> rowsFor(List<String> titles) => <CustomCardRow>[
            for (int i = 0; i < titles.length; i++)
              CustomCardRow(
                index: i + 1,
                sourceTitle: titles[i],
                entry: entry(title: titles[i]),
              ),
          ];

      test('flags case-insensitive title matches in the target collection',
          () async {
        when(() => mockRepo.getItemsWithData(any())).thenAnswer(
          (_) async => <CollectionItem>[
            createTestCollectionItem(overrideName: 'chrono trigger'),
          ],
        );

        final Set<int> duplicates = await sut.duplicateRowIndexes(
          collectionId: 1,
          rows: rowsFor(<String>['Chrono Trigger', 'Dune']),
        );

        expect(duplicates, <int>{1});
      });

      test('flags in-file repeats of the same title', () async {
        final Set<int> duplicates = await sut.duplicateRowIndexes(
          collectionId: null,
          rows: rowsFor(<String>['Dune', 'DUNE', 'Other']),
        );

        expect(duplicates, <int>{2});
      });

      test('skips invalid rows and existing lookup for a new collection',
          () async {
        final Set<int> duplicates = await sut.duplicateRowIndexes(
          collectionId: null,
          rows: <CustomCardRow>[
            const CustomCardRow(
              index: 1,
              issues: <CustomCardIssue>[
                CustomCardIssue(CustomCardIssueCode.missingTitle),
              ],
            ),
          ],
        );

        expect(duplicates, isEmpty);
        verifyNever(() => mockRepo.getItemsWithData(any()));
      });
    });

    group('importSelected', () {
      test('fails on an empty selection', () async {
        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: const <CustomCardEntry>[],
        );

        expect(result.success, isFalse);
        expect(result.fatalError, isNotNull);
      });

      test('fails when the target collection does not exist', () async {
        when(() => mockRepo.getById(any())).thenAnswer((_) async => null);

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 42,
          author: 'me',
          entries: <CustomCardEntry>[entry()],
        );

        expect(result.success, isFalse);
        verifyNever(() => mockCustomDao.createAll(any()));
      });

      test('creates a new collection when collectionId is null', () async {
        final UniversalImportResult result = await sut.importSelected(
          collectionId: null,
          author: 'me',
          entries: <CustomCardEntry>[entry()],
        );

        expect(result.success, isTrue);
        expect(result.collection?.id, 7);
        verify(() => mockRepo.create(name: 'Custom Import', author: 'me'))
            .called(1);
      });

      test('maps entries to custom cards with platform catalog matching',
          () async {
        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(title: 'Matched', platform: 'snes'),
            entry(title: 'Free text', platform: 'Famiclone'),
            entry(
              title: 'Not a game',
              type: MediaType.anime,
              platform: 'SNES',
            ),
          ],
        );

        final List<CustomMedia> cards = verify(
                () => mockCustomDao.createAll(captureAny()))
            .captured
            .single as List<CustomMedia>;
        expect(cards[0].platformId, 19);
        expect(cards[0].platformName, 'SNES');
        expect(cards[0].displayType, MediaType.game);
        expect(cards[1].platformId, isNull);
        expect(cards[1].platformName, 'Famiclone');
        // The platform FK is a custom-games-only field.
        expect(cards[2].platformId, isNull);
        expect(cards[2].platformName, 'SNES');
        expect(cards[2].displayType, MediaType.anime);
      });

      test('custom keeps no display type, audio keeps its own', () async {
        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(title: 'Plain', type: MediaType.custom),
            entry(title: 'Album', type: MediaType.audio),
          ],
        );

        final List<CustomMedia> cards = verify(
                () => mockCustomDao.createAll(captureAny()))
            .captured
            .single as List<CustomMedia>;
        expect(cards[0].displayType, isNull);
        expect(cards[1].displayType, MediaType.audio);
      });

      test('writes items with user fields and status dates', () async {
        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(
              status: ItemStatus.completed,
              rating: 8.5,
              comment: 'note',
              rewatchCount: 3,
            ),
            entry(title: 'Untouched'),
          ],
        );

        final List<Map<String, dynamic>> rows = (verify(
                () => mockRepo.addItemsBatchReturningIds(1, captureAny()))
            .captured
            .single as List<dynamic>)
            .cast<Map<String, dynamic>>();

        expect(rows[0]['media_type'], 'custom');
        expect(rows[0]['external_id'], 100);
        expect(rows[0]['status'], 'completed');
        expect(rows[0]['user_rating'], 8.5);
        expect(rows[0]['user_comment'], 'note');
        expect(rows[0]['rewatch_count'], 3);
        expect(rows[0]['completed_at'], isNotNull);
        expect(rows[0]['last_activity_at'], isNotNull);

        expect(rows[1]['external_id'], 101);
        expect(rows[1]['status'], 'not_started');
        expect(rows[1].containsKey('user_rating'), isFalse);
        expect(rows[1].containsKey('started_at'), isFalse);
      });

      test('explicit dates and remaining user fields override status defaults',
          () async {
        final DateTime started = DateTime(2024, 1, 5);
        final DateTime completed = DateTime(2024, 2, 10);

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(
              status: ItemStatus.completed,
              startedAt: started,
              completedAt: completed,
              timeSpentMinutes: 300,
              favorite: true,
              currentEpisode: 12,
              currentSeason: 2,
            ),
          ],
        );

        final Map<String, dynamic> row = (verify(
                () => mockRepo.addItemsBatchReturningIds(1, captureAny()))
            .captured
            .single as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .single;

        int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
        expect(row['started_at'], epoch(started));
        expect(row['completed_at'], epoch(completed));
        expect(row['last_activity_at'], epoch(completed));
        expect(row['time_spent_minutes'], 300);
        expect(row['is_favorite'], 1);
        expect(row['current_episode'], 12);
        expect(row['current_season'], 2);
      });

      test('resolves tags through the DAO and assigns them to written items',
          () async {
        when(() => mockTagDao.resolveOrCreateAll(any())).thenAnswer(
          (_) async => <String, int>{'jrpg': 5, 'new tag': 9},
        );

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(tags: <String>['jrpg', 'new tag']),
          ],
        );

        final List<TagSeed> seeds = verify(
                () => mockTagDao.resolveOrCreateAll(captureAny()))
            .captured
            .single as List<TagSeed>;
        expect(seeds.map((TagSeed s) => s.name), <String>['jrpg', 'new tag']);
        verify(() => mockTagDao.addTagsToItems(<int>[200], <int>{5, 9}))
            .called(1);
      });

      test('skips tagging rows the insert ignored as duplicates', () async {
        when(() => mockRepo.addItemsBatchReturningIds(any(), any()))
            .thenAnswer((_) async => <int?>[null, 201]);
        when(() => mockTagDao.resolveOrCreateAll(any())).thenAnswer(
          (_) async => <String, int>{'jrpg': 5},
        );

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(tags: <String>['jrpg']),
            entry(title: 'Second', tags: <String>['jrpg']),
          ],
        );

        verify(() => mockTagDao.addTagsToItems(<int>[201], <int>{5})).called(1);
        verifyNever(() => mockTagDao.addTagsToItems(<int>[200], any()));
      });

      test('skips the tag machinery entirely when no entry has tags',
          () async {
        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[entry()],
        );

        verifyNever(() => mockTagDao.resolveOrCreateAll(any()));
        verifyNever(() => mockTagDao.addTagsToItems(any(), any()));
      });

      test('downloads covers only for entries that have one', () async {
        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(title: 'No cover'),
            entry(title: 'Covered', coverUrl: 'https://e.com/c.jpg'),
          ],
        );

        expect(result.success, isTrue);
        verify(() => mockImageCache.downloadImage(
              type: ImageType.customCover,
              imageId: '101',
              remoteUrl: 'https://e.com/c.jpg',
            )).called(1);
        verifyNoMoreInteractions(mockImageCache);
      });

      test('reports failed cover downloads without failing the import',
          () async {
        when(() => mockImageCache.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => false);

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[
            entry(title: 'Covered', coverUrl: 'https://e.com/c.jpg'),
          ],
        );

        expect(result.success, isTrue);
        expect(result.errors, hasLength(1));
        expect(result.errors.single, contains('Covered'));
      });

      test('counts inserted vs skipped and reports progress stages', () async {
        when(() => mockRepo.addItemsBatchReturningIds(any(), any()))
            .thenAnswer((_) async => <int?>[200, null]);
        final List<ImportStage> stages = <ImportStage>[];

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[entry(), entry(title: 'Second')],
          onProgress: (ImportProgress progress) => stages.add(progress.stage),
        );

        expect(result.importedByType, <MediaType, int>{MediaType.custom: 1});
        expect(result.skipped, 1);
        expect(stages.first, ImportStage.creatingCollection);
        expect(stages, contains(ImportStage.addingItems));
        expect(stages.last, ImportStage.completed);
      });

      test('turns an unexpected exception into a failure result', () async {
        when(() => mockCustomDao.createAll(any()))
            .thenThrow(Exception('db locked'));

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[entry()],
        );

        expect(result.success, isFalse);
        expect(result.fatalError, contains('db locked'));
      });
    });

    group('importSelected with resolveFromSources', () {
      final Movie dune = createTestMovie(
        tmdbId: 438631,
        title: 'Dune',
        releaseYear: 2021,
        posterUrl: 'https://img/dune.jpg',
      );
      final LookupCandidate duneHit = LookupCandidate(
        media: dune,
        mediaType: MediaType.movie,
        externalId: 438631,
        source: DataSource.tmdb,
        titles: const <String?>['Dune'],
        year: 2021,
        coverUrl: 'https://img/dune.jpg',
      );
      final String duneKey = ImportWriter.itemKey(
        MediaType.movie,
        438631,
        null,
        DataSource.tmdb,
      );

      void resolverAnswers(ResolveOutcome outcome) {
        when(() => mockResolver.resolve(
              any(),
              any(),
              platformUnknown: any(named: 'platformUnknown'),
              onSource: any(named: 'onSource'),
              onRateLimit: any(named: 'onRateLimit'),
            )).thenAnswer((_) async => outcome);
      }

      void writerAnswers({
        Map<MediaType, int> importedByType = const <MediaType, int>{},
        int skipped = 0,
        Map<String, int> itemIdsByKey = const <String, int>{},
      }) {
        when(() => mockWriter.writeItems(
              collectionId: any(named: 'collectionId'),
              candidates: any(named: 'candidates'),
              onItem: any(named: 'onItem'),
            )).thenAnswer(
          (_) async => ImportWriteResult(
            importedByType: importedByType,
            updatedByType: const <MediaType, int>{},
            skipped: skipped,
            itemIdsByKey: itemIdsByKey,
          ),
        );
      }

      List<ImportCandidate> writtenCandidates() => verify(
            () => mockWriter.writeItems(
              collectionId: 1,
              candidates: captureAny(named: 'candidates'),
              onItem: any(named: 'onItem'),
            ),
          ).captured.single as List<ImportCandidate>;

      test('the flag off asks no source and behaves as before', () async {
        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          entries: <CustomCardEntry>[entry(title: 'Dune', type: MediaType.movie)],
        );

        verifyNever(() => mockResolver.resolve(
              any(),
              any(),
              platformUnknown: any(named: 'platformUnknown'),
              onSource: any(named: 'onSource'),
              onRateLimit: any(named: 'onRateLimit'),
            ));
        verifyNever(() => mockWriter.writeItems(
              collectionId: any(named: 'collectionId'),
              candidates: any(named: 'candidates'),
              onItem: any(named: 'onItem'),
            ));
        verify(() => mockCustomDao.createAll(any())).called(1);
      });

      test('a unique hit becomes a real item carrying the personal fields',
          () async {
        resolverAnswers(ResolvedMatch(duneHit, platformId: null));
        writerAnswers(
          importedByType: <MediaType, int>{MediaType.movie: 1},
          itemIdsByKey: <String, int>{duneKey: 55},
        );

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(
              title: 'Dune',
              type: MediaType.movie,
              year: 2021,
              description: 'file text',
              genres: 'Sci-Fi',
              link: 'https://file/dune',
              unitTotal: 3,
              status: ItemStatus.completed,
              rating: 9,
              comment: 'loved it',
              rewatchCount: 1,
              timeSpentMinutes: 155,
              favorite: true,
              currentEpisode: 2,
              currentSeason: 1,
              startedAt: DateTime(2024, 1, 5),
              completedAt: DateTime(2024, 1, 6),
            ),
          ],
        );

        verify(() => mockMediaCache.upsertAll(<Object>[dune])).called(1);
        final ImportCandidate written = writtenCandidates().single;
        expect(written.mediaType, MediaType.movie);
        expect(written.externalId, 438631);
        expect(written.source, DataSource.tmdb);
        expect(written.platformId, isNull);
        final Map<String, dynamic> row = written.insertRow;
        expect(row['media_type'], 'movie');
        expect(row['external_id'], 438631);
        expect(row['source'], 'tmdb');
        expect(row['status'], 'completed');
        expect(row['user_rating'], 9);
        expect(row['user_comment'], 'loved it');
        expect(row['rewatch_count'], 1);
        expect(row['time_spent_minutes'], 155);
        expect(row['is_favorite'], 1);
        expect(row['current_episode'], 2);
        expect(row['current_season'], 1);
        expect(row['started_at'], DateTime(2024, 1, 5).millisecondsSinceEpoch ~/ 1000);
        expect(row['completed_at'], DateTime(2024, 1, 6).millisecondsSinceEpoch ~/ 1000);
        // File metadata never reaches a real item: the source owns it.
        expect(row.keys, isNot(contains('description')));
        expect(row.keys, isNot(contains('genres')));
        expect(row.keys, isNot(contains('external_url')));
        expect(row.keys, isNot(contains('unit_total')));
        expect(row.keys, isNot(contains('override_cover_url')));
        verifyNever(() => mockCustomDao.createAll(any()));
        expect(result.importedByType[MediaType.movie], 1);
        expect(result.importedByType[MediaType.custom], 0);
      });

      test('a file cover becomes the override only when the source has none',
          () async {
        final LookupCandidate bare = LookupCandidate(
          media: dune,
          mediaType: MediaType.movie,
          externalId: 438631,
          source: DataSource.tmdb,
          titles: const <String?>['Dune'],
        );
        resolverAnswers(ResolvedMatch(bare, platformId: null));
        writerAnswers();

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(
              title: 'Dune',
              type: MediaType.movie,
              coverUrl: 'https://file/cover.jpg',
            ),
          ],
        );

        expect(
          writtenCandidates().single.insertRow['override_cover_url'],
          'https://file/cover.jpg',
        );
      });

      test('ambiguous and not-found rows stay custom cards', () async {
        when(() => mockResolver.resolve(
              any(),
              any(),
              platformUnknown: any(named: 'platformUnknown'),
              onSource: any(named: 'onSource'),
              onRateLimit: any(named: 'onRateLimit'),
            )).thenAnswer((Invocation inv) async =>
                (inv.positionalArguments[1] as TitleQuery).title == 'Dune'
                    ? const ResolvedAmbiguous(DataSource.tmdb, 2)
                    : const ResolvedNotFound());

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Dune', type: MediaType.movie),
            entry(title: 'Nobody Knows', type: MediaType.movie),
          ],
        );

        final List<CustomMedia> cards = verify(
                () => mockCustomDao.createAll(captureAny()))
            .captured
            .single as List<CustomMedia>;
        expect(cards.map((CustomMedia c) => c.title), <String>['Dune', 'Nobody Knows']);
        expect(cards.first.displayType, MediaType.movie);
        verifyNever(() => mockWriter.writeItems(
              collectionId: any(named: 'collectionId'),
              candidates: any(named: 'candidates'),
              onItem: any(named: 'onItem'),
            ));
        expect(result.unresolvedTitles, <String>['Dune']);
        expect(result.importedByType[MediaType.custom], 2);
      });

      test('custom and audio rows never ask a source', () async {
        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Mine', type: MediaType.custom),
            entry(title: 'Album', type: MediaType.audio),
          ],
        );

        verifyNever(() => mockResolver.resolve(
              any(),
              any(),
              platformUnknown: any(named: 'platformUnknown'),
              onSource: any(named: 'onSource'),
              onRateLimit: any(named: 'onRateLimit'),
            ));
        verify(() => mockCustomDao.createAll(any())).called(1);
      });

      test('a game passes its catalog platform and flags an unknown one',
          () async {
        resolverAnswers(const ResolvedNotFound());

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Chrono Trigger', platform: 'snes'),
            entry(title: 'Homebrew', platform: 'Famiclone'),
          ],
        );

        final List<dynamic> captured = verify(() => mockResolver.resolve(
              MediaType.game,
              captureAny(),
              platformUnknown: captureAny(named: 'platformUnknown'),
              onSource: any(named: 'onSource'),
              onRateLimit: any(named: 'onRateLimit'),
            )).captured;
        expect((captured[0] as TitleQuery).platformId, 19);
        expect(captured[1], isFalse);
        expect((captured[2] as TitleQuery).platformId, isNull);
        expect(captured[3], isTrue);
      });

      test('should add file tags, not replace, when a row resolves', () async {
        resolverAnswers(ResolvedMatch(duneHit, platformId: null));
        writerAnswers(itemIdsByKey: <String, int>{duneKey: 55});
        when(() => mockTagDao.resolveOrCreateAll(any()))
            .thenAnswer((_) async => <String, int>{'epic': 3});

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Dune', type: MediaType.movie, tags: <String>['epic']),
          ],
        );

        verify(() => mockTagDao.addTagsToItems(<int>[55], <int>{3})).called(1);
        verifyNever(() => mockTagDao.setItemTags(any(), any()));
      });

      test('an item already in the collection counts as skipped', () async {
        resolverAnswers(ResolvedMatch(duneHit, platformId: null));
        writerAnswers(skipped: 1, itemIdsByKey: <String, int>{duneKey: 55});

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Dune', type: MediaType.movie),
          ],
        );

        expect(result.success, isTrue);
        expect(result.skipped, 1);
        expect(result.importedByType[MediaType.movie], isNull);
      });

      test('two rows with one hit are both handed to the writer', () async {
        resolverAnswers(ResolvedMatch(duneHit, platformId: null));
        writerAnswers(
          importedByType: <MediaType, int>{MediaType.movie: 1},
          skipped: 1,
        );

        final UniversalImportResult result = await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Dune', type: MediaType.movie),
            entry(title: 'Dune', type: MediaType.movie, altTitle: 'Дюна'),
          ],
        );

        expect(writtenCandidates().length, 2);
        expect(result.skipped, 1);
      });

      test('progress reports the row, the source and running tallies',
          () async {
        when(() => mockResolver.resolve(
              any(),
              any(),
              platformUnknown: any(named: 'platformUnknown'),
              onSource: any(named: 'onSource'),
              onRateLimit: any(named: 'onRateLimit'),
            )).thenAnswer((Invocation inv) async {
          final void Function(DataSource)? onSource =
              inv.namedArguments[#onSource] as void Function(DataSource)?;
          onSource?.call(DataSource.tmdb);
          return (inv.positionalArguments[1] as TitleQuery).title == 'Dune'
              ? ResolvedMatch(duneHit, platformId: null)
              : const ResolvedAmbiguous(DataSource.tmdb, 3);
        });
        writerAnswers(importedByType: <MediaType, int>{MediaType.movie: 1});
        final List<ImportProgress> seen = <ImportProgress>[];

        await sut.importSelected(
          collectionId: 1,
          author: 'me',
          resolveFromSources: true,
          entries: <CustomCardEntry>[
            entry(title: 'Dune', type: MediaType.movie),
            entry(title: 'Twins', type: MediaType.movie),
          ],
          onProgress: seen.add,
        );

        final List<ImportProgress> lookups = seen
            .where((ImportProgress p) => p.stage == ImportStage.resolvingTitles)
            .toList();
        expect(lookups.first.currentItem, 'Dune');
        expect(lookups.first.total, 2);
        expect(
          lookups.where((ImportProgress p) => p.source == DataSource.tmdb),
          hasLength(2),
        );
        final ImportProgress last = lookups.last;
        expect(last.imported, 1);
        expect(last.customCards, 1);
        expect(last.ambiguous, 1);
      });
    });
  });
}
