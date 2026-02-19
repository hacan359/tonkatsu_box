// Экран вишлиста — заметки для отложенного поиска контента.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';
import '../../search/screens/search_screen.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/add_wishlist_dialog.dart';

/// Экран вишлиста.
///
/// Показывает список заметок для отложенного поиска контента.
/// FAB для быстрого добавления, popup menu для действий.
class WishlistScreen extends ConsumerStatefulWidget {
  /// Создаёт [WishlistScreen].
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _showResolved = true;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WishlistItem>> itemsAsync =
        ref.watch(wishlistProvider);

    return Scaffold(
      appBar: BreadcrumbAppBar(
        crumbs: const <BreadcrumbItem>[
          BreadcrumbItem(label: 'Wishlist'),
        ],
        actions: <Widget>[
          IconButton(
            icon: Icon(
              _showResolved
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            tooltip: _showResolved ? 'Hide resolved' : 'Show resolved',
            onPressed: () {
              setState(() {
                _showResolved = !_showResolved;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear resolved',
            onPressed: () => _confirmClearResolved(context),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (List<WishlistItem> items) {
          final List<WishlistItem> filtered = _showResolved
              ? items
              : items
                  .where((WishlistItem item) => !item.isResolved)
                  .toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filtered.length,
            itemBuilder: (BuildContext context, int index) {
              return _WishlistTile(
                item: filtered[index],
                onTap: () => _searchForItem(context, filtered[index]),
                onResolve: () => _toggleResolved(filtered[index]),
                onEdit: () => _editItem(context, filtered[index]),
                onDelete: () => _deleteItem(context, filtered[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wishlist_add',
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No wishlist items yet',
            style: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap + to add something to find later',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final WishlistDialogResult? result = await AddWishlistDialog.show(context);
    if (result == null || !mounted) return;

    await ref.read(wishlistProvider.notifier).add(
          text: result.text,
          mediaTypeHint: result.mediaTypeHint,
          note: result.note,
        );
  }

  Future<void> _editItem(BuildContext context, WishlistItem item) async {
    final WishlistDialogResult? result = await AddWishlistDialog.show(
      context,
      existing: item,
    );
    if (result == null || !mounted) return;

    await ref.read(wishlistProvider.notifier).updateItem(
          item.id,
          text: result.text,
          mediaTypeHint: result.mediaTypeHint,
          clearMediaTypeHint: result.mediaTypeHint == null,
          note: result.note,
          clearNote: result.note == null,
        );
  }

  void _toggleResolved(WishlistItem item) {
    if (item.isResolved) {
      ref.read(wishlistProvider.notifier).unresolve(item.id);
    } else {
      ref.read(wishlistProvider.notifier).resolve(item.id);
    }
  }

  Future<void> _deleteItem(BuildContext context, WishlistItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete "${item.text}" from wishlist?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(wishlistProvider.notifier).delete(item.id);
    }
  }

  void _searchForItem(BuildContext context, WishlistItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchScreen(
          initialQuery: item.text,
          initialTabIndex: item.mediaTypeHint == MediaType.game ? 1 : 0,
        ),
      ),
    );
  }

  Future<void> _confirmClearResolved(BuildContext context) async {
    final int resolvedCount = ref
            .read(wishlistProvider)
            .valueOrNull
            ?.where((WishlistItem item) => item.isResolved)
            .length ??
        0;

    if (resolvedCount == 0) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear resolved'),
        content: Text(
          'Delete $resolvedCount resolved item${resolvedCount == 1 ? '' : 's'}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(wishlistProvider.notifier).clearResolved();
    }
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({
    required this.item,
    required this.onTap,
    required this.onResolve,
    required this.onEdit,
    required this.onDelete,
  });

  final WishlistItem item;
  final VoidCallback onTap;
  final VoidCallback onResolve;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isResolved ? 0.5 : 1.0,
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          item.text,
          style: item.isResolved
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: _buildSubtitle(context),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            switch (value) {
              case 'search':
                onTap();
              case 'edit':
                onEdit();
              case 'resolve':
                onResolve();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Search'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
              value: 'resolve',
              child: ListTile(
                leading: Icon(
                  item.isResolved ? Icons.undo : Icons.check_circle_outline,
                ),
                title: Text(item.isResolved ? 'Unresolve' : 'Mark resolved'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (item.mediaTypeHint != null) {
      return Icon(
        MediaTypeTheme.iconFor(item.mediaTypeHint!),
        color: MediaTypeTheme.colorFor(item.mediaTypeHint!),
      );
    }
    return const Icon(Icons.bookmark_border, color: AppColors.textTertiary);
  }

  Widget? _buildSubtitle(BuildContext context) {
    final List<String> parts = <String>[];
    if (item.hasNote) {
      parts.add(item.note!);
    }
    if (item.mediaTypeHint != null && !item.hasNote) {
      parts.add(item.mediaTypeHint!.displayLabel);
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
