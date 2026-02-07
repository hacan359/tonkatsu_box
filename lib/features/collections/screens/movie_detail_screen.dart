// Экран детального просмотра фильма в коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../providers/collections_provider.dart';
import '../widgets/item_status_dropdown.dart';

/// Экран детального просмотра фильма в коллекции.
///
/// Позволяет просматривать полную информацию о фильме,
/// изменять статус и редактировать комментарии.
class MovieDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [MovieDetailScreen].
  const MovieDetailScreen({
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
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
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
            body: const Center(child: Text('Movie not found')),
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
    final Movie? movie = item.movie;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.itemName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildHeader(context, item, movie),
          const SizedBox(height: 16),
          _buildStatusSection(context, item),
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
    Movie? movie,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String? posterUrl = movie?.posterThumbUrl;

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
                    Icons.movie_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Movie',
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
                  if (movie?.releaseYear != null)
                    _buildInfoChip(
                      Icons.calendar_today_outlined,
                      movie!.releaseYear.toString(),
                      colorScheme,
                    ),
                  if (movie?.runtime != null)
                    _buildInfoChip(
                      Icons.schedule_outlined,
                      _formatRuntime(movie!.runtime!),
                      colorScheme,
                    ),
                  if (movie?.formattedRating != null)
                    _buildInfoChip(
                      Icons.star_outline,
                      '${movie!.formattedRating}/10',
                      colorScheme,
                    ),
                  if (movie?.genresString != null)
                    _buildInfoChip(
                      Icons.category_outlined,
                      movie!.genresString!,
                      colorScheme,
                    ),
                ],
              ),
              if (movie?.overview != null &&
                  movie!.overview!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  movie.overview!,
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
        Icons.movie_outlined,
        size: 32,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  String _formatRuntime(int minutes) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}m';
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
          mediaType: MediaType.movie,
          onChanged: (ItemStatus status) =>
              _updateStatus(item.id, status),
        ),
      ],
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
        .updateStatus(id, status, MediaType.movie);
  }

  Future<void> _editAuthorComment(CollectionItem item) async {
    final String? result = await _showCommentDialog(
      title: "Edit Author's Comment",
      hint: 'Write a comment about this movie...',
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
