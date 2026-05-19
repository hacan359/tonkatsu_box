import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../collections/providers/collections_provider.dart';
import '../services/search_collection_adder.dart';
import '../widgets/item_details_sheet.dart';
import 'game_handler.dart';
import 'media_action_handler.dart';
import 'movie_handler.dart';
import 'simple_media_handler.dart';
import 'tv_show_handler.dart';

/// Registry that maps search results to their per-source handlers.
///
/// Resolution is two-level:
/// 1. by `sourceId` — for the case when the same model type comes from
///    multiple sources (e.g. `Game` from IGDB *and* a future RAWG) and
///    needs source-specific logic;
/// 2. fallback by `runtimeType` — the default when no source override is
///    registered.
class MediaHandlers {
  MediaHandlers({
    required WidgetRef ref,
    required Map<int, Platform> Function() platformMap,
    required int? targetCollectionId,
    void Function(Game game)? onGameSelected,
  }) {
    final SearchCollectionAdder adder = SearchCollectionAdder(ref);
    _byType[Game] = GameHandler(
      ref: ref,
      adder: adder,
      platformMap: platformMap,
      targetCollectionId: targetCollectionId,
      onGameSelected: onGameSelected,
    );
    _byType[Movie] = MovieHandler(
      ref: ref,
      adder: adder,
      targetCollectionId: targetCollectionId,
    );
    _byType[TvShow] = TvShowHandler(
      ref: ref,
      adder: adder,
      targetCollectionId: targetCollectionId,
    );
    _byType[VisualNovel] = SimpleMediaHandler<VisualNovel>(
      ref: ref,
      adder: adder,
      targetCollectionId: targetCollectionId,
      mediaType: MediaType.visualNovel,
      imageType: ImageType.vnCover,
      collectedProvider: collectedVisualNovelIdsProvider,
      externalIdOf: (VisualNovel vn) => vn.numericId,
      imageIdOf: (VisualNovel vn) => vn.numericId.toString(),
      titleOf: (VisualNovel vn) => vn.title,
      imageUrlOf: (VisualNovel vn) => vn.imageUrl,
      upsert: (VisualNovel vn) =>
          ref.read(databaseServiceProvider).upsertVisualNovel(vn),
      sheetBuilder: (VisualNovel vn, VoidCallback onAdd) =>
          ItemDetailsSheet.visualNovel(vn, onAddToCollection: onAdd),
    );
    _byType[Manga] = SimpleMediaHandler<Manga>(
      ref: ref,
      adder: adder,
      targetCollectionId: targetCollectionId,
      mediaType: MediaType.manga,
      imageType: ImageType.mangaCover,
      collectedProvider: collectedMangaIdsProvider,
      externalIdOf: (Manga m) => m.id,
      imageIdOf: (Manga m) => m.id.toString(),
      titleOf: (Manga m) => m.title,
      imageUrlOf: (Manga m) => m.coverUrl,
      upsert: (Manga m) => ref.read(databaseServiceProvider).upsertManga(m),
      sheetBuilder: (Manga m, VoidCallback onAdd) =>
          ItemDetailsSheet.manga(m, onAddToCollection: onAdd),
    );
    _byType[Anime] = SimpleMediaHandler<Anime>(
      ref: ref,
      adder: adder,
      targetCollectionId: targetCollectionId,
      mediaType: MediaType.anime,
      imageType: ImageType.animeCover,
      collectedProvider: collectedAnimeIdsProvider,
      externalIdOf: (Anime a) => a.id,
      imageIdOf: (Anime a) => a.id.toString(),
      titleOf: (Anime a) => a.title,
      imageUrlOf: (Anime a) => a.coverUrl,
      upsert: (Anime a) => ref.read(databaseServiceProvider).upsertAnime(a),
      sheetBuilder: (Anime a, VoidCallback onAdd) =>
          ItemDetailsSheet.anime(a, onAddToCollection: onAdd),
    );
  }

  final Map<Type, MediaActionHandler> _byType =
      <Type, MediaActionHandler>{};
  final Map<String, MediaActionHandler> _bySource =
      <String, MediaActionHandler>{};

  /// Register a source-specific handler. Takes precedence over the
  /// type-based default for items dispatched with this [sourceId].
  void registerForSource(String sourceId, MediaActionHandler handler) {
    _bySource[sourceId] = handler;
  }

  MediaActionHandler? forItem(Object item, {String? sourceId}) {
    if (sourceId != null) {
      final MediaActionHandler? bySource = _bySource[sourceId];
      if (bySource != null) return bySource;
    }
    return _byType[item.runtimeType];
  }

  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType, {
    String? sourceId,
  }) async {
    final MediaActionHandler? handler =
        forItem(item, sourceId: sourceId);
    if (handler == null) return;
    await handler.onTap(context, item, mediaType);
  }

  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType, {
    String? sourceId,
  }) async {
    final MediaActionHandler? handler =
        forItem(item, sourceId: sourceId);
    if (handler == null) return;
    await handler.addToAnyCollection(context, item, mediaType);
  }
}
