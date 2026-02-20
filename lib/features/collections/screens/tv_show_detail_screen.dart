// Экран детального просмотра сериала в коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../../shared/constants/platform_features.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/episode_tracker_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/activity_dates_section.dart';
import '../widgets/canvas_view.dart';
import '../widgets/status_chip_row.dart';
import '../widgets/steamgriddb_panel.dart';
import '../widgets/vgmaps_panel.dart';

/// Экран детального просмотра сериала в коллекции.
///
/// Содержит две вкладки: Details (информация о сериале с прогрессом) и Canvas
/// (персональный холст для заметок, скриншотов и ссылок).
class TvShowDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [TvShowDetailScreen].
  const TvShowDetailScreen({
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
  ConsumerState<TvShowDetailScreen> createState() =>
      _TvShowDetailScreenState();
}

class _TvShowDetailScreenState extends ConsumerState<TvShowDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isViewModeLocked = false;

  bool get _hasCanvas => kCanvasEnabled && widget.collectionId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _hasCanvas ? 2 : 1,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));

    return itemsAsync.when(
      data: (List<CollectionItem> items) {
        final CollectionItem? item = _findItem(items);
        if (item == null) {
          return const BreadcrumbScope(
            label: '...',
            child: Scaffold(
              appBar: AutoBreadcrumbAppBar(),
              body: Center(child: Text('TV Show not found')),
            ),
          );
        }
        return _buildContent(item);
      },
      loading: () => const BreadcrumbScope(
        label: 'Loading...',
        child: Scaffold(
          appBar: AutoBreadcrumbAppBar(),
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object error, StackTrace stack) => BreadcrumbScope(
        label: 'Error',
        child: Scaffold(
          appBar: const AutoBreadcrumbAppBar(),
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Future<void> _moveToCollection(CollectionItem item) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final bool isUncategorized = widget.collectionId == null;

    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: widget.collectionId,
      showUncategorized: !isUncategorized,
      title: 'Move to Collection',
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
        targetName = 'Uncategorized';
    }

    final bool success = await ref
        .read(
          collectionItemsNotifierProvider(widget.collectionId).notifier,
        )
        .moveItem(
          item.id,
          targetCollectionId: targetCollectionId,
          mediaType: item.mediaType,
        );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text('${item.itemName} moved to $targetName')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${item.itemName} already exists in $targetName'),
        ),
      );
    }
  }

  Future<void> _removeFromCollection(CollectionItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove Item?'),
        content: Text('Remove ${item.itemName} from this collection?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.itemName} removed')),
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

  Widget _buildContent(CollectionItem item) {
    final TvShow? tvShow = item.tvShow;
    _currentItemName = item.itemName;

    return BreadcrumbScope(
      label: item.itemName,
      child: Scaffold(
        appBar: AutoBreadcrumbAppBar(
          actions: <Widget>[
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
                const PopupMenuItem<String>(
                  value: 'move',
                  child: ListTile(
                    leading: Icon(Icons.drive_file_move_outlined),
                    title: Text('Move to Collection'),
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
                      'Remove',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          if (widget.isEditable &&
              _hasCanvas &&
              _tabController.index == 1)
            IconButton(
              icon: Icon(
                _isViewModeLocked ? Icons.lock : Icons.lock_open,
              ),
              color: _isViewModeLocked
                  ? AppColors.warning
                  : AppColors.textSecondary,
              tooltip:
                  _isViewModeLocked ? 'Unlock board' : 'Lock board',
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
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Tab>[
            const Tab(
              icon: Icon(Icons.info_outline),
              text: 'Details',
            ),
            if (_hasCanvas)
              const Tab(
                icon: Icon(Icons.dashboard_outlined),
                text: 'Board',
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          // Details tab
          MediaDetailView(
            title: item.itemName,
            coverUrl: tvShow?.posterThumbUrl,
            placeholderIcon: Icons.tv_outlined,
            source: DataSource.tmdb,
            typeIcon: Icons.tv_outlined,
            typeLabel: 'TV Show',
            infoChips: _buildInfoChips(tvShow),
            description: tvShow?.overview,
            cacheImageType: ImageType.tvShowPoster,
            cacheImageId: item.externalId.toString(),
            statusWidget: StatusChipRow(
              status: item.status,
              mediaType: MediaType.tvShow,
              onChanged: (ItemStatus status) =>
                  _updateStatus(item.id, status),
            ),
            extraSections: <Widget>[
              ActivityDatesSection(
                addedAt: item.addedAt,
                startedAt: item.startedAt,
                completedAt: item.completedAt,
                lastActivityAt: item.lastActivityAt,
                isEditable: widget.isEditable,
                onDateChanged: (String type, DateTime date) =>
                    _updateActivityDate(item.id, type, date),
              ),
              _buildSeasonsSection(context, item, tvShow),
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
            accentColor: AppColors.tvShowAccent,
            embedded: true,
          ),
          // Canvas tab (только desktop)
          if (_hasCanvas) _buildCanvasTab(),
        ],
      ),
      ),
    );
  }

  List<MediaDetailChip> _buildInfoChips(TvShow? tvShow) {
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
        text:
            '${tvShow!.totalSeasons} season${tvShow.totalSeasons != 1 ? 's' : ''}',
      ));
    }
    if (tvShow?.totalEpisodes != null) {
      chips.add(MediaDetailChip(
        icon: Icons.playlist_play,
        text: '${tvShow!.totalEpisodes} ep',
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

  Widget _buildSeasonsSection(
    BuildContext context,
    CollectionItem item,
    TvShow? tvShow,
  ) {
    final int tmdbShowId = item.externalId;
    final ({int? collectionId, int showId}) trackerArg =
        (collectionId: widget.collectionId, showId: tmdbShowId);

    final EpisodeTrackerState trackerState =
        ref.watch(episodeTrackerNotifierProvider(trackerArg));

    final int totalEpisodes = tvShow?.totalEpisodes ?? 0;
    final int watchedCount = trackerState.totalWatchedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Заголовок и общий прогресс
        Row(
          children: <Widget>[
            const Icon(Icons.playlist_add_check, size: 20, color: AppColors.brand),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Episode Progress',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              totalEpisodes > 0
                  ? '$watchedCount/$totalEpisodes watched'
                  : '$watchedCount watched',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (totalEpisodes > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: watchedCount / totalEpisodes,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Список сезонов
        _SeasonsListWidget(
          tmdbShowId: tmdbShowId,
          collectionId: widget.collectionId,
        ),
      ],
    );
  }

  ({int? collectionId, int collectionItemId}) get _canvasArg => (
        collectionId: widget.collectionId,
        collectionItemId: widget.itemId,
      );

  Widget _buildCanvasTab() {
    return Row(
      children: <Widget>[
        Expanded(
          child: CanvasView(
            collectionId: widget.collectionId,
            isEditable: widget.isEditable && !_isViewModeLocked,
            collectionItemId: widget.itemId,
          ),
        ),
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

  String? _currentItemName;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image added to board'),
          duration: Duration(seconds: 2),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map added to board'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateStatus(int id, ItemStatus status) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status, MediaType.tvShow);
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

/// Виджет списка сезонов с ExpansionTile.
class _SeasonsListWidget extends ConsumerStatefulWidget {
  const _SeasonsListWidget({
    required this.tmdbShowId,
    required this.collectionId,
  });

  final int tmdbShowId;
  final int? collectionId;

  @override
  ConsumerState<_SeasonsListWidget> createState() => _SeasonsListWidgetState();
}

class _SeasonsListWidgetState extends ConsumerState<_SeasonsListWidget> {
  List<TvSeason> _seasons = <TvSeason>[];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    List<TvSeason> seasons =
        await db.getTvSeasonsByShowId(widget.tmdbShowId);

    // Если в кэше пусто — загружаем из TMDB API и кэшируем
    if (seasons.isEmpty) {
      try {
        final TmdbApi tmdbApi = ref.read(tmdbApiProvider);
        seasons = await tmdbApi.getTvSeasons(widget.tmdbShowId);
        if (seasons.isNotEmpty) {
          await db.upsertTvSeasons(seasons);
        }
      } on Exception catch (_) {
        // Если API недоступен — покажем пустой список
      }
    }

    if (mounted) {
      setState(() {
        _seasons = seasons;
        _loading = false;
      });
    }
  }

  /// Принудительно обновляет список сезонов и загруженные эпизоды из API.
  /// Добавляет новые сезоны/эпизоды, обновляет метаданные,
  /// не трогает watched-статусы.
  Future<void> _refreshSeasons() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      final DatabaseService db = ref.read(databaseServiceProvider);
      final TmdbApi tmdbApi = ref.read(tmdbApiProvider);

      // Обновляем список сезонов
      final List<TvSeason> seasons =
          await tmdbApi.getTvSeasons(widget.tmdbShowId);
      if (seasons.isNotEmpty) {
        await db.upsertTvSeasons(seasons);
      }

      // Обновляем эпизоды для каждого уже раскрытого сезона
      final EpisodeTrackerNotifier tracker = ref.read(
        episodeTrackerNotifierProvider(_trackerArg).notifier,
      );
      final EpisodeTrackerState trackerState = ref.read(
        episodeTrackerNotifierProvider(_trackerArg),
      );
      for (final int seasonNum in trackerState.episodesBySeason.keys) {
        await tracker.refreshSeason(seasonNum);
      }

      if (mounted) {
        setState(() {
          _seasons = seasons;
          _refreshing = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  ({int? collectionId, int showId}) get _trackerArg => (
        collectionId: widget.collectionId,
        showId: widget.tmdbShowId,
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_seasons.isEmpty) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'No season data available',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh from TMDB',
            onPressed: _refreshing ? null : _refreshSeasons,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    final EpisodeTrackerState trackerState =
        ref.watch(episodeTrackerNotifierProvider(_trackerArg));

    return Column(
      children: <Widget>[
        // Кнопка обновления данных из TMDB
        Align(
          alignment: Alignment.centerRight,
          child: _refreshing
              ? const Padding(
                  padding: EdgeInsets.all(4),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh from TMDB',
                  onPressed: _refreshSeasons,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  visualDensity: VisualDensity.compact,
                ),
        ),
        for (final TvSeason season in _seasons)
          if (season.seasonNumber > 0) // Пропускаем Specials (сезон 0)
            _SeasonExpansionTile(
              season: season,
              trackerState: trackerState,
              trackerArg: _trackerArg,
            ),
      ],
    );
  }
}

/// ExpansionTile для одного сезона с эпизодами.
class _SeasonExpansionTile extends ConsumerWidget {
  const _SeasonExpansionTile({
    required this.season,
    required this.trackerState,
    required this.trackerArg,
  });

  final TvSeason season;
  final EpisodeTrackerState trackerState;
  final ({int? collectionId, int showId}) trackerArg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int seasonNum = season.seasonNumber;
    final int episodeCount = season.episodeCount ?? 0;
    final int watchedCount = trackerState.watchedCountForSeason(seasonNum);
    final bool allWatched = episodeCount > 0 && watchedCount >= episodeCount;
    final bool isLoading = trackerState.loadingSeasons[seasonNum] == true;
    final List<TvEpisode>? episodes =
        trackerState.episodesBySeason[seasonNum];

    final String seasonTitle =
        season.name ?? 'Season $seasonNum';
    final String subtitle = episodeCount > 0
        ? '$watchedCount/$episodeCount episodes'
        : '$watchedCount watched';

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      leading: Icon(
        allWatched ? Icons.check_circle : Icons.circle_outlined,
        color: allWatched ? AppColors.brand : AppColors.surfaceBorder,
        size: 20,
      ),
      title: Text(
        seasonTitle,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Кнопка Mark all / Unmark all
          IconButton(
            icon: Icon(
              allWatched
                  ? Icons.remove_done
                  : Icons.done_all,
              size: 18,
            ),
            tooltip: allWatched ? 'Unmark all' : 'Mark all watched',
            onPressed: () {
              // Если эпизоды ещё не загружены, сначала загрузим
              if (episodes == null || episodes.isEmpty) {
                ref
                    .read(episodeTrackerNotifierProvider(trackerArg).notifier)
                    .loadSeason(seasonNum)
                    .then((_) {
                  ref
                      .read(
                          episodeTrackerNotifierProvider(trackerArg).notifier)
                      .toggleSeason(seasonNum);
                });
              } else {
                ref
                    .read(episodeTrackerNotifierProvider(trackerArg).notifier)
                    .toggleSeason(seasonNum);
              }
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
          ),
          const Icon(Icons.expand_more, size: 20),
        ],
      ),
      onExpansionChanged: (bool expanded) {
        if (expanded) {
          ref
              .read(episodeTrackerNotifierProvider(trackerArg).notifier)
              .loadSeason(seasonNum);
        }
      },
      children: <Widget>[
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (episodes != null && episodes.isNotEmpty)
          ...episodes.map((TvEpisode episode) => _EpisodeTile(
                episode: episode,
                isWatched: trackerState.isEpisodeWatched(
                  seasonNum,
                  episode.episodeNumber,
                ),
                watchedAt: trackerState.getWatchedAt(
                  seasonNum,
                  episode.episodeNumber,
                ),
                trackerArg: trackerArg,
              ))
        else if (episodes != null && episodes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'No episodes found',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Тайл одного эпизода с чекбоксом.
class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({
    required this.episode,
    required this.isWatched,
    required this.trackerArg,
    this.watchedAt,
  });

  final TvEpisode episode;
  final bool isWatched;
  final DateTime? watchedAt;
  final ({int? collectionId, int showId}) trackerArg;

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title =
        'E${episode.episodeNumber}: ${episode.name}';
    final List<String> subtitleParts = <String>[];
    if (episode.airDate != null) {
      subtitleParts.add(episode.airDate!);
    }
    if (episode.runtime != null) {
      subtitleParts.add('${episode.runtime} min');
    }
    if (isWatched && watchedAt != null) {
      subtitleParts.add(
        'watched ${_months[watchedAt!.month - 1]} ${watchedAt!.day}',
      );
    }

    return CheckboxListTile(
      value: isWatched,
      onChanged: (_) {
        ref
            .read(episodeTrackerNotifierProvider(trackerArg).notifier)
            .toggleEpisode(
              episode.seasonNumber,
              episode.episodeNumber,
            );
      },
      title: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          decoration: isWatched ? TextDecoration.lineThrough : null,
          color: isWatched
              ? AppColors.textSecondary
              : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitleParts.isNotEmpty
          ? Text(
              subtitleParts.join(' \u2022 '),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      visualDensity: VisualDensity.compact,
    );
  }
}
