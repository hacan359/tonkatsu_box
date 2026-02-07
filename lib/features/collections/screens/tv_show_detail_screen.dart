// Экран детального просмотра сериала в коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_show.dart';
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
        return _buildContent(context, item);
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

  Widget _buildContent(BuildContext context, CollectionItem item) {
    final TvShow? tvShow = item.tvShow;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.itemName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildHeader(context, item, tvShow),
          const SizedBox(height: 16),
          _buildStatusSection(context, item),
          const SizedBox(height: 16),
          _buildProgressSection(context, item, tvShow),
          const SizedBox(height: 16),
          _buildAuthorCommentSection(context, item),
          const SizedBox(height: 16),
          _buildUserNotesSection(context, item),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CollectionItem item,
    TvShow? tvShow,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String? posterUrl = tvShow?.posterThumbUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Постер
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 80,
            height: 120,
            child: posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    memCacheHeight: 180,
                    placeholder: (BuildContext ctx, String url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget:
                        (BuildContext ctx, String url, Object error) =>
                            _buildPlaceholder(colorScheme),
                  )
                : _buildPlaceholder(colorScheme),
          ),
        ),
        const SizedBox(width: 12),
        // Инфо
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.tv_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TV Show',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  if (tvShow?.firstAirYear != null)
                    _buildInfoChip(
                      Icons.calendar_today_outlined,
                      tvShow!.firstAirYear.toString(),
                      colorScheme,
                    ),
                  if (tvShow?.totalSeasons != null)
                    _buildInfoChip(
                      Icons.video_library_outlined,
                      '${tvShow!.totalSeasons} season${tvShow.totalSeasons != 1 ? 's' : ''}',
                      colorScheme,
                    ),
                  if (tvShow?.totalEpisodes != null)
                    _buildInfoChip(
                      Icons.playlist_play,
                      '${tvShow!.totalEpisodes} ep',
                      colorScheme,
                    ),
                  if (tvShow?.formattedRating != null)
                    _buildInfoChip(
                      Icons.star_outline,
                      '${tvShow!.formattedRating}/10',
                      colorScheme,
                    ),
                  if (tvShow?.status != null)
                    _buildInfoChip(
                      Icons.info_outline,
                      tvShow!.status!,
                      colorScheme,
                    ),
                  if (tvShow?.genresString != null)
                    _buildInfoChip(
                      Icons.category_outlined,
                      tvShow!.genresString!,
                      colorScheme,
                    ),
                ],
              ),
              if (tvShow?.overview != null &&
                  tvShow!.overview!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  tvShow.overview!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.tv_outlined,
        size: 32,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, CollectionItem item) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ItemStatusDropdown(
          status: item.status,
          mediaType: MediaType.tvShow,
          onChanged: (ItemStatus status) =>
              _updateStatus(item.id, status),
        ),
      ],
    );
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

  Widget _buildAuthorCommentSection(
    BuildContext context,
    CollectionItem item,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.format_quote,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Author's Comment",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.isEditable)
              TextButton.icon(
                onPressed: () => _editAuthorComment(item),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.tertiaryContainer,
            ),
          ),
          child: item.hasAuthorComment
              ? Text(
                  item.authorComment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                )
              : Text(
                  widget.isEditable
                      ? 'No comment yet. Tap Edit to add one.'
                      : 'No comment from the author.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserNotesSection(BuildContext context, CollectionItem item) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.note_alt_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'My Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _editUserNotes(item),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.primaryContainer,
            ),
          ),
          child: item.hasUserComment
              ? Text(
                  item.userComment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                )
              : Text(
                  'No notes yet. Tap Edit to add your personal notes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
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

  Future<void> _editAuthorComment(CollectionItem item) async {
    final String? result = await _showCommentDialog(
      title: "Edit Author's Comment",
      hint: 'Write a comment about this TV show...',
      initialValue: item.authorComment,
    );

    if (result == null) return;

    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateAuthorComment(item.id, result.isEmpty ? null : result);
  }

  Future<void> _editUserNotes(CollectionItem item) async {
    final String? result = await _showCommentDialog(
      title: 'Edit My Notes',
      hint: 'Write your personal notes...',
      initialValue: item.userComment,
    );

    if (result == null) return;

    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateUserComment(item.id, result.isEmpty ? null : result);
  }

  Future<String?> _showCommentDialog({
    required String title,
    required String hint,
    String? initialValue,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
