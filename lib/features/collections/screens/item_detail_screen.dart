import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/discord_rpc_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../../../core/database/dao/tracked_release_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/data_source.dart';
import '../../releases/providers/releases_provider.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/constants/platform_features.dart';
import '../helpers/collection_actions.dart';
import '../widgets/create_custom_item_dialog.dart';
import '../providers/collections_provider.dart';
import '../extensions/item_display_name.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/episode_tracker_section.dart';
import '../widgets/item_tags_section.dart';
import '../widgets/anime_progress_section.dart';
import '../widgets/manga_progress_section.dart';
import '../widgets/dialogs/add_time_dialog.dart';
import '../providers/tracker_provider.dart';
import '../../../shared/models/tracker_game_data.dart';
import '../widgets/ra_achievements_section.dart';
import '../widgets/item_detail/item_detail_app_bar.dart';
import '../widgets/item_detail/item_detail_canvas_view.dart';
import '../widgets/item_detail/item_detail_media_config.dart';
import '../widgets/item_detail/item_detail_ra_badge.dart';
import '../widgets/item_detail/seasons_info.dart';
import '../widgets/item_detail/uncategorized_banner.dart';
import '../widgets/ra_link_dialog.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/rename_item_dialog.dart';
import '../widgets/screenscraper_gallery_section.dart';
import '../widgets/reviews_section.dart';
import '../widgets/status_chip_row.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';

/// Unified detail screen for any collection item, dispatched off
/// [CollectionItem.mediaType].
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({
    required this.collectionId,
    required this.itemId,
    required this.isEditable,
    super.key,
  });

  /// Null for uncategorized items.
  final int? collectionId;
  final int itemId;
  final bool isEditable;

  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Деталь элемента',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+B', description: 'Переключить Board/Canvas'),
      ShortcutEntry(keys: 'Ctrl+L', description: 'Lock/Unlock канвас'),
      ShortcutEntry(keys: 'Ctrl+M', description: 'Переместить в коллекцию'),
      ShortcutEntry(keys: 'Alt+1..5', description: 'Установить рейтинг'),
      ShortcutEntry(keys: 'Alt+0', description: 'Сбросить рейтинг'),
    ],
  );

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _showCanvas = false;
  bool _isViewModeLocked = false;
  DiscordRpcService? _discordRpc;
  String? _currentItemName;

  bool get _hasCanvas => kCanvasEnabled && widget.collectionId != null;

  void _updateDiscordPresence(CollectionItem item) {
    if (!kDiscordRpcAvailable) return;
    final SettingsState settings = ref.read(settingsNotifierProvider);
    if (!settings.discordRpcEnabled) return;
    _discordRpc ??= ref.read(discordRpcServiceProvider);
    final TrackerGameData? raData = item.mediaType == MediaType.game
        ? ref.read(trackerDetailProvider((gameId: item.externalId, platformId: item.platformId))).valueOrNull?.gameData
        : null;
    _discordRpc!.updatePresence(
      item,
      raData: raData,
      animeMangaTitleLanguage: settings.animeMangaTitleLanguage,
    );
  }

  @override
  void dispose() {
    _discordRpc?.clearPresence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync = ref.watch(
      collectionItemsNotifierProvider(widget.collectionId),
    );

    return itemsAsync.when(
      data: (List<CollectionItem> items) {
        final CollectionItem? item = _findItem(items);
        if (item == null) {
          return Scaffold(
            appBar: const ScreenAppBar(),
            body: Center(child: Text(_notFoundMessage(context, null))),
          );
        }
        return _buildContent(item);
      },
      loading: () => const Scaffold(
        appBar: ScreenAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: const ScreenAppBar(),
        body: Center(
          child: Text(S.of(context).errorPrefix(error.toString())),
        ),
      ),
    );
  }

  void _toggleLock() {
    setState(() => _isViewModeLocked = !_isViewModeLocked);
    if (_isViewModeLocked) {
      ref
          .read(steamGridDbPanelProvider(widget.collectionId).notifier)
          .closePanel();
      ref
          .read(vgMapsPanelProvider(widget.collectionId).notifier)
          .closePanel();
    }
  }

  void _handleMenuAction(ItemDetailMenuAction action, CollectionItem item) {
    switch (action) {
      case ItemDetailMenuAction.refresh:
        _refreshFromApi(item);
      case ItemDetailMenuAction.rename:
        _renameItem(item);
      case ItemDetailMenuAction.move:
        _moveToCollection(item);
      case ItemDetailMenuAction.clone:
        _cloneToCollection(item);
      case ItemDetailMenuAction.remove:
        _removeFromCollection(item);
    }
  }

  /// Release tracking covers only TMDB-backed TV shows and anime for now.
  bool _canTrackReleases(CollectionItem item) =>
      item.mediaType == MediaType.tvShow ||
      item.mediaType == MediaType.animation;

  Future<void> _toggleTracked(CollectionItem item) async {
    final TrackedReleaseDao dao = ref.read(trackedReleaseDaoProvider);
    final bool tracked =
        await dao.isTracked(item.externalId, DataSource.tmdb, item.mediaType);
    if (tracked) {
      await dao.unsubscribe(item.externalId, DataSource.tmdb, item.mediaType);
    } else {
      await dao.subscribe(item.externalId, DataSource.tmdb, item.mediaType);
    }
    ref.invalidate(isReleaseTrackedProvider(
      (externalId: item.externalId, mediaType: item.mediaType),
    ));
    ref.invalidate(releasesProvider);
  }

  Future<void> _refreshFromApi(CollectionItem item) async {
    final bool ok = await CollectionActions.refreshItemFromApi(
      context: context,
      ref: ref,
      item: item,
    );
    if (!ok || !mounted) return;
    // The detail screen reads from the cache tables; nudging the items
    // provider makes sure the refreshed row reaches the open view.
    ref.invalidate(collectionItemsNotifierProvider(widget.collectionId));
  }

  void _addAnimeMangaSuggestions(
    List<RenameSuggestion> out,
    S l, {
    required String romaji,
    required String? english,
    required String? native,
  }) {
    out.add(RenameSuggestion(
      label: l.settingsAnimeMangaTitleLanguageRomaji,
      value: romaji,
    ));
    if (english != null && english.isNotEmpty) {
      out.add(RenameSuggestion(
        label: l.settingsAnimeMangaTitleLanguageEnglish,
        value: english,
      ));
    }
    if (native != null && native.isNotEmpty) {
      out.add(RenameSuggestion(
        label: l.settingsAnimeMangaTitleLanguageNative,
        value: native,
      ));
    }
  }

  Future<void> _renameItem(CollectionItem item) async {
    final String original = item.cachedName ?? item.itemName;
    final S l = S.of(context);
    final List<RenameSuggestion> suggestions = <RenameSuggestion>[];
    if (item.mediaType == MediaType.anime && item.anime != null) {
      _addAnimeMangaSuggestions(
        suggestions, l,
        romaji: item.anime!.title,
        english: item.anime!.titleEnglish,
        native: item.anime!.titleNative,
      );
    } else if (item.mediaType == MediaType.manga && item.manga != null) {
      _addAnimeMangaSuggestions(
        suggestions, l,
        romaji: item.manga!.title,
        english: item.manga!.titleEnglish,
        native: item.manga!.titleNative,
      );
    }
    final String? result = await RenameItemDialog.show(
      context,
      currentOverride: item.overrideName,
      originalName: original,
      suggestions: suggestions,
    );
    if (result == null || !mounted) return;
    // Empty string from the dialog = "reset to original".
    final String? newName = result.isEmpty ? null : result;
    if (newName == item.overrideName) return;

    await ref
        .read(
          collectionItemsNotifierProvider(widget.collectionId).notifier,
        )
        .setOverrideName(item.id, newName);
  }

  Future<void> _moveToCollection(CollectionItem item) async {
    final S l = S.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final bool isUncategorized = widget.collectionId == null;

    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: widget.collectionId,
      showUncategorized: !isUncategorized,
      title: l.collectionMoveToCollection,
    );
    if (choice == null || !mounted) return;

    final int? targetCollectionId;
    final String targetName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        targetCollectionId = collection.id;
        targetName = collection.name;
      case WithoutCollection():
        targetCollectionId = null;
        targetName = l.collectionsUncategorized;
    }

    final ({bool success, bool sourceEmpty}) result = await ref
        .read(
          collectionItemsNotifierProvider(widget.collectionId).notifier,
        )
        .moveItem(
          item.id,
          targetCollectionId: targetCollectionId,
          mediaType: item.mediaType,
        );

    if (!mounted) return;

    if (result.success) {
      final String displayName = ref.currentDisplayNameOf(item);
      context.showSnack(
        S.of(context).collectionItemMovedTo(displayName, targetName),
        type: SnackType.success,
      );
      if (result.sourceEmpty && widget.collectionId != null) {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(S.of(context).collectionEmpty),
            content: Text(S.of(context).collectionDeleteEmptyPrompt),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(S.of(context).keep),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(S.of(context).delete),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await ref
              .read(collectionsProvider.notifier)
              .delete(widget.collectionId!);
        }
      }
      if (mounted) navigator.pop();
    } else {
      final String displayName = ref.currentDisplayNameOf(item);
      context.showSnack(
        S.of(context).collectionItemAlreadyExists(displayName, targetName),
      );
    }
  }

  Future<void> _cloneToCollection(CollectionItem item) async {
    await CollectionActions.cloneItem(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
      item: item,
    );
  }

  Future<void> _removeFromCollection(CollectionItem item) async {
    final String displayName = ref.currentDisplayNameOf(item);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).collectionRemoveItemTitle),
        content: Text(S.of(context).collectionRemoveItemMessage(displayName)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(S.of(context).remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(
          collectionItemsNotifierProvider(widget.collectionId).notifier,
        )
        .removeItem(item.id, mediaType: item.mediaType);

    if (mounted) {
      context.showSnack(
        S.of(context).collectionItemRemoved(displayName),
        type: SnackType.success,
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _editCustomItem(CollectionItem item) async {
    if (item.customMedia == null) return;

    final CustomItemData? data = await CreateCustomItemDialog.edit(
      context,
      item.customMedia!,
    );
    if (data == null || !mounted) return;

    // Cache local files and mark coverUrl so the renderer reads from disk.
    String? newCoverUrl = data.coverUrl;
    if (data.localCoverPath != null) {
      final File sourceFile = File(data.localCoverPath!);
      if (sourceFile.existsSync()) {
        final ImageCacheService cache = ref.read(imageCacheServiceProvider);
        final Uint8List bytes = await sourceFile.readAsBytes();
        final bool saved = await cache.saveImageBytes(
          ImageType.customCover,
          item.externalId.toString(),
          bytes,
        );
        if (saved) {
          newCoverUrl = CustomMedia.localCoverMarker;
        }
      }
    }

    final bool clearDisplayType = data.mediaType == MediaType.custom;
    final CustomMedia updated = item.customMedia!.copyWith(
      title: data.title,
      altTitle: data.altTitle,
      description: data.description,
      coverUrl: newCoverUrl,
      year: data.year,
      genres: data.genres,
      platformName: data.platform,
      externalUrl: data.externalUrl,
      displayType: clearDisplayType ? null : data.mediaType,
      clearDisplayType: clearDisplayType,
    );

    final DatabaseService db = ref.read(databaseServiceProvider);
    await db.customMediaDao.update(updated);

    ref
        .read(
          collectionItemsNotifierProvider(widget.collectionId).notifier,
        )
        .refresh();

    if (mounted) {
      context.showSnack(
        S.of(context).customItemUpdated,
        type: SnackType.success,
      );
    }
  }

  CollectionItem? _findItem(List<CollectionItem> items) {
    for (final CollectionItem item in items) {
      if (item.id == widget.itemId) {
        return item;
      }
    }
    return null;
  }

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts(
    CollectionItem item,
  ) {
    if (kIsMobile) return <ShortcutActivator, VoidCallback>{};

    return <ShortcutActivator, VoidCallback>{
      if (_hasCanvas)
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            () => setState(() => _showCanvas = !_showCanvas),
      if (widget.isEditable && _hasCanvas && _showCanvas)
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            _toggleLock,
      if (widget.isEditable)
        const SingleActivator(LogicalKeyboardKey.keyM, control: true):
            () => _moveToCollection(item),
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true):
          () => _updateUserRating(item.id, 1),
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true):
          () => _updateUserRating(item.id, 2),
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true):
          () => _updateUserRating(item.id, 3),
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true):
          () => _updateUserRating(item.id, 4),
      const SingleActivator(LogicalKeyboardKey.digit5, alt: true):
          () => _updateUserRating(item.id, 5),
      const SingleActivator(LogicalKeyboardKey.digit0, alt: true):
          () => _updateUserRating(item.id, null),
    };
  }

  Widget _buildContent(CollectionItem item) {
    final String displayName = ref.displayNameOf(item);
    _currentItemName = displayName;
    _updateDiscordPresence(item);
    final ItemDetailMediaConfig config =
        ItemDetailMediaConfig.from(item, context);

    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(item),
      child: Scaffold(
        appBar: ItemDetailAppBar(
          item: item,
          displayName: displayName,
          isEditable: widget.isEditable,
          hasCanvas: _hasCanvas,
          showCanvas: _showCanvas,
          isViewModeLocked: _isViewModeLocked,
          onToggleLock: _toggleLock,
          onToggleCanvas: () => setState(() => _showCanvas = !_showCanvas),
          onEditCustom: () => _editCustomItem(item),
          onMenuSelected: (ItemDetailMenuAction action) =>
              _handleMenuAction(action, item),
          canTrackReleases: _canTrackReleases(item),
          isTracked: _canTrackReleases(item) &&
              (ref
                      .watch(isReleaseTrackedProvider((
                        externalId: item.externalId,
                        mediaType: item.mediaType,
                      )))
                      .valueOrNull ??
                  false),
          onToggleTracked: () => _toggleTracked(item),
        ),
        body: _showCanvas && _hasCanvas
            ? ItemDetailCanvasView(
                collectionId: widget.collectionId,
                itemId: widget.itemId,
                isEditable: widget.isEditable && !_isViewModeLocked,
                currentItemName: _currentItemName ?? '',
              )
            : _buildDetailView(item, config, displayName),
      ),
    );
  }

  Widget _buildDetailView(
    CollectionItem item,
    ItemDetailMediaConfig config,
    String displayName,
  ) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    // Recommendations / reviews are TMDB-only.
    final bool showRecs = settings.showRecommendations &&
        (item.mediaType == MediaType.movie ||
            item.mediaType == MediaType.tvShow ||
            item.mediaType == MediaType.animation);

    return MediaDetailView(
      title: displayName,
      coverUrl: config.coverUrl,
      externalUrl: config.externalUrl,
      backdropUrl: config.backdropUrl,
      placeholderIcon: config.placeholderIcon,
      source: config.source,
      typeIcon: config.typeIcon,
      typeLabel: config.typeLabel,
      infoChips: config.infoChips,
      description: config.description,
      cacheImageType: config.cacheImageType,
      cacheImageId: config.cacheImageId,
      statusWidget: StatusChipRow(
        status: item.status,
        mediaType: item.mediaType,
        onChanged: (ItemStatus status) =>
            _updateStatus(item.id, status, item.mediaType),
      ),
      addedAt: item.addedAt,
      startedAt: item.startedAt,
      completedAt: item.completedAt,
      lastActivityAt: item.lastActivityAt,
      completionTime: item.completionTime,
      onActivityDateChanged: widget.isEditable
          ? (String type, DateTime date) =>
              _updateActivityDate(item.id, type, date)
          : null,
      tagWidget: widget.collectionId != null
          ? ItemTagsSection(
              collectionId: widget.collectionId!,
              itemId: item.id,
              currentTagId: item.tagId,
              isEditable: widget.isEditable,
            )
          : null,
      raBadge: item.mediaType == MediaType.game
          ? ItemDetailRaBadge(item: item, onLink: () => _linkRa(item))
          : null,
      trackerSection: _buildTrackerSection(item),
      timeSpentMinutes: item.timeSpentMinutes,
      onTimeSpentTap: widget.collectionId != null && widget.isEditable
          ? () => _showTimeSpentDialog(item)
          : null,
      mediaGallery: ScreenScraperGallerySection(
        gameName: item.itemName,
        igdbPlatformId: item.platformId,
      ),
      extraSections: <Widget>[
        if (widget.collectionId == null)
          UncategorizedBanner(onMove: () => _moveToCollection(item)),
        if (config.hasEpisodeTracker && widget.collectionId != null)
          EpisodeTrackerSection(
            collectionId: widget.collectionId,
            externalId: item.externalId,
            tvShow: config.tvShow,
            accentColor: config.accentColor,
          ),
        if (config.hasEpisodeTracker && widget.collectionId == null)
          SeasonsInfo(
            totalSeasons: item.totalSeasons,
            totalEpisodes: item.totalEpisodes,
            accentColor: config.accentColor,
          ),
        if (config.hasMangaProgress && widget.collectionId != null)
          MangaProgressSection(
            itemId: item.id,
            collectionId: widget.collectionId,
            manga: config.manga,
            currentChapter: item.currentEpisode,
            currentVolume: item.currentSeason,
            accentColor: config.accentColor,
          ),
        if (config.hasAnimeProgress && widget.collectionId != null)
          AnimeProgressSection(
            itemId: item.id,
            collectionId: widget.collectionId,
            anime: config.anime,
            currentEpisode: item.currentEpisode,
            accentColor: config.accentColor,
          ),
      ],
      recommendationSections: <Widget>[
        if (showRecs)
          RecommendationsSection(
            tmdbId: item.externalId,
            mediaType: item.mediaType,
            onAddMovie: _addMovieFromRecommendations,
            onAddTvShow: _addTvShowFromRecommendations,
          ),
        if (showRecs)
          ReviewsSection(
            tmdbId: item.externalId,
            mediaType: item.mediaType,
          ),
      ],
      authorComment: item.authorComment,
      userComment: item.userComment,
      hasAuthorComment: item.hasAuthorComment,
      hasUserComment: item.hasUserComment,
      isEditable: widget.isEditable,
      onAuthorCommentSave: (String? text) =>
          _saveAuthorComment(item.id, text),
      onUserCommentSave: (String? text) =>
          _saveUserComment(item.id, text),
      userRating: item.userRating,
      onUserRatingChanged: (double? rating) =>
          _updateUserRating(item.id, rating),
      accentColor: config.accentColor,
      platformOverlayAsset:
          ref.watch(settingsNotifierProvider).resolveOverlay(
            platformOverlay: item.platform?.overlayAsset,
            mediaTypeOverlay: item.mediaType.overlayAsset,
          ),
      embedded: true,
    );
  }

  String _notFoundMessage(BuildContext context, MediaType? mediaType) {
    final S l = S.of(context);
    return switch (mediaType) {
      MediaType.game => l.gameNotFound,
      MediaType.movie => l.movieNotFound,
      MediaType.tvShow => l.tvShowNotFound,
      MediaType.animation => l.animationNotFound,
      MediaType.visualNovel => l.visualNovelNotFound,
      MediaType.manga => l.mangaNotFound,
      MediaType.anime => l.mediaTypeAnime,
      MediaType.custom => l.unknownCustom,
      null => l.gameNotFound,
    };
  }

  Future<void> _showTimeSpentDialog(CollectionItem item) async {
    final int? collId = widget.collectionId;
    if (collId == null) return;
    final int? minutes = await AddTimeDialog.show(
      context,
      initialMinutes: item.timeSpentMinutes,
      isEdit: item.timeSpentMinutes > 0,
    );
    if (minutes == null || !mounted) return;
    await ref
        .read(collectionItemsNotifierProvider(collId).notifier)
        .setTimeSpent(item.id, minutes);
  }

  Widget? _buildTrackerSection(CollectionItem item) {
    if (item.mediaType != MediaType.game) return null;
    final bool hasData = ref.watch(
      trackerDetailProvider((gameId: item.externalId, platformId: item.platformId)).select(
        (AsyncValue<TrackerDetailState> v) =>
            v.valueOrNull?.hasRaData ?? false,
      ),
    );
    if (hasData) {
      return RaAchievementsSection(
        gameId: item.externalId,
        platformId: item.platformId,
      );
    }
    return null;
  }


  Future<void> _addMovieFromRecommendations(Movie movie) => _addRecommendation(
        tmdbId: movie.tmdbId,
        title: movie.title,
        mediaType: MediaType.movie,
        ownMapProvider: collectedMovieIdsProvider,
        upsert: (DatabaseService db) => db.upsertMovie(movie),
      );

  Future<void> _addTvShowFromRecommendations(TvShow tvShow) =>
      _addRecommendation(
        tmdbId: tvShow.tmdbId,
        title: tvShow.title,
        mediaType: MediaType.tvShow,
        ownMapProvider: collectedTvShowIdsProvider,
        upsert: (DatabaseService db) => db.upsertTvShow(tvShow),
      );

  Future<void> _addRecommendation({
    required int tmdbId,
    required String title,
    required MediaType mediaType,
    required FutureProvider<Map<int, List<CollectedItemInfo>>> ownMapProvider,
    required Future<void> Function(DatabaseService db) upsert,
  }) async {
    final Map<int, List<CollectedItemInfo>> ownMap =
        await ref.read(ownMapProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedAnimations =
        await ref.read(collectedAnimationIdsProvider.future);
    final Set<int?> alreadyIn = <CollectedItemInfo>[
      ...ownMap[tmdbId] ?? <CollectedItemInfo>[],
      ...collectedAnimations[tmdbId] ?? <CollectedItemInfo>[],
    ].map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    await upsert(ref.read(databaseServiceProvider));

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(mediaType: mediaType, externalId: tmdbId);

    if (!mounted) return;

    context.showSnack(
      success
          ? l.searchAddedToNamed(title, collectionName)
          : l.searchAlreadyInNamed(title, collectionName),
      type: success ? SnackType.success : SnackType.info,
    );
  }

  Future<void> _updateStatus(
    int id,
    ItemStatus status,
    MediaType mediaType,
  ) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status, mediaType);
  }

  Future<void> _updateActivityDate(int id, String type, DateTime date) async {
    final CollectionItemsNotifier notifier =
        ref.read(collectionItemsNotifierProvider(widget.collectionId).notifier);
    if (type == 'started') {
      await notifier.updateActivityDates(
        id,
        startedAt: date,
        lastActivityAt: DateTime.now(),
      );
    } else {
      await notifier.updateActivityDates(
        id,
        completedAt: date,
        lastActivityAt: DateTime.now(),
      );
    }
  }

  Future<void> _saveAuthorComment(int id, String? text) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateAuthorComment(id, text);
  }

  Future<void> _saveUserComment(int id, String? text) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateUserComment(id, text);
  }

  Future<void> _updateUserRating(int id, double? rating) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateUserRating(id, rating);
  }

  Future<void> _linkRa(CollectionItem item) async {
    final RaLinkResult? result = await showRaLinkDialog(
      context,
      gameName: item.itemName,
      platformId: item.platformId,
    );
    if (result == null || !mounted) return;

    await ref
        .read(trackerDetailProvider((gameId: item.externalId, platformId: item.platformId)).notifier)
        .linkRaGame(
          raGameId: result.raGameId,
          raTitle: result.title,
          achievementsTotal: result.numAchievements,
        );

    if (mounted) {
      context.showSnack(S.of(context).raLinkSuccess);
    }
  }
}

