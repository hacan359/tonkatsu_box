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
import 'package:xerabora/shared/models/tracker_game_data.dart';
import 'package:xerabora/shared/models/tracker_profile.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void registerAllFallbacks() {
  registerFallbackValue(MediaType.game);
  registerFallbackValue(ItemStatus.notStarted);
  registerFallbackValue(CollectionType.own);
  registerFallbackValue(ImageType.gameCover);

  registerFallbackValue(const Game(id: 0, name: 'fallback'));
  registerFallbackValue(const Movie(tmdbId: 0, title: 'fallback'));
  registerFallbackValue(const TvShow(tmdbId: 0, title: 'fallback'));

  registerFallbackValue(FakeCanvasItem());
  registerFallbackValue(FakeCanvasConnection());
  registerFallbackValue(const CanvasViewport(collectionId: 0));

  registerFallbackValue(const <Game>[]);
  registerFallbackValue(const <Movie>[]);
  registerFallbackValue(const <TvShow>[]);
  registerFallbackValue(const <TvSeason>[]);
  registerFallbackValue(const <TvEpisode>[]);
  registerFallbackValue(const <Platform>[]);
  registerFallbackValue(const <int>[]);

  registerFallbackValue(<TierDefinition>[]);

  registerFallbackValue(const RaGameProgress(
    gameId: 0,
    title: 'fallback',
    consoleName: '',
    consoleId: 0,
    numAwarded: 0,
    numAwardedHardcore: 0,
    maxPossible: 0,
    hardcoreMode: false,
  ));

  registerFallbackValue(TrackerType.ra);
  registerFallbackValue(const TrackerGameData(
    id: 0,
    trackerType: TrackerType.ra,
    gameId: 0,
    trackerGameId: '0',
    lastSyncedAt: 0,
  ));

  registerFallbackValue(Uint8List(0));
  registerFallbackValue(DateTime(2024));
  registerFallbackValue(Options());
}
