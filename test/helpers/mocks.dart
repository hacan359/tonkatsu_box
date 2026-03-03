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
import 'package:xerabora/core/api/vndb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/core/services/config_service.dart';
import 'package:xerabora/core/services/gamepad_service.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
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

class MockDatabaseService extends Mock implements DatabaseService {}

class MockConfigService extends Mock implements ConfigService {}

// ===== API =====

class MockIgdbApi extends Mock implements IgdbApi {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockSteamGridDbApi extends Mock implements SteamGridDbApi {}

class MockVndbApi extends Mock implements VndbApi {}

// ===== Services =====

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

class FakeCanvasItem extends Fake implements CanvasItem {}

class FakeCanvasConnection extends Fake implements CanvasConnection {}

class FakeCanvasViewport extends Fake implements CanvasViewport {}

class FakeGame extends Fake implements Game {}
