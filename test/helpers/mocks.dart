// Единое хранилище mock-классов для всех тестов.
//
// Каждый mock объявляется ровно один раз. Тестовые файлы импортируют
// `test_helpers.dart`, который реэкспортирует этот файл.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/api/steamgriddb_api.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/api/anilist_api.dart';
import 'package:xerabora/core/api/vndb_api.dart';
import 'package:xerabora/core/database/dao/canvas_dao.dart';
import 'package:xerabora/core/database/dao/collection_dao.dart';
import 'package:xerabora/core/database/dao/game_dao.dart';
import 'package:xerabora/core/database/dao/movie_dao.dart';
import 'package:xerabora/core/database/dao/tv_show_dao.dart';
import 'package:xerabora/core/database/dao/manga_dao.dart';
import 'package:xerabora/core/database/dao/visual_novel_dao.dart';
import 'package:xerabora/core/database/dao/tier_list_dao.dart';
import 'package:xerabora/core/database/dao/wishlist_dao.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/core/services/config_service.dart';
import 'package:xerabora/core/services/gamepad_service.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/core/api/steam_api.dart';
import 'package:xerabora/core/services/steam_import_service.dart';
import 'package:xerabora/core/services/trakt_zip_import_service.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/data/repositories/game_repository.dart';
import 'package:xerabora/data/repositories/wishlist_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';

// ===== Core =====

class MockDio extends Mock implements Dio {}

class MockDatabase extends Mock implements Database {}

/// [MockDatabase] с прямым override [transaction] для тестов.
///
/// mocktail не может корректно стабить generic-метод `Database.transaction<T>()`
/// через `when(() => mockDb.transaction<void>(any()))`. Этот подкласс
/// решает проблему прямым override метода.
class TransactionMockDatabase extends MockDatabase {
  Transaction? _stubTxn;

  /// Задаёт mock [Transaction] для передачи в callback транзакции.
  // ignore: use_setters_to_change_properties
  void stubTransaction(Transaction txn) => _stubTxn = txn;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    if (_stubTxn == null) {
      throw StateError('transaction() called but not stubbed');
    }
    return action(_stubTxn!);
  }
}

class MockTransaction extends Mock implements Transaction {}

class MockBatch extends Mock implements Batch {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockConfigService extends Mock implements ConfigService {}

// ===== DAO =====

class MockGameDao extends Mock implements GameDao {}

class MockMovieDao extends Mock implements MovieDao {}

class MockTvShowDao extends Mock implements TvShowDao {}

class MockVisualNovelDao extends Mock implements VisualNovelDao {}

class MockMangaDao extends Mock implements MangaDao {}

class MockCollectionDao extends Mock implements CollectionDao {}

class MockCanvasDao extends Mock implements CanvasDao {}

class MockTierListDao extends Mock implements TierListDao {}

class MockWishlistDao extends Mock implements WishlistDao {}

// ===== API =====

class MockIgdbApi extends Mock implements IgdbApi {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockSteamGridDbApi extends Mock implements SteamGridDbApi {}

class MockVndbApi extends Mock implements VndbApi {}

class MockAniListApi extends Mock implements AniListApi {}

class MockSteamApi extends Mock implements SteamApi {}

// ===== Services =====

class MockSteamImportService extends Mock implements SteamImportService {}

class MockImageCacheService extends Mock implements ImageCacheService {}

class MockTraktZipImportService extends Mock
    implements TraktZipImportService {}

// ===== Repositories =====

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockCanvasRepository extends Mock implements CanvasRepository {}

class MockGameRepository extends Mock implements GameRepository {}

class MockWishlistRepository extends Mock implements WishlistRepository {}

// ===== Providers / Notifiers =====

/// Мок [CollectionItemsNotifier] с настраиваемым начальным состоянием.
///
/// Если [initialState] не передан, возвращает пустой список.
/// Метод [emitState] позволяет менять state в ходе теста.
class MockCollectionItemsNotifier extends CollectionItemsNotifier {
  MockCollectionItemsNotifier([this._initialState]);

  final AsyncValue<List<CollectionItem>>? _initialState;

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    return _initialState ??
        const AsyncValue<List<CollectionItem>>.data(<CollectionItem>[]);
  }

  void emitState(AsyncValue<List<CollectionItem>> newState) {
    state = newState;
  }
}

class MockWidgetRef extends Mock implements WidgetRef {}

// ===== Localization =====

class MockS extends Mock implements S {}

// ===== Gamepad =====

/// Мок-источник событий геймпада с ручным контроллером.
class MockGamepadEventSource implements GamepadEventSource {
  final StreamController<GamepadEvent> controller =
      StreamController<GamepadEvent>.broadcast();

  @override
  Stream<GamepadEvent> get events => controller.stream;

  void emit(GamepadEvent event) => controller.add(event);

  void dispose() => controller.close();
}

// ===== Fakes =====

/// Фейк [DatabaseException] c поддержкой isUniqueConstraintError.
class FakeDatabaseException extends Fake implements DatabaseException {
  @override
  bool isUniqueConstraintError([String? field]) => true;
}

class FakeCanvasItem extends Fake implements CanvasItem {}

class FakeCanvasConnection extends Fake implements CanvasConnection {}

class FakeCanvasViewport extends Fake implements CanvasViewport {}

class FakeGame extends Fake implements Game {}
