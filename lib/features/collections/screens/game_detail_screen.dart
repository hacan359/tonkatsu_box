import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../../../shared/constants/platform_features.dart';
import '../widgets/canvas_view.dart';
import '../widgets/steamgriddb_panel.dart';
import '../widgets/activity_dates_section.dart';
import '../widgets/status_chip_row.dart';
import '../widgets/vgmaps_panel.dart';

/// Экран детального просмотра игры в коллекции.
///
/// Содержит две вкладки: Details (информация об игре) и Canvas (персональный
/// холст для заметок, скриншотов и ссылок).
class GameDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [GameDetailScreen].
  const GameDetailScreen({
    required this.collectionId,
    required this.itemId,
    required this.isEditable,
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  /// ID записи элемента в коллекции.
  final int itemId;

  /// Можно ли редактировать комментарий автора.
  final bool isEditable;

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isViewModeLocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kCanvasEnabled ? 2 : 1,
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
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
            ),
            body: const Center(child: Text('Game not found')),
          );
        }
        return _buildContent(item);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  CollectionItem? _findItem(List<CollectionItem> items) {
    for (final CollectionItem item in items) {
      if (item.id == widget.itemId) {
        return item;
      }
    }
    return null;
  }

  Widget _buildContent(CollectionItem collectionItem) {
    final Game? game = collectionItem.game;
    _currentItemName = collectionItem.itemName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(collectionItem.itemName),
        actions: <Widget>[
          if (widget.isEditable &&
              kCanvasEnabled &&
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
            if (kCanvasEnabled)
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
            title: collectionItem.itemName,
            coverUrl: game?.coverUrl,
            placeholderIcon: Icons.videogame_asset,
            source: DataSource.igdb,
            typeIcon: Icons.sports_esports,
            typeLabel: collectionItem.platformName,
            infoChips: _buildInfoChips(game),
            description: game?.summary,
            cacheImageType: ImageType.gameCover,
            cacheImageId: widget.itemId.toString(),
            statusWidget: StatusChipRow(
              status: collectionItem.status,
              mediaType: MediaType.game,
              onChanged: (ItemStatus status) =>
                  _updateStatus(collectionItem.id, status),
            ),
            extraSections: <Widget>[
              ActivityDatesSection(
                addedAt: collectionItem.addedAt,
                startedAt: collectionItem.startedAt,
                completedAt: collectionItem.completedAt,
                lastActivityAt: collectionItem.lastActivityAt,
                isEditable: widget.isEditable,
                onDateChanged: (String type, DateTime date) =>
                    _updateActivityDate(collectionItem.id, type, date),
              ),
            ],
            authorComment: collectionItem.authorComment,
            userComment: collectionItem.userComment,
            hasAuthorComment: collectionItem.hasAuthorComment,
            hasUserComment: collectionItem.hasUserComment,
            isEditable: widget.isEditable,
            onAuthorCommentSave: (String? text) =>
                _saveAuthorComment(collectionItem.id, text),
            onUserCommentSave: (String? text) =>
                _saveUserComment(collectionItem.id, text),
            embedded: true,
          ),
          // Canvas tab (только desktop)
          if (kCanvasEnabled) _buildCanvasTab(),
        ],
      ),
    );
  }

  List<MediaDetailChip> _buildInfoChips(Game? game) {
    final List<MediaDetailChip> chips = <MediaDetailChip>[];
    if (game?.releaseYear != null) {
      chips.add(MediaDetailChip(
        icon: Icons.calendar_today_outlined,
        text: game!.releaseYear.toString(),
      ));
    }
    if (game?.formattedRating != null) {
      chips.add(MediaDetailChip(
        icon: Icons.star_outline,
        text: '${game!.formattedRating}/10',
      ));
    }
    if (game?.genres != null && game!.genres!.isNotEmpty) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: game.genresString!,
      ));
    }
    return chips;
  }

  ({int collectionId, int collectionItemId}) get _canvasArg => (
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
        // Боковая панель VGMaps Browser
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

  /// Имя текущего элемента (для поиска в SteamGridDB).
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
        .updateStatus(id, status, MediaType.game);
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
}
