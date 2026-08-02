import 'dart:typed_data';

import 'package:core/models/anime.dart';
import 'package:core/models/canvas_viewport.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/ra_game_progress.dart';
import 'package:core/models/tier_definition.dart';
import 'package:core/models/tracker_game_data.dart';
import 'package:core/models/tracker_profile.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/dao/global_tag_dao.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';

import 'mocks.dart';

void registerAllFallbacks() {
  registerFallbackValue(MediaType.game);
  registerFallbackValue(DataSource.tmdb);
  registerFallbackValue(ItemStatus.notStarted);
  registerFallbackValue(CollectionType.own);
  registerFallbackValue(ImageType.gameCover);

  registerFallbackValue(<int>{});
  registerFallbackValue(const Game(id: 0, name: 'fallback'));
  registerFallbackValue(const CustomMedia(id: 0, title: 'fallback'));
  registerFallbackValue(const Movie(tmdbId: 0, title: 'fallback'));
  registerFallbackValue(const TvShow(tmdbId: 0, title: 'fallback'));
  registerFallbackValue(const Anime(id: 0, title: 'fallback'));

  registerFallbackValue(FakeCanvasItem());
  registerFallbackValue(FakeCanvasConnection());
  registerFallbackValue(const CanvasViewport(collectionId: 0));

  registerFallbackValue(const <Game>[]);
  registerFallbackValue(const <Movie>[]);
  registerFallbackValue(const <TvShow>[]);
  registerFallbackValue(const <TvSeason>[]);
  registerFallbackValue(const <TvEpisode>[]);
  registerFallbackValue(const <Platform>[]);
  registerFallbackValue(const <Anime>[]);
  registerFallbackValue(const <Manga>[]);
  registerFallbackValue(const <int>[]);
  registerFallbackValue(const <int>{});

  registerFallbackValue(<TierDefinition>[]);
  registerFallbackValue(<TagSeed>[]);

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

  registerFallbackValue(const <ItemMark>[]);

  registerFallbackValue(Uint8List(0));
  registerFallbackValue(DateTime(2024));
  registerFallbackValue(Options());
  registerFallbackValue(_FakeBuildContext());
}

class _FakeBuildContext extends Fake implements BuildContext {}
