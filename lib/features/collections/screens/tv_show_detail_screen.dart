// Экран детального просмотра сериала в коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../providers/collections_provider.dart';
import '../widgets/item_status_dropdown.dart';

/// Экран детального просмотра сериала в коллекции.
///
/// Позволяет просматривать полную информацию о сериале,
/// отслеживать прогресс (сезон/эпизод), изменять статус
/// и редактировать комментарии.
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

class _TvShowDetailScreenState extends ConsumerState<TvShowDetailScreen> {
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

    return MediaDetailView(
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
        onChanged: (ItemStatus status) => _updateStatus(item.id, status),
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
