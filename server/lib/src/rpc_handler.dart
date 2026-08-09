import 'dart:convert';
import 'dart:io';

import 'package:core/rpc/generated/dao_dispatch.rpc.dart';
import 'package:core/rpc/rpc_codec.dart';
import 'package:shelf/shelf.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'protocol.dart';

/// One [Database] per process is deliberate: sqflite serialises through it,
/// which is what keeps a dispatched transaction atomic. Never pool.
class DaoRegistry {
  DaoRegistry(this.db);

  final Database db;

  Future<Database> _get() async => db;

  late final AniListTagDao aniListTagDao = AniListTagDao(_get);

  late final AnimeDao animeDao = AnimeDao(_get);

  late final BookDao bookDao = BookDao(_get);

  late final CalendarEntryDao calendarEntryDao = CalendarEntryDao(_get);

  late final CanvasDao canvasDao = CanvasDao(_get);

  late final CollectionDao collectionDao = CollectionDao.withMediaDaos(_get);

  late final CustomMediaDao customMediaDao = CustomMediaDao(_get);

  late final GameDao gameDao = GameDao(_get);

  late final GlobalTagDao globalTagDao = GlobalTagDao(_get);

  late final ItemMarkDao itemMarkDao = ItemMarkDao(_get);

  late final MangaDao mangaDao = MangaDao(_get);

  late final MangaBakaGenreDao mangaBakaGenreDao = MangaBakaGenreDao(_get);

  late final MangaBakaTagDao mangaBakaTagDao = MangaBakaTagDao(_get);

  late final MangaDexTagDao mangaDexTagDao = MangaDexTagDao(_get);

  late final MoodGridDao moodGridDao = MoodGridDao(_get);

  late final MovieDao movieDao = MovieDao(_get);

  late final StatsDao statsDao = StatsDao(_get);

  late final TierListDao tierListDao = TierListDao(_get);

  late final TrackedReleaseDao trackedReleaseDao = TrackedReleaseDao(_get);

  late final TrackerDao trackerDao = TrackerDao(_get);

  late final TvShowDao tvShowDao = TvShowDao(_get);

  late final VisualNovelDao visualNovelDao = VisualNovelDao(_get);

  late final WishlistDao wishlistDao = WishlistDao(_get);

  late final Map<String, DaoDispatch> table = buildDaoDispatchTable(
    aniListTagDao: aniListTagDao,
    animeDao: animeDao,
    bookDao: bookDao,
    calendarEntryDao: calendarEntryDao,
    canvasDao: canvasDao,
    collectionDao: collectionDao,
    customMediaDao: customMediaDao,
    gameDao: gameDao,
    globalTagDao: globalTagDao,
    itemMarkDao: itemMarkDao,
    mangaDao: mangaDao,
    mangaBakaGenreDao: mangaBakaGenreDao,
    mangaBakaTagDao: mangaBakaTagDao,
    mangaDexTagDao: mangaDexTagDao,
    moodGridDao: moodGridDao,
    movieDao: movieDao,
    statsDao: statsDao,
    tierListDao: tierListDao,
    trackedReleaseDao: trackedReleaseDao,
    trackerDao: trackerDao,
    tvShowDao: tvShowDao,
    visualNovelDao: visualNovelDao,
    wishlistDao: wishlistDao,
  );
}

/// `POST /rpc` — runs one DAO method next to the database.
Handler buildRpcHandler(DaoRegistry daos) {
  return (Request request) async {
    final Map<String, Object?> body;
    try {
      body = asObject(jsonDecode(await request.readAsString()));
    } on Object {
      return _error(HttpStatus.badRequest, 'protocol', 'Malformed JSON body');
    }

    final Object? protocol = body['protocol'];
    if (protocol != kProtocolVersion) {
      return _error(
        HttpStatus.badRequest,
        'protocol',
        'Protocol $protocol is not $kProtocolVersion — reload the page',
      );
    }

    final Object? dao = body['dao'];
    final Object? method = body['method'];
    if (dao is! String || method is! String) {
      return _error(
        HttpStatus.badRequest,
        'protocol',
        '`dao` and `method` must be strings',
      );
    }

    try {
      final Map<String, Object?> args = body['args'] == null
          ? <String, Object?>{}
          : asObject(body['args']);
      final Object? result = await _dispatch(daos, dao, method, args);
      return _json(HttpStatus.ok, <String, Object?>{
        'ok': true,
        'result': result,
      });
    } on RpcCodecException catch (e) {
      return _error(HttpStatus.ok, 'badRequest', e.message);
    } on DatabaseException catch (e) {
      return _error(HttpStatus.ok, 'database', e.toString());
    } on Object catch (e) {
      return _error(HttpStatus.ok, 'internal', e.toString());
    }
  };
}

Future<Object?> _dispatch(
  DaoRegistry daos,
  String dao,
  String method,
  Map<String, Object?> args,
) {
  final DaoDispatch? dispatch = daos.table[dao];
  if (dispatch == null) throw RpcCodecException('Unknown dao "$dao"');
  return dispatch(method, args);
}

Response _json(int status, Map<String, Object?> body) => Response(
  status,
  body: jsonEncode(body),
  headers: <String, String>{HttpHeaders.contentTypeHeader: 'application/json'},
);

/// A DAO-level failure still reached the DAO, so it answers 200 with an error
/// payload; only transport problems use a 4xx.
Response _error(int status, String kind, String message) =>
    _json(status, <String, Object?>{
      'ok': false,
      'error': <String, String>{'kind': kind, 'message': message},
    });
