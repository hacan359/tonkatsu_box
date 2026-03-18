// Централизованная регистрация fallback-значений для mocktail.
//
// Вызывать один раз в setUpAll() каждого тестового файла, который
// использует any() / captureAny() для типов, требующих fallback.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_episode.dart';
import 'package:xerabora/shared/models/tv_season.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/shared/models/ra_game_progress.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

/// Регистрирует все fallback-значения, необходимые для mocktail.
///
/// Безопасно вызывать несколько раз — mocktail игнорирует повторные
/// регистрации того же типа.
void registerAllFallbacks() {
  // Enums
  registerFallbackValue(MediaType.game);
  registerFallbackValue(ItemStatus.notStarted);
  registerFallbackValue(CollectionType.own);
  registerFallbackValue(ImageType.gameCover);

  // Models
  registerFallbackValue(const Game(id: 0, name: 'fallback'));
  registerFallbackValue(const Movie(tmdbId: 0, title: 'fallback'));
  registerFallbackValue(const TvShow(tmdbId: 0, title: 'fallback'));

  // Canvas
  registerFallbackValue(FakeCanvasItem());
  registerFallbackValue(FakeCanvasConnection());
  registerFallbackValue(const CanvasViewport(collectionId: 0));

  // Collections
  registerFallbackValue(const <Game>[]);
  registerFallbackValue(const <Movie>[]);
  registerFallbackValue(const <TvShow>[]);
  registerFallbackValue(const <TvSeason>[]);
  registerFallbackValue(const <TvEpisode>[]);
  registerFallbackValue(const <Platform>[]);
  registerFallbackValue(const <int>[]);

  // Tier lists
  registerFallbackValue(<TierDefinition>[]);

  // RA
  registerFallbackValue(const RaGameProgress(
    gameId: 0,
    title: 'fallback',
    consoleName: '',
    consoleId: 0,
    numAwarded: 0,
    maxPossible: 0,
    hardcoreMode: false,
  ));

  // Other
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(DateTime(2024));
  registerFallbackValue(Options());
}
