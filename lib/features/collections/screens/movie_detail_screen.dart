// Экран детального просмотра фильма в коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
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
    final Movie? movie = item.movie;

    return MediaDetailView(
      title: item.itemName,
      coverUrl: movie?.posterThumbUrl,
      placeholderIcon: Icons.movie_outlined,
      source: DataSource.tmdb,
      typeIcon: Icons.movie_outlined,
      typeLabel: 'Movie',
      infoChips: _buildInfoChips(movie),
      description: movie?.overview,
      statusWidget: ItemStatusDropdown(
        status: item.status,
        mediaType: MediaType.movie,
        onChanged: (ItemStatus status) => _updateStatus(item.id, status),
      ),
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

  List<MediaDetailChip> _buildInfoChips(Movie? movie) {
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
        icon: Icons.star_outline,
        text: '${movie!.formattedRating}/10',
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

  Future<void> _updateStatus(int id, ItemStatus status) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status, MediaType.movie);
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
