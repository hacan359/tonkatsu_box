// Единый экран детального просмотра элемента коллекции.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/discord_rpc_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../../shared/constants/platform_features.dart';
import '../helpers/collection_actions.dart';
import '../widgets/create_custom_item_dialog.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/canvas_view.dart';
import '../widgets/episode_tracker_section.dart';
import '../widgets/item_tags_section.dart';
import '../widgets/anime_progress_section.dart';
import '../widgets/manga_progress_section.dart';
import '../providers/tracker_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/ra_api.dart';
import '../../../core/services/ra_to_igdb_mapper.dart';
import '../../../shared/models/tracker_game_data.dart';
import '../widgets/ra_achievements_section.dart';
import '../widgets/ra_link_dialog.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/reviews_section.dart';
import '../widgets/status_chip_row.dart';
import '../widgets/steamgriddb_panel.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/vgmaps_panel.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';

/// Конфигурация медиа-типа для отображения в детальном экране.
class _MediaConfig {
  const _MediaConfig({
    required this.coverUrl,
    required this.placeholderIcon,
    required this.source,
    required this.typeIcon,
    required this.typeLabel,
    required this.cacheImageType,
    required this.cacheImageId,
    required this.accentColor,
    required this.infoChips,
    required this.description,
    required this.hasEpisodeTracker,
    required this.hasMangaProgress,
    required this.hasAnimeProgress,
    this.externalUrl,
    this.backdropUrl,
    this.tvShow,
    this.manga,
    this.anime,
  });

  final String? coverUrl;
  final IconData placeholderIcon;
  final DataSource source;
  final IconData typeIcon;
  final String typeLabel;
  final ImageType cacheImageType;
  final String cacheImageId;
  final Color accentColor;
  final List<MediaDetailChip> infoChips;
  final String? description;
  final bool hasEpisodeTracker;
  final bool hasMangaProgress;
  final bool hasAnimeProgress;
  final String? externalUrl;
  final String? backdropUrl;
  final TvShow? tvShow;
  final Manga? manga;
  final Anime? anime;
}

/// Единый экран детального просмотра элемента коллекции.
///
/// Заменяет GameDetailScreen, MovieDetailScreen, TvShowDetailScreen и
/// AnimeDetailScreen. Определяет тип медиа из [CollectionItem.mediaType]
/// и строит UI соответственно.
class ItemDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [ItemDetailScreen].
  const ItemDetailScreen({
    required this.collectionId,
    required this.itemId,
    required this.isEditable,
    super.key,
  });

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  /// ID записи элемента в коллекции.
  final int itemId;

  /// Можно ли редактировать комментарий автора.
  final bool isEditable;

  /// Группа хоткеев этого экрана для легенды F1.
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
    final bool enabled = ref.read(settingsNotifierProvider).discordRpcEnabled;
    if (!enabled) return;
    _discordRpc ??= ref.read(discordRpcServiceProvider);
    final TrackerGameData? raData = item.mediaType == MediaType.game
        ? ref.read(trackerDetailProvider(item.externalId)).valueOrNull?.gameData
        : null;
    _discordRpc!.updatePresence(item, raData: raData);
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

  // ==================== Navigation / Actions ====================

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
      context.showSnack(
        S.of(context).collectionItemMovedTo(item.itemName, targetName),
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
      context.showSnack(
        S.of(context).collectionItemAlreadyExists(item.itemName, targetName),
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).collectionRemoveItemTitle),
        content: Text(S.of(context).collectionRemoveItemMessage(item.itemName)),
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
        S.of(context).collectionItemRemoved(item.itemName),
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

    // Определяем coverUrl: при локальном файле — кэшируем и ставим маркер
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

    // Обновляем custom_items в БД
    final CustomMedia updated = item.customMedia!.copyWith(
      title: data.title,
      altTitle: data.altTitle,
      description: data.description,
      coverUrl: newCoverUrl,
      year: data.year,
      genres: data.genres,
      platformName: data.platform,
      externalUrl: data.externalUrl,
    );

    final DatabaseService db = ref.read(databaseServiceProvider);
    await db.customMediaDao.update(updated);

    // Рефрешим коллекцию
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

  // ==================== Content ====================

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts(
    CollectionItem item,
  ) {
    if (kIsMobile) return <ShortcutActivator, VoidCallback>{};

    return <ShortcutActivator, VoidCallback>{
      if (_hasCanvas)
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            () => setState(() => _showCanvas = !_showCanvas),
      if (widget.isEditable && _hasCanvas && _showCanvas)
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () {
          setState(() { _isViewModeLocked = !_isViewModeLocked; });
          if (_isViewModeLocked) {
            ref.read(steamGridDbPanelProvider(widget.collectionId).notifier).closePanel();
            ref.read(vgMapsPanelProvider(widget.collectionId).notifier).closePanel();
          }
        },
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
    _currentItemName = item.itemName;
    _updateDiscordPresence(item);
    final _MediaConfig config = _getMediaConfig(item);

    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(item),
      child: Scaffold(
        appBar: ScreenAppBar(
          title: item.itemName,
          actions: <Widget>[
            // Lock кнопка (только на Canvas)
            if (widget.isEditable && _hasCanvas && _showCanvas)
              IconButton(
                icon: Icon(
                  _isViewModeLocked ? Icons.lock : Icons.lock_open,
                ),
                color: _isViewModeLocked
                    ? AppColors.warning
                    : AppColors.textSecondary,
                tooltip: _isViewModeLocked
                    ? (!kIsMobile
                        ? '${S.of(context).collectionUnlockBoard} (Ctrl+L)'
                        : S.of(context).collectionUnlockBoard)
                    : (!kIsMobile
                        ? '${S.of(context).collectionLockBoard} (Ctrl+L)'
                        : S.of(context).collectionLockBoard),
                onPressed: () {
                  setState(() {
                    _isViewModeLocked = !_isViewModeLocked;
                  });
                  if (_isViewModeLocked) {
                    ref
                        .read(steamGridDbPanelProvider(widget.collectionId)
                            .notifier)
                        .closePanel();
                    ref
                        .read(vgMapsPanelProvider(widget.collectionId)
                            .notifier)
                        .closePanel();
                  }
                },
              ),
            // Board toggle кнопка
            if (_hasCanvas)
              IconButton(
                icon: Icon(
                  _showCanvas
                      ? Icons.dashboard
                      : Icons.dashboard_outlined,
                ),
                color: _showCanvas
                    ? AppColors.brand
                    : AppColors.textSecondary,
                tooltip: !kIsMobile
                    ? '${S.of(context).boardTab} (Ctrl+B)'
                    : S.of(context).boardTab,
                onPressed: () {
                  setState(() {
                    _showCanvas = !_showCanvas;
                  });
                },
              ),
            // Edit button (только для кастомных элементов)
            if (widget.isEditable && item.mediaType == MediaType.custom)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textSecondary,
                tooltip: S.of(context).customItemEdit,
                onPressed: () => _editCustomItem(item),
              ),
            // Popup menu
            if (widget.isEditable)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (String value) {
                  switch (value) {
                    case 'move':
                      _moveToCollection(item);
                    case 'clone':
                      _cloneToCollection(item);
                    case 'remove':
                      _removeFromCollection(item);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'move',
                    child: ListTile(
                      leading: const Icon(Icons.drive_file_move_outlined),
                      title: Text(S.of(context).collectionMoveToCollection),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'clone',
                    child: ListTile(
                      leading: const Icon(Icons.copy_outlined),
                      title: Text(S.of(context).collectionCopyToCollection),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        S.of(context).remove,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: _showCanvas && _hasCanvas
            ? _buildCanvasView()
            : _buildDetailView(item, config),
      ),
    );
  }

  Widget _buildDetailView(CollectionItem item, _MediaConfig config) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    // Рекомендации и ревью доступны только для TMDB-источников
    final bool showRecs = settings.showRecommendations &&
        (item.mediaType == MediaType.movie ||
            item.mediaType == MediaType.tvShow ||
            item.mediaType == MediaType.animation);

    return MediaDetailView(
      title: item.itemName,
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
      raBadge: _buildRaBadge(item),
      trackerSection: _buildTrackerSection(item),
      extraSections: <Widget>[
        if (widget.collectionId == null)
          _buildUncategorizedBanner(item),
        if (config.hasEpisodeTracker && widget.collectionId != null)
          EpisodeTrackerSection(
            collectionId: widget.collectionId,
            externalId: item.externalId,
            tvShow: config.tvShow,
            accentColor: config.accentColor,
          ),
        if (config.hasEpisodeTracker && widget.collectionId == null)
          _buildSeasonsInfo(item, config.accentColor),
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
      onUserRatingChanged: (int? rating) =>
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

  // ==================== Media Config ====================

  _MediaConfig _getMediaConfig(CollectionItem item) {
    // Извлекаем externalUrl из вложенной модели медиа
    final String? externalUrl = switch (item.mediaType) {
      MediaType.game => item.game?.externalUrl,
      MediaType.movie || MediaType.animation => item.movie?.externalUrl
          ?? item.tvShow?.externalUrl,
      MediaType.tvShow => item.tvShow?.externalUrl,
      MediaType.visualNovel => item.visualNovel?.externalUrl,
      MediaType.manga => item.manga?.externalUrl,
      MediaType.anime => item.anime?.externalUrl,
      MediaType.custom => item.customMedia?.externalUrl,
    };

    return _MediaConfig(
      coverUrl: item.thumbnailUrl,
      placeholderIcon: item.placeholderIcon,
      source: item.dataSource,
      typeIcon: item.mediaType == MediaType.game
          ? Icons.sports_esports
          : item.placeholderIcon,
      typeLabel: _typeLabel(item),
      cacheImageType: item.imageType,
      cacheImageId: item.externalId.toString(),
      accentColor: MediaTypeTheme.colorFor(item.displayMediaType),
      infoChips: _buildChips(item),
      description: item.itemDescription,
      hasEpisodeTracker: item.mediaType == MediaType.tvShow ||
          (item.mediaType == MediaType.animation &&
              item.platformId == AnimationSource.tvShow),
      hasMangaProgress: item.mediaType == MediaType.manga,
      hasAnimeProgress: item.mediaType == MediaType.anime,
      externalUrl: externalUrl,
      backdropUrl: item.game?.artworkUrl
          ?? item.movie?.backdropUrl
          ?? item.tvShow?.backdropUrl
          ?? item.manga?.bannerUrl
          ?? item.anime?.bannerUrl,
      tvShow: item.tvShow,
      manga: item.manga,
      anime: item.anime,
    );
  }

  String _typeLabel(CollectionItem item) {
    final S l = S.of(context);
    return switch (item.mediaType) {
      MediaType.game => item.platformName,
      MediaType.movie => l.mediaTypeMovie,
      MediaType.tvShow => l.mediaTypeTvShow,
      MediaType.animation => item.platformId == AnimationSource.tvShow
          ? l.animatedSeries
          : l.animatedMovie,
      MediaType.visualNovel => l.mediaTypeVisualNovel,
      MediaType.manga => l.mediaTypeManga,
      MediaType.anime => l.mediaTypeAnime,
      MediaType.custom => item.customMedia?.platformName ?? l.mediaTypeCustom,
    };
  }

  // ==================== Info Chips ====================

  List<MediaDetailChip> _buildChips(CollectionItem item) {
    final S l = S.of(context);
    final List<MediaDetailChip> chips = <MediaDetailChip>[];
    if (item.releaseYear != null) {
      chips.add(MediaDetailChip(
        icon: Icons.calendar_today_outlined,
        text: item.releaseYear.toString(),
      ));
    }
    if (item.runtime != null) {
      chips.add(MediaDetailChip(
        icon: Icons.schedule_outlined,
        text: _formatRuntime(item.runtime!),
      ));
    }
    if (item.totalSeasons != null) {
      chips.add(MediaDetailChip(
        icon: Icons.video_library_outlined,
        text: l.totalSeasons(item.totalSeasons!),
      ));
    }
    if (item.totalEpisodes != null) {
      chips.add(MediaDetailChip(
        icon: Icons.playlist_play,
        text: l.totalEpisodes(item.totalEpisodes!),
      ));
    }
    if (item.formattedRating != null) {
      chips.add(MediaDetailChip(
        icon: Icons.star,
        text: '${item.formattedRating}/10',
        iconColor: AppColors.ratingStar,
      ));
    }
    // Custom-специфичные чипы: altTitle, platformName
    if (item.mediaType == MediaType.custom && item.customMedia != null) {
      final CustomMedia c = item.customMedia!;
      if (c.altTitle != null && c.altTitle!.isNotEmpty) {
        chips.add(MediaDetailChip(
          icon: Icons.translate,
          text: c.altTitle!,
        ));
      }
      if (c.platformName != null && c.platformName!.isNotEmpty) {
        chips.add(MediaDetailChip(
          icon: Icons.sports_esports,
          text: c.platformName!,
        ));
      }
    }
    // Manga-специфичные чипы: chapters, volumes, format, authors
    if (item.mediaType == MediaType.manga && item.manga != null) {
      final Manga m = item.manga!;
      chips.add(MediaDetailChip(
        icon: Icons.menu_book,
        text: m.progressString,
      ));
      if (m.formatLabel != null) {
        chips.add(MediaDetailChip(
          icon: Icons.category_outlined,
          text: m.formatLabel!,
        ));
      }
      if (m.authorsString != null) {
        chips.add(MediaDetailChip(
          icon: Icons.person_outline,
          text: m.authorsString!,
        ));
      }
    }
    // Anime-специфичные чипы: format, episodes, duration, studios, season, source
    if (item.mediaType == MediaType.anime && item.anime != null) {
      final Anime a = item.anime!;
      if (a.formatLabel != null) {
        chips.add(MediaDetailChip(
          icon: Icons.category_outlined,
          text: a.formatLabel!,
        ));
      }
      chips.add(MediaDetailChip(
        icon: Icons.playlist_play,
        text: a.episodesString,
      ));
      if (a.durationString != null) {
        chips.add(MediaDetailChip(
          icon: Icons.schedule_outlined,
          text: a.durationString!,
        ));
      }
      if (a.studiosString != null) {
        chips.add(MediaDetailChip(
          icon: Icons.business,
          text: a.studiosString!,
        ));
      }
      if (a.seasonLabel != null) {
        chips.add(MediaDetailChip(
          icon: Icons.date_range,
          text: a.seasonLabel!,
        ));
      }
      if (a.sourceLabel != null) {
        chips.add(MediaDetailChip(
          icon: Icons.source,
          text: a.sourceLabel!,
        ));
      }
    }
    if (item.mediaStatus != null) {
      chips.add(MediaDetailChip(
        icon: Icons.info_outline,
        text: item.mediaStatus!,
      ));
    }
    if (item.genresString != null &&
        item.mediaType != MediaType.manga) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: item.genresString!,
      ));
    }
    return chips;
  }

  String _formatRuntime(int minutes) {
    final S l = S.of(context);
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return l.runtimeHoursMinutes(hours, mins);
    } else if (hours > 0) {
      return l.runtimeHours(hours);
    }
    return l.runtimeMinutes(mins);
  }

  // ==================== Uncategorized Helpers ====================

  Widget _buildUncategorizedBanner(CollectionItem item) {
    final S l = S.of(context);
    return Card(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l.uncategorizedBanner,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => _moveToCollection(item),
              child: Text(l.uncategorizedBannerAction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonsInfo(CollectionItem item, Color accentColor) {
    final S l = S.of(context);
    final int? seasons = item.totalSeasons;
    final int? episodes = item.totalEpisodes;
    if (seasons == null && episodes == null) {
      return const SizedBox.shrink();
    }
    final StringBuffer buf = StringBuffer();
    if (seasons != null) {
      buf.write(l.totalSeasons(seasons));
    }
    if (seasons != null && episodes != null) {
      buf.write(' \u2022 ');
    }
    if (episodes != null) {
      buf.write(l.totalEpisodes(episodes));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.video_library_outlined,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            buf.toString(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Not Found ====================

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

  // ==================== Canvas ====================

  ({int? collectionId, int collectionItemId}) get _canvasArg => (
        collectionId: widget.collectionId,
        collectionItemId: widget.itemId,
      );

  /// Возвращает RA секцию если для игры есть tracker data,
  /// или кнопку привязки если RA credentials есть и платформа поддерживается.
  ///
  /// Используем `select` чтобы подписаться только на `hasRaData` —
  /// экран не перестраивается при загрузке/обновлении ачивок.
  /// RA badge в верхнем ряду: лого + % (или кнопка Link).
  Widget? _buildRaBadge(CollectionItem item) {
    if (item.mediaType != MediaType.game) return null;

    final TrackerGameData? raData = ref
        .watch(trackerDetailProvider(item.externalId))
        .valueOrNull
        ?.gameData;

    if (raData != null) {
      // Привязана — показываем лого RA.
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final Uri uri = Uri.parse(raData.raGameUrl);
            launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/ra_logo.png',
              width: 18,
              height: 18,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    }

    // Не привязана — кнопка Link (если доступно).
    final bool hasRaCreds = ref.watch(raApiProvider).hasCredentials;
    if (!hasRaCreds) return null;
    if (item.platformId == null) return null;
    if (RaToIgdbMapper.igdbToRaConsoleIds(item.platformId!).isEmpty) {
      return null;
    }

    return _PulsingRaLink(onTap: () => _linkRa(item));
  }

  Widget? _buildTrackerSection(CollectionItem item) {
    if (item.mediaType != MediaType.game) return null;
    final bool hasData = ref.watch(
      trackerDetailProvider(item.externalId).select(
        (AsyncValue<TrackerDetailState> v) =>
            v.valueOrNull?.hasRaData ?? false,
      ),
    );
    if (hasData) return RaAchievementsSection(gameId: item.externalId);
    return null;
  }


  Widget _buildCanvasView() {
    return Row(
      children: <Widget>[
        Expanded(
          child: CanvasView(
            collectionId: widget.collectionId,
            isEditable: widget.isEditable && !_isViewModeLocked,
            collectionItemId: widget.itemId,
          ),
        ),
        // Боковая панель SteamGridDB
        Consumer(
          builder:
              (BuildContext context, WidgetRef ref, Widget? child) {
            final bool isPanelOpen = ref.watch(
              steamGridDbPanelProvider(widget.collectionId)
                  .select((SteamGridDbPanelState s) => s.isOpen),
            );
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isPanelOpen ? 320 : 0,
              curve: Curves.easeInOut,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                border: isPanelOpen
                    ? const Border(
                        left: BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                      )
                    : null,
              ),
              child: isPanelOpen
                  ? OverflowBox(
                      maxWidth: 320,
                      alignment: Alignment.centerLeft,
                      child: SteamGridDbPanel(
                        collectionId: widget.collectionId,
                        collectionName: _currentItemName ?? '',
                        onAddImage: _addSteamGridDbImage,
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
        // Боковая панель VGMaps Browser (Windows only)
        if (kVgMapsEnabled)
          Consumer(
            builder:
                (BuildContext context, WidgetRef ref, Widget? child) {
              final bool isPanelOpen = ref.watch(
                vgMapsPanelProvider(widget.collectionId)
                    .select((VgMapsPanelState s) => s.isOpen),
              );
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isPanelOpen ? 500 : 0,
                curve: Curves.easeInOut,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  border: isPanelOpen
                      ? const Border(
                          left: BorderSide(
                            color: AppColors.surfaceBorder,
                          ),
                        )
                      : null,
                ),
                child: isPanelOpen
                    ? OverflowBox(
                        maxWidth: 500,
                        alignment: Alignment.centerLeft,
                        child: VgMapsPanel(
                          collectionId: widget.collectionId,
                          onAddImage: _addVgMapsImage,
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
      ],
    );
  }

  void _addSteamGridDbImage(SteamGridDbImage image) {
    const double maxWidth = 300;
    const double defaultSize = 200;
    double targetWidth = defaultSize;
    double targetHeight = defaultSize;

    if (image.width > 0 && image.height > 0) {
      final double aspectRatio = image.width / image.height;
      targetWidth =
          image.width.toDouble() > maxWidth ? maxWidth : image.width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref
        .read(gameCanvasNotifierProvider(_canvasArg).notifier)
        .addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': image.url},
          width: targetWidth,
          height: targetHeight,
        );

    if (mounted) {
      context.showSnack(S.of(context).imageAddedToBoard, type: SnackType.success);
    }
  }

  void _addVgMapsImage(String url, int? width, int? height) {
    const double maxWidth = 400;
    double targetWidth = maxWidth;
    double targetHeight = maxWidth;

    if (width != null && height != null && width > 0 && height > 0) {
      final double aspectRatio = width / height;
      targetWidth =
          width.toDouble() > maxWidth ? maxWidth : width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref
        .read(gameCanvasNotifierProvider(_canvasArg).notifier)
        .addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': url},
          width: targetWidth,
          height: targetHeight,
        );

    if (mounted) {
      context.showSnack(S.of(context).mapAddedToBoard, type: SnackType.success);
    }
  }

  // ==================== Add from Recommendations ====================

  Future<void> _addMovieFromRecommendations(Movie movie) async {
    final Map<int, List<CollectedItemInfo>> collectedMovies =
        await ref.read(collectedMovieIdsProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedAnimations =
        await ref.read(collectedAnimationIdsProvider.future);
    final List<CollectedItemInfo> infos = <CollectedItemInfo>[
      ...collectedMovies[movie.tmdbId] ?? <CollectedItemInfo>[],
      ...collectedAnimations[movie.tmdbId] ?? <CollectedItemInfo>[],
    ];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

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

    await ref.read(databaseServiceProvider).upsertMovie(movie);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.movie,
          externalId: movie.tmdbId,
        );

    if (!mounted) return;

    if (success) {
      context.showSnack(
        l.searchAddedToNamed(movie.title, collectionName),
        type: SnackType.success,
      );
    } else {
      context.showSnack(
        l.searchAlreadyInNamed(movie.title, collectionName),
        type: SnackType.info,
      );
    }
  }

  Future<void> _addTvShowFromRecommendations(TvShow tvShow) async {
    final Map<int, List<CollectedItemInfo>> collectedTvShows =
        await ref.read(collectedTvShowIdsProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedAnimations =
        await ref.read(collectedAnimationIdsProvider.future);
    final List<CollectedItemInfo> infos = <CollectedItemInfo>[
      ...collectedTvShows[tvShow.tmdbId] ?? <CollectedItemInfo>[],
      ...collectedAnimations[tvShow.tmdbId] ?? <CollectedItemInfo>[],
    ];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

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

    await ref.read(databaseServiceProvider).upsertTvShow(tvShow);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.tvShow,
          externalId: tvShow.tmdbId,
        );

    if (!mounted) return;

    if (success) {
      context.showSnack(
        l.searchAddedToNamed(tvShow.title, collectionName),
        type: SnackType.success,
      );
    } else {
      context.showSnack(
        l.searchAlreadyInNamed(tvShow.title, collectionName),
        type: SnackType.info,
      );
    }
  }

  // ==================== Data Operations ====================

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

  Future<void> _updateUserRating(int id, int? rating) async {
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
        .read(trackerDetailProvider(item.externalId).notifier)
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

/// Мерцающее лого RA для непривязанных игр.
class _PulsingRaLink extends StatefulWidget {
  const _PulsingRaLink({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PulsingRaLink> createState() => _PulsingRaLinkState();
}

class _PulsingRaLinkState extends State<_PulsingRaLink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _opacity,
          builder: (BuildContext context, Widget? child) {
            return Opacity(opacity: _opacity.value, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/ra_logo.png',
              width: 18,
              height: 18,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

