// Экран вишлиста — заметки для отложенного поиска контента.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
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
    final S l = S.of(context);
    final AsyncValue<List<WishlistItem>> itemsAsync =
        ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AutoBreadcrumbAppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(
              _showResolved
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            color: AppColors.textSecondary,
            tooltip: _showResolved ? l.wishlistHideResolved : l.wishlistShowResolved,
            onPressed: () {
              setState(() {
                _showResolved = !_showResolved;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            color: AppColors.textSecondary,
            tooltip: l.wishlistClearResolved,
            onPressed: () => _confirmClearResolved(context),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Text(S.of(context).errorPrefix(error.toString())),
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
    final S l = S.of(context);

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
            l.wishlistEmpty,
            style: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.wishlistEmptyHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final WishlistDialogResult? result = await AddWishlistForm.show(context);
    if (result == null || !mounted) return;

    await ref.read(wishlistProvider.notifier).add(
          text: result.text,
          mediaTypeHint: result.mediaTypeHint,
          note: result.note,
        );
  }

  Future<void> _editItem(BuildContext context, WishlistItem item) async {
    final WishlistDialogResult? result = await AddWishlistForm.show(
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
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.wishlistDeleteItem),
        content: Text(l.wishlistDeletePrompt(item.text)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
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
    final S l = S.of(context);
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
        title: Text(l.wishlistClearResolvedTitle),
        content: Text(l.wishlistClearResolvedMessage(resolvedCount)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.clear),
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
    final S l = S.of(context);

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
            PopupMenuItem<String>(
              value: 'search',
              child: ListTile(
                leading: const Icon(Icons.search),
                title: Text(l.search),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l.edit),
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
                title: Text(item.isResolved ? l.wishlistUnresolve : l.wishlistMarkResolved),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l.delete, style: const TextStyle(color: Colors.red)),
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
      parts.add(item.mediaTypeHint!.localizedLabel(S.of(context)));
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' \u00b7 '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
