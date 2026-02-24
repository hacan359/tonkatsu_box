// Единый экран детального просмотра элемента коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../../shared/constants/platform_features.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/canvas_view.dart';
import '../widgets/episode_tracker_section.dart';
import '../widgets/status_chip_row.dart';
import '../widgets/steamgriddb_panel.dart';
import '../widgets/vgmaps_panel.dart';

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
    this.tvShow,
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
  final TvShow? tvShow;
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

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _showCanvas = false;
  bool _isViewModeLocked = false;
  String? _currentItemName;

  bool get _hasCanvas => kCanvasEnabled && widget.collectionId != null;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync = ref.watch(
      collectionItemsNotifierProvider(widget.collectionId),
    );

    return itemsAsync.when(
      data: (List<CollectionItem> items) {
        final CollectionItem? item = _findItem(items);
        if (item == null) {
          return BreadcrumbScope(
            label: '...',
            child: Scaffold(
              appBar: const AutoBreadcrumbAppBar(),
              body: Center(child: Text(_notFoundMessage(context, null))),
            ),
          );
        }
        return _buildContent(item);
      },
      loading: () => const BreadcrumbScope(
        label: '...',
        child: Scaffold(
          appBar: AutoBreadcrumbAppBar(),
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object error, StackTrace stack) => BreadcrumbScope(
        label: '...',
        child: Scaffold(
          appBar: const AutoBreadcrumbAppBar(),
          body: Center(
            child: Text(S.of(context).errorPrefix(error.toString())),
          ),
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

  CollectionItem? _findItem(List<CollectionItem> items) {
    for (final CollectionItem item in items) {
      if (item.id == widget.itemId) {
        return item;
      }
    }
    return null;
  }

  // ==================== Content ====================

  Widget _buildContent(CollectionItem item) {
    _currentItemName = item.itemName;
    final _MediaConfig config = _getMediaConfig(item);

    return BreadcrumbScope(
      label: item.itemName,
      child: Scaffold(
        appBar: AutoBreadcrumbAppBar(
          actions: <Widget>[
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
                tooltip: S.of(context).boardTab,
                onPressed: () {
                  setState(() {
                    _showCanvas = !_showCanvas;
                  });
                },
              ),
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
                    ? S.of(context).collectionUnlockBoard
                    : S.of(context).collectionLockBoard,
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
    return MediaDetailView(
      title: item.itemName,
      coverUrl: config.coverUrl,
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
      onActivityDateChanged: widget.isEditable
          ? (String type, DateTime date) =>
              _updateActivityDate(item.id, type, date)
          : null,
      extraSections: <Widget>[
        if (config.hasEpisodeTracker)
          EpisodeTrackerSection(
            collectionId: widget.collectionId,
            externalId: item.externalId,
            tvShow: config.tvShow,
            accentColor: config.accentColor,
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
      embedded: true,
    );
  }

  // ==================== Media Config ====================

  _MediaConfig _getMediaConfig(CollectionItem item) {
    return switch (item.mediaType) {
      MediaType.game => _getGameConfig(item),
      MediaType.movie => _getMovieConfig(item),
      MediaType.tvShow => _getTvShowConfig(item),
      MediaType.animation => _getAnimationConfig(item),
    };
  }

  _MediaConfig _getGameConfig(CollectionItem item) {
    final Game? game = item.game;
    return _MediaConfig(
      coverUrl: game?.coverUrl,
      placeholderIcon: Icons.videogame_asset,
      source: DataSource.igdb,
      typeIcon: Icons.sports_esports,
      typeLabel: item.platformName,
      cacheImageType: ImageType.gameCover,
      cacheImageId: widget.itemId.toString(),
      accentColor: AppColors.brand,
      infoChips: _buildGameChips(game),
      description: game?.summary,
      hasEpisodeTracker: false,
    );
  }

  _MediaConfig _getMovieConfig(CollectionItem item) {
    final Movie? movie = item.movie;
    return _MediaConfig(
      coverUrl: movie?.posterThumbUrl,
      placeholderIcon: Icons.movie_outlined,
      source: DataSource.tmdb,
      typeIcon: Icons.movie_outlined,
      typeLabel: S.of(context).mediaTypeMovie,
      cacheImageType: ImageType.moviePoster,
      cacheImageId: item.externalId.toString(),
      accentColor: AppColors.movieAccent,
      infoChips: _buildMovieChips(movie),
      description: movie?.overview,
      hasEpisodeTracker: false,
    );
  }

  _MediaConfig _getTvShowConfig(CollectionItem item) {
    final TvShow? tvShow = item.tvShow;
    return _MediaConfig(
      coverUrl: tvShow?.posterThumbUrl,
      placeholderIcon: Icons.tv_outlined,
      source: DataSource.tmdb,
      typeIcon: Icons.tv_outlined,
      typeLabel: S.of(context).mediaTypeTvShow,
      cacheImageType: ImageType.tvShowPoster,
      cacheImageId: item.externalId.toString(),
      accentColor: AppColors.tvShowAccent,
      infoChips: _buildTvShowChips(tvShow),
      description: tvShow?.overview,
      hasEpisodeTracker: true,
      tvShow: tvShow,
    );
  }

  _MediaConfig _getAnimationConfig(CollectionItem item) {
    final bool isTvShow = item.platformId == AnimationSource.tvShow;
    if (isTvShow) {
      final TvShow? tvShow = item.tvShow;
      return _MediaConfig(
        coverUrl: tvShow?.posterThumbUrl,
        placeholderIcon: Icons.animation,
        source: DataSource.tmdb,
        typeIcon: Icons.animation,
        typeLabel: S.of(context).animatedSeries,
        cacheImageType: ImageType.tvShowPoster,
        cacheImageId: item.externalId.toString(),
        accentColor: AppColors.animationAccent,
        infoChips: _buildTvShowChips(tvShow),
        description: tvShow?.overview,
        hasEpisodeTracker: true,
        tvShow: tvShow,
      );
    } else {
      final Movie? movie = item.movie;
      return _MediaConfig(
        coverUrl: movie?.posterThumbUrl,
        placeholderIcon: Icons.animation,
        source: DataSource.tmdb,
        typeIcon: Icons.animation,
        typeLabel: S.of(context).animatedMovie,
        cacheImageType: ImageType.moviePoster,
        cacheImageId: item.externalId.toString(),
        accentColor: AppColors.animationAccent,
        infoChips: _buildMovieChips(movie),
        description: movie?.overview,
        hasEpisodeTracker: false,
      );
    }
  }

  // ==================== Info Chips ====================

  List<MediaDetailChip> _buildGameChips(Game? game) {
    final List<MediaDetailChip> chips = <MediaDetailChip>[];
    if (game?.releaseYear != null) {
      chips.add(
        MediaDetailChip(
          icon: Icons.calendar_today_outlined,
          text: game!.releaseYear.toString(),
        ),
      );
    }
    if (game?.formattedRating != null) {
      chips.add(
        MediaDetailChip(
          icon: Icons.star,
          text: '${game!.formattedRating}/10',
          iconColor: AppColors.ratingStar,
        ),
      );
    }
    if (game?.genres != null && game!.genres!.isNotEmpty) {
      chips.add(
        MediaDetailChip(
          icon: Icons.category_outlined,
          text: game.genresString!,
        ),
      );
    }
    return chips;
  }

  List<MediaDetailChip> _buildMovieChips(Movie? movie) {
    final List<MediaDetailChip> chips = <MediaDetailChip>[];
    if (movie?.releaseYear != null) {
      chips.add(MediaDetailChip(
        icon: Icons.calendar_today_outlined,
        text: movie!.releaseYear.toString(),
      ));
    }
    if (movie?.runtime != null) {
      chips.add(MediaDetailChip(
        icon: Icons.schedule_outlined,
        text: _formatRuntime(movie!.runtime!),
      ));
    }
    if (movie?.formattedRating != null) {
      chips.add(MediaDetailChip(
        icon: Icons.star,
        text: '${movie!.formattedRating}/10',
        iconColor: AppColors.ratingStar,
      ));
    }
    if (movie?.genresString != null) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: movie!.genresString!,
      ));
    }
    return chips;
  }

  List<MediaDetailChip> _buildTvShowChips(TvShow? tvShow) {
    final S l = S.of(context);
    final List<MediaDetailChip> chips = <MediaDetailChip>[];
    if (tvShow?.firstAirYear != null) {
      chips.add(MediaDetailChip(
        icon: Icons.calendar_today_outlined,
        text: tvShow!.firstAirYear.toString(),
      ));
    }
    if (tvShow?.totalSeasons != null) {
      chips.add(MediaDetailChip(
        icon: Icons.video_library_outlined,
        text: l.totalSeasons(tvShow!.totalSeasons!),
      ));
    }
    if (tvShow?.totalEpisodes != null) {
      chips.add(MediaDetailChip(
        icon: Icons.playlist_play,
        text: l.totalEpisodes(tvShow!.totalEpisodes!),
      ));
    }
    if (tvShow?.formattedRating != null) {
      chips.add(MediaDetailChip(
        icon: Icons.star,
        text: '${tvShow!.formattedRating}/10',
        iconColor: AppColors.ratingStar,
      ));
    }
    if (tvShow?.status != null) {
      chips.add(MediaDetailChip(
        icon: Icons.info_outline,
        text: tvShow!.status!,
      ));
    }
    if (tvShow?.genresString != null) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: tvShow!.genresString!,
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

  // ==================== Not Found ====================

  String _notFoundMessage(BuildContext context, MediaType? mediaType) {
    final S l = S.of(context);
    return switch (mediaType) {
      MediaType.game => l.gameNotFound,
      MediaType.movie => l.movieNotFound,
      MediaType.tvShow => l.tvShowNotFound,
      MediaType.animation => l.animationNotFound,
      null => l.gameNotFound,
    };
  }

  // ==================== Canvas ====================

  ({int? collectionId, int collectionItemId}) get _canvasArg => (
        collectionId: widget.collectionId,
        collectionItemId: widget.itemId,
      );

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
}
