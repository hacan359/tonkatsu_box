import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/core/import/sources/mal/mal_import_service.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  late MalImportService sut;
  late MockAniListApi mockAniList;
  late MockDatabaseService mockDb;
  late MockAnimeDao mockAnimeDao;
  late MockMangaDao mockMangaDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  setUp(() {
    mockAniList = MockAniListApi();
    mockDb = MockDatabaseService();
    mockAnimeDao = MockAnimeDao();
    mockMangaDao = MockMangaDao();
    when(() => mockDb.animeDao).thenReturn(mockAnimeDao);
    when(() => mockDb.mangaDao).thenReturn(mockMangaDao);
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();
    sut = MalImportService(
      aniListApi: mockAniList,
      database: mockDb,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    when(() => mockAnimeDao.upsertAnimes(any())).thenAnswer((_) async {});
    when(() => mockMangaDao.upsertMangas(any())).thenAnswer((_) async {});
    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockRepo.addItemsBatch(any(), any())).thenAnswer(
        (Invocation inv) async =>
            (inv.positionalArguments[1] as List<dynamic>).length);
    when(() => mockRepo.updateItemFieldsBatch(any())).thenAnswer((_) async {});
    when(() => mockWishlist.getAll(
          includeResolved: any(named: 'includeResolved'),
        )).thenAnswer((_) async => <WishlistItem>[]);
    when(() => mockWishlist.addWishlistItemsBatch(any())).thenAnswer(
        (Invocation inv) async =>
            (inv.positionalArguments[0] as List<dynamic>).length);
  });

  group('MalImportService', () {
    group('parseString (anime)', () {
      const String animeXml = '''
<?xml version="1.0" encoding="UTF-8" ?>
<myanimelist>
  <myinfo>
    <user_id>123</user_id>
    <user_name>tester</user_name>
    <user_export_type>1</user_export_type>
  </myinfo>
  <anime>
    <series_animedb_id>5114</series_animedb_id>
    <series_title><![CDATA[Fullmetal Alchemist: Brotherhood]]></series_title>
    <series_episodes>64</series_episodes>
    <my_watched_episodes>64</my_watched_episodes>
    <my_start_date>2020-01-15</my_start_date>
    <my_finish_date>2020-04-10</my_finish_date>
    <my_score>10</my_score>
    <my_status>Completed</my_status>
    <my_tags><![CDATA[Action, Adventure, 2009]]></my_tags>
    <my_times_watched>2</my_times_watched>
    <my_comments><![CDATA[Best anime ever!]]></my_comments>
  </anime>
  <anime>
    <series_animedb_id>20770</series_animedb_id>
    <series_title><![CDATA[Akatsuki no Yona]]></series_title>
    <series_episodes>24</series_episodes>
    <my_watched_episodes>0</my_watched_episodes>
    <my_start_date>0000-00-00</my_start_date>
    <my_finish_date>0000-00-00</my_finish_date>
    <my_score>0</my_score>
    <my_status>Plan to Watch</my_status>
    <my_tags><![CDATA[]]></my_tags>
    <my_times_watched>0</my_times_watched>
    <my_comments><![CDATA[]]></my_comments>
  </anime>
</myanimelist>
''';

      test('парсит file kind как anime', () {
        final MalParsedFile parsed = sut.parseString(animeXml);
        expect(parsed.kind, MalFileKind.anime);
        expect(parsed.userName, 'tester');
        expect(parsed.entries, hasLength(2));
      });

      test('парсит completed запись со всеми полями', () {
        final MalParsedFile parsed = sut.parseString(animeXml);
        final MalEntry entry = parsed.entries.first;
        expect(entry.malId, 5114);
        expect(entry.title, 'Fullmetal Alchemist: Brotherhood');
        expect(entry.status, ItemStatus.completed);
        expect(entry.score, 10);
        expect(entry.watchedEpisodes, 64);
        expect(entry.totalEpisodesXml, 64);
        expect(entry.startDate, DateTime.utc(2020, 1, 15));
        expect(entry.finishDate, DateTime.utc(2020, 4, 10));
        expect(entry.tags, 'Action, Adventure, 2009');
        expect(entry.timesWatched, 2);
        expect(entry.comments, 'Best anime ever!');
      });

      test('игнорирует пустые даты 0000-00-00 и нулевой score', () {
        final MalParsedFile parsed = sut.parseString(animeXml);
        final MalEntry entry = parsed.entries[1];
        expect(entry.status, ItemStatus.planned);
        expect(entry.score, isNull);
        expect(entry.startDate, isNull);
        expect(entry.finishDate, isNull);
        expect(entry.tags, isNull);
        expect(entry.comments, isNull);
      });
    });

    group('parseString (manga)', () {
      const String mangaXml = '''
<?xml version="1.0" encoding="UTF-8" ?>
<myanimelist>
  <myinfo>
    <user_id>123</user_id>
    <user_name>tester</user_name>
    <user_export_type>2</user_export_type>
  </myinfo>
  <manga>
    <manga_mangadb_id>30844</manga_mangadb_id>
    <manga_title><![CDATA[1-Pound no Fukuin]]></manga_title>
    <manga_volumes>4</manga_volumes>
    <manga_chapters>37</manga_chapters>
    <my_read_volumes>4</my_read_volumes>
    <my_read_chapters>37</my_read_chapters>
    <my_status>Completed</my_status>
    <my_score>7</my_score>
    <my_times_read>1</my_times_read>
    <my_tags><![CDATA[Comedy, Sports]]></my_tags>
    <my_comments><![CDATA[]]></my_comments>
  </manga>
</myanimelist>
''';

      test('парсит file kind как manga', () {
        final MalParsedFile parsed = sut.parseString(mangaXml);
        expect(parsed.kind, MalFileKind.manga);
        expect(parsed.entries, hasLength(1));
      });

      test('парсит volumes и chapters для манги', () {
        final MalParsedFile parsed = sut.parseString(mangaXml);
        final MalEntry entry = parsed.entries.first;
        expect(entry.malId, 30844);
        expect(entry.kind, MalFileKind.manga);
        expect(entry.readChapters, 37);
        expect(entry.readVolumes, 4);
        expect(entry.totalChaptersXml, 37);
        expect(entry.totalVolumesXml, 4);
        expect(entry.timesWatched, 1);
      });
    });

    group('маппинг статусов', () {
      String wrap(String malStatus) => '''
<?xml version="1.0" encoding="UTF-8" ?>
<myanimelist>
  <myinfo><user_export_type>1</user_export_type></myinfo>
  <anime>
    <series_animedb_id>1</series_animedb_id>
    <series_title>x</series_title>
    <my_status>$malStatus</my_status>
  </anime>
</myanimelist>
''';

      test('Watching → inProgress', () {
        expect(sut.parseString(wrap('Watching')).entries.first.status,
            ItemStatus.inProgress);
      });

      test('Completed → completed', () {
        expect(sut.parseString(wrap('Completed')).entries.first.status,
            ItemStatus.completed);
      });

      test('On-Hold → planned', () {
        expect(sut.parseString(wrap('On-Hold')).entries.first.status,
            ItemStatus.planned);
      });

      test('Dropped → dropped', () {
        expect(sut.parseString(wrap('Dropped')).entries.first.status,
            ItemStatus.dropped);
      });

      test('Plan to Watch → planned', () {
        expect(sut.parseString(wrap('Plan to Watch')).entries.first.status,
            ItemStatus.planned);
      });

      test('неизвестный статус → notStarted', () {
        expect(sut.parseString(wrap('FooBar')).entries.first.status,
            ItemStatus.notStarted);
      });
    });

    group('parseString (валидация)', () {
      test('бросает FormatException на невалидном XML', () {
        expect(() => sut.parseString('<not xml<<'),
            throwsA(isA<FormatException>()));
      });

      test('бросает FormatException если корневой элемент не myanimelist', () {
        expect(() => sut.parseString('<?xml version="1.0"?><other></other>'),
            throwsA(isA<FormatException>()));
      });

      test('фолбэк на тип по первому child если user_export_type пуст', () {
        const String xml = '''
<?xml version="1.0"?>
<myanimelist>
  <myinfo></myinfo>
  <anime>
    <series_animedb_id>1</series_animedb_id>
    <series_title>x</series_title>
    <my_status>Completed</my_status>
  </anime>
</myanimelist>
''';
        expect(sut.parseString(xml).kind, MalFileKind.anime);
      });

      test('пропускает запись с невалидным malId', () {
        const String xml = '''
<?xml version="1.0"?>
<myanimelist>
  <myinfo><user_export_type>1</user_export_type></myinfo>
  <anime>
    <series_animedb_id>0</series_animedb_id>
    <series_title>bad</series_title>
    <my_status>Completed</my_status>
  </anime>
  <anime>
    <series_animedb_id>5</series_animedb_id>
    <series_title>good</series_title>
    <my_status>Completed</my_status>
  </anime>
</myanimelist>
''';
        final MalParsedFile parsed = sut.parseString(xml);
        expect(parsed.entries, hasLength(1));
        expect(parsed.entries.first.malId, 5);
      });
    });

    group('import', () {
      const String singleAnimeXml = '''
<?xml version="1.0"?>
<myanimelist>
  <myinfo><user_export_type>1</user_export_type></myinfo>
  <anime>
    <series_animedb_id>5114</series_animedb_id>
    <series_title>FMA</series_title>
    <series_episodes>64</series_episodes>
    <my_watched_episodes>30</my_watched_episodes>
    <my_status>Completed</my_status>
    <my_score>9</my_score>
    <my_times_watched>0</my_times_watched>
    <my_tags>Action</my_tags>
  </anime>
</myanimelist>
''';

      void stubAnimeLookup({
        Map<int, Anime> resolved = const <int, Anime>{},
        List<int> failedIds = const <int>[],
      }) {
        when(() => mockAniList.getAnimeByMalIdsTolerant(
              any(),
              onRateLimit: any(named: 'onRateLimit'),
              onBatchProgress: any(named: 'onBatchProgress'),
            )).thenAnswer((_) async => AniListMalLookupResult<Anime>(
              resolved: resolved,
              failedIds: failedIds,
            ));
      }

      MalImportOptions opts(String path) => MalImportOptions(
            animeFile: File(path),
            author: 'me',
            newCollectionName: 'MAL',
            collectionId: 1,
          );

      List<Map<String, dynamic>> capturedItemRows() =>
          verify(() => mockRepo.addItemsBatch(any(), captureAny()))
              .captured
              .single as List<Map<String, dynamic>>;

      test('completed аниме досыпает episode до total из AniList', () async {
        final MalParsedFile parsed = sut.parseString(singleAnimeXml);
        final MalEntry entry = parsed.entries.first;
        expect(entry.watchedEpisodes, 30);
        expect(entry.totalEpisodesXml, 64);
        expect(entry.status, ItemStatus.completed);
      });

      test('unmatched запись попадает в wishlist с MAL-ссылкой в note',
          () async {
        stubAnimeLookup();

        final List<Map<String, dynamic>>? rows = await _runWithTempFile(
          singleAnimeXml,
          (String path) async {
            await sut.import(opts(path));
            return verify(() => mockWishlist.addWishlistItemsBatch(captureAny()))
                .captured
                .single as List<Map<String, dynamic>>;
          },
        );

        final Map<String, dynamic> row = rows!.single;
        expect(row['media_type_hint'], MediaType.anime.value);
        expect(row['note'], contains('https://myanimelist.net/anime/5114'));
        expect(row['note'], contains('Status: Completed'));
        expect(row['note'], contains('Score: 9/10'));
        expect(row['tag'], startsWith('MyAnimeList-'));
      });

      test('повторный импорт обновляет существующий, не создаёт новый',
          () async {
        stubAnimeLookup(resolved: const <int, Anime>{
          5114: Anime(id: 999, title: 'FMA', episodes: 64),
        });
        when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
            <CollectionItem>[
              createTestCollectionItem(
                id: 555,
                mediaType: MediaType.anime,
                externalId: 999,
                status: ItemStatus.inProgress,
                currentEpisode: 10,
              ),
            ]);

        await _runWithTempFile(singleAnimeXml, (String path) async {
          final UniversalImportResult result = await sut.import(
            MalImportOptions(
              animeFile: File(path),
              author: 'me',
              newCollectionName: 'MAL',
              collectionId: 1,
              overwriteExistingItems: true,
            ),
          );
          expect(result.totalImported, 0);
          expect(result.totalUpdated, 1);
          expect(result.totalWishlisted, 0);
          expect(capturedItemRows(), isEmpty);
          return null;
        });
      });

      test('overwriteExistingItems=false: существующий не трогается, пропускается',
          () async {
        stubAnimeLookup(resolved: const <int, Anime>{
          5114: Anime(id: 999, title: 'FMA', episodes: 64),
        });
        when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
            <CollectionItem>[
              createTestCollectionItem(
                id: 555,
                mediaType: MediaType.anime,
                externalId: 999,
                status: ItemStatus.inProgress,
                currentEpisode: 10,
              ),
            ]);

        await _runWithTempFile(singleAnimeXml, (String path) async {
          final UniversalImportResult result = await sut.import(opts(path));
          expect(result.totalImported, 0);
          expect(result.totalUpdated, 0);
          expect(result.totalWishlisted, 0);
          expect(result.skipped, greaterThanOrEqualTo(1));
          expect(capturedItemRows(), isEmpty);
          return null;
        });

        verifyNever(() => mockRepo.updateItemFieldsBatch(
              any(that: predicate<List<(int, Map<String, dynamic>)>>(
                (List<(int, Map<String, dynamic>)> u) => u.isNotEmpty,
              )),
            ));
      });

      test('failed lookup пропускается, не падает в wishlist', () async {
        stubAnimeLookup(failedIds: const <int>[5114]);

        await _runWithTempFile(singleAnimeXml, (String path) async {
          final UniversalImportResult result = await sut.import(opts(path));
          expect(result.totalImported, 0);
          expect(result.totalWishlisted, 0);
          expect(result.skipped, greaterThanOrEqualTo(1));
          expect(capturedItemRows(), isEmpty);
          return null;
        });

        verifyNever(() => mockWishlist.addWishlistItemsBatch(any()));
      });
    });
  });
}

Future<T?> _runWithTempFile<T>(
  String xml,
  Future<T?> Function(String path) body,
) async {
  final Directory dir = await Directory.systemTemp.createTemp('mal_test_');
  final File file = File('${dir.path}/test.xml');
  await file.writeAsString(xml);
  try {
    return await body(file.path);
  } finally {
    await dir.delete(recursive: true);
  }
}
