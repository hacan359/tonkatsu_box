// Debug-экран для проверки URL изображений в коллекциях.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../collections/providers/collections_provider.dart';

/// Debug-экран для проверки URL изображений.
///
/// Показывает все элементы коллекций с URL постеров,
/// статусом загрузки и превью изображений.
class ImageDebugScreen extends ConsumerStatefulWidget {
  /// Создаёт [ImageDebugScreen].
  const ImageDebugScreen({super.key});

  @override
  ConsumerState<ImageDebugScreen> createState() => _ImageDebugScreenState();
}

class _ImageDebugScreenState extends ConsumerState<ImageDebugScreen> {
  List<Collection> _collections = <Collection>[];
  int? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.read(collectionsProvider);
    final List<Collection>? collections = collectionsAsync.valueOrNull;
    if (collections != null && mounted) {
      setState(() {
        _collections = collections;
        if (collections.isNotEmpty) {
          _selectedCollectionId = collections.first.id;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return BreadcrumbScope(
      label: 'IGDB Media',
      child: Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: Column(
        children: <Widget>[
          // Выбор коллекции
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Text('Collection: ', style: theme.textTheme.titleSmall),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedCollectionId,
                    isExpanded: true,
                    items: _collections
                        .map((Collection c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (int? id) {
                      setState(() => _selectedCollectionId = id);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Список элементов
          Expanded(
            child: _selectedCollectionId != null
                ? _buildItemsList(colorScheme)
                : const Center(child: Text('No collections')),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildItemsList(ColorScheme colorScheme) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(_selectedCollectionId));

    return itemsAsync.when(
      data: (List<CollectionItem> items) {
        if (items.isEmpty) {
          return const Center(child: Text('No items in collection'));
        }

        // Фильтруем только фильмы и сериалы (TMDB)
        final List<CollectionItem> tmdbItems = items
            .where((CollectionItem item) =>
                item.mediaType == MediaType.movie ||
                item.mediaType == MediaType.tvShow)
            .toList();

        if (tmdbItems.isEmpty) {
          return const Center(
            child: Text('No movies/TV shows in this collection'),
          );
        }

        return ListView.builder(
          itemCount: tmdbItems.length,
          itemBuilder: (BuildContext context, int index) {
            return _ImageDebugTile(item: tmdbItems[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) =>
          Center(child: Text('Error: $error')),
    );
  }
}

/// Плитка отладки изображения элемента.
class _ImageDebugTile extends StatelessWidget {
  const _ImageDebugTile({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final String? fullUrl = item.coverUrl;
    final String? thumbUrl = item.thumbnailUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Заголовок: имя + тип
            Row(
              children: <Widget>[
                Icon(
                  item.mediaType == MediaType.movie
                      ? Icons.movie_outlined
                      : Icons.tv_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.itemName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.mediaType.displayLabel,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // External ID
            _buildInfoRow(
              context,
              'TMDB ID',
              item.externalId.toString(),
            ),

            // Joined data status
            _buildInfoRow(
              context,
              'Data loaded',
              item.mediaType == MediaType.movie
                  ? (item.movie != null ? 'YES' : 'NO (movie is null)')
                  : (item.tvShow != null ? 'YES' : 'NO (tvShow is null)'),
              isError: item.mediaType == MediaType.movie
                  ? item.movie == null
                  : item.tvShow == null,
            ),

            const Divider(height: 16),

            // Full URL
            _buildUrlRow(context, 'Full URL (w500)', fullUrl),

            const SizedBox(height: 4),

            // Thumbnail URL
            _buildUrlRow(context, 'Thumb URL (w154)', thumbUrl),

            const SizedBox(height: 12),

            // Превью изображений
            Row(
              children: <Widget>[
                // Thumbnail preview
                _buildImagePreview(
                  context,
                  'Thumb (w154)',
                  thumbUrl,
                  48,
                  64,
                ),
                const SizedBox(width: 16),
                // Full preview
                _buildImagePreview(
                  context,
                  'Full (w500)',
                  fullUrl,
                  80,
                  120,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isError = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: isError ? colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlRow(BuildContext context, String label, String? url) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: url != null
              ? SelectableText(
                  url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                )
              : Text(
                  'NULL',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (url != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Copy URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              context.showSnack('URL copied');
            },
          ),
      ],
    );
  }

  Widget _buildImagePreview(
    BuildContext context,
    String label,
    String? url,
    double width,
    double height,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: width,
            height: height,
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (BuildContext ctx, String u) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (BuildContext ctx, String u, Object error) =>
                        Container(
                      color: colorScheme.errorContainer,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 20,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        'NULL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
