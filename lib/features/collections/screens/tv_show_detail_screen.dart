// Экран детального просмотра сериала в коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/canvas_view.dart';
import '../widgets/item_status_dropdown.dart';
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

  /// ID коллекции.
  final int collectionId;

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
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));

    return itemsAsync.when(
      data: (List<CollectionItem> items) {
        final CollectionItem? item = _findItem(items);
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('TV Show not found')),
          );
        }
        return _buildContent(item);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(item.itemName),
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
            title: item.itemName,
            coverUrl: tvShow?.posterThumbUrl,
            placeholderIcon: Icons.tv_outlined,
            source: DataSource.tmdb,
            typeIcon: Icons.tv_outlined,
            typeLabel: 'TV Show',
            infoChips: _buildInfoChips(tvShow),
            description: tvShow?.overview,
            statusWidget: ItemStatusDropdown(
              status: item.status,
              mediaType: MediaType.tvShow,
              onChanged: (ItemStatus status) =>
                  _updateStatus(item.id, status),
            ),
            extraSections: <Widget>[
              _buildProgressSection(context, item, tvShow),
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
            embedded: true,
          ),
          // Вкладка Canvas с боковыми панелями
          _buildCanvasTab(),
        ],
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
        icon: Icons.star_outline,
        text: '${tvShow!.formattedRating}/10',
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

  Widget _buildProgressSection(
    BuildContext context,
    CollectionItem item,
    TvShow? tvShow,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final int totalSeasons = tvShow?.totalSeasons ?? 0;
    final int totalEpisodes = tvShow?.totalEpisodes ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Progress',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildProgressField(
                context,
                label: 'Season',
                value: item.currentSeason,
                total: totalSeasons,
                onChanged: (int value) => _updateProgress(
                  item.id,
                  currentSeason: value,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressField(
                context,
                label: 'Episode',
                value: item.currentEpisode,
                total: totalEpisodes,
                onChanged: (int value) => _updateProgress(
                  item.id,
                  currentEpisode: value,
                ),
              ),
            ),
          ],
        ),
        if (totalSeasons > 0 || totalEpisodes > 0) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            _buildProgressText(item, totalSeasons, totalEpisodes),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _buildProgressText(
    CollectionItem item,
    int totalSeasons,
    int totalEpisodes,
  ) {
    final List<String> parts = <String>[];
    if (totalSeasons > 0) {
      parts.add('S${item.currentSeason}/$totalSeasons');
    }
    if (totalEpisodes > 0) {
      parts.add('E${item.currentEpisode}/$totalEpisodes');
    }
    return parts.join(' \u2022 ');
  }

  Widget _buildProgressField(
    BuildContext context, {
    required String label,
    required int value,
    required int total,
    required void Function(int) onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: value > 0
                    ? () => onChanged(value - 1)
                    : null,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (total > 0)
                Text(
                  '/$total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => onChanged(value + 1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
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
            isEditable: widget.isEditable,
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

  Future<void> _updateStatus(int id, ItemStatus status) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status, MediaType.tvShow);
  }

  Future<void> _updateProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateProgress(
          id,
          currentSeason: currentSeason,
          currentEpisode: currentEpisode,
        );
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
