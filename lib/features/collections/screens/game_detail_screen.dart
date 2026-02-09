import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/collection_game.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/canvas_view.dart';
import '../widgets/steamgriddb_panel.dart';
import '../widgets/status_dropdown.dart';
import '../widgets/vgmaps_panel.dart';

/// Экран детального просмотра игры в коллекции.
///
/// Содержит две вкладки: Details (информация об игре) и Canvas (персональный
/// холст для заметок, скриншотов и ссылок).
class GameDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [GameDetailScreen].
  const GameDetailScreen({
    required this.collectionId,
    required this.gameId,
    required this.isEditable,
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  /// ID записи игры в коллекции.
  final int gameId;

  /// Можно ли редактировать комментарий автора.
  final bool isEditable;

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionGame>> gamesAsync =
        ref.watch(collectionGamesNotifierProvider(widget.collectionId));

    return gamesAsync.when(
      data: (List<CollectionGame> games) {
        final CollectionGame? collectionGame = _findGame(games);
        if (collectionGame == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Game not found')),
          );
        }
        return _buildContent(collectionGame);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  CollectionGame? _findGame(List<CollectionGame> games) {
    for (final CollectionGame game in games) {
      if (game.id == widget.gameId) {
        return game;
      }
    }
    return null;
  }

  Widget _buildContent(CollectionGame collectionGame) {
    final Game? game = collectionGame.game;
    _currentItemName = collectionGame.gameName;

    return Scaffold(
      appBar: AppBar(
        title: Text(collectionGame.gameName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Details',
            ),
            Tab(
              icon: Icon(Icons.dashboard_outlined),
              text: 'Canvas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          // Вкладка Details
          MediaDetailView(
            title: collectionGame.gameName,
            coverUrl: game?.coverUrl,
            placeholderIcon: Icons.videogame_asset,
            source: DataSource.igdb,
            typeIcon: Icons.sports_esports,
            typeLabel: collectionGame.platformName,
            infoChips: _buildInfoChips(game),
            description: game?.summary,
            cacheImageType: ImageType.gameCover,
            cacheImageId: widget.gameId.toString(),
            statusWidget: StatusDropdown(
              status: collectionGame.status,
              onChanged: (GameStatus status) =>
                  _updateStatus(collectionGame.id, status),
            ),
            authorComment: collectionGame.authorComment,
            userComment: collectionGame.userComment,
            hasAuthorComment: collectionGame.hasAuthorComment,
            hasUserComment: collectionGame.hasUserComment,
            isEditable: widget.isEditable,
            onAuthorCommentSave: (String? text) =>
                _saveAuthorComment(collectionGame.id, text),
            onUserCommentSave: (String? text) =>
                _saveUserComment(collectionGame.id, text),
            embedded: true,
          ),
          // Вкладка Canvas с боковыми панелями
          _buildCanvasTab(),
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
        collectionItemId: widget.gameId,
      );

  Widget _buildCanvasTab() {
    return Row(
      children: <Widget>[
        Expanded(
          child: CanvasView(
            collectionId: widget.collectionId,
            isEditable: widget.isEditable,
            collectionItemId: widget.gameId,
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
                    ? Border(
                        left: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
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
                    ? Border(
                        left: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
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
          content: Text('Image added to canvas'),
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
          content: Text('Map added to canvas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateStatus(int id, GameStatus status) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status);
  }

  Future<void> _saveAuthorComment(int id, String? text) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateAuthorComment(id, text);
  }

  Future<void> _saveUserComment(int id, String? text) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateUserComment(id, text);
  }
}
