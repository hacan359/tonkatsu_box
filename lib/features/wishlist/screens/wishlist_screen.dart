import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/wishlist_dao.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/models/wishlist_tag.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../search/screens/search_screen.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/add_wishlist_dialog.dart';
import '../widgets/wishlist_dialogs.dart';
import '../widgets/wishlist_tag_header.dart';
import '../widgets/wishlist_tile.dart';

/// Maps a wishlist [MediaType] hint to the primary search source id.
///
/// The returned id must exist in `searchSources`; an unknown id makes
/// `getSearchSourceById` silently fall back to the first source (movies),
/// which is how a book hint used to open the movies tab.
String? wishlistSourceIdFor(MediaType? hint) {
  return switch (hint) {
    MediaType.game => 'games',
    MediaType.movie => 'movies',
    MediaType.tvShow => 'tv',
    MediaType.animation => 'anime',
    MediaType.visualNovel => 'visual_novels',
    MediaType.manga => 'manga',
    MediaType.anime => 'anilist_anime',
    MediaType.book => 'openlibrary',
    MediaType.custom => null,
    null => null,
  };
}

/// Wishlist screen — notes for deferred content search.
class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Вишлист',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+N', description: 'Добавить элемент'),
      ShortcutEntry(keys: 'Ctrl+H', description: 'Показать/скрыть выполненные'),
      ShortcutEntry(keys: 'Ctrl+Shift+D', description: 'Очистить выполненные'),
    ],
  );

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _showResolved = true;
  WishlistTagFilter _tagFilter = const WishlistTagFilter.all();

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WishlistItem>> itemsAsync =
        ref.watch(wishlistProvider);
    final String searchQuery = ref.watch(wishlistSearchQueryProvider);
    final List<WishlistTagCount> tags = ref.watch(wishlistTagsProvider);

    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(),
      child: Stack(
        children: <Widget>[
          itemsAsync.when(
            loading: () => const ShimmerList(),
            error: (Object error, StackTrace stack) => Center(
              child: Text(S.of(context).errorPrefix(error.toString())),
            ),
            data: (List<WishlistItem> items) {
              final List<WishlistItem> filtered = _applyFilters(
                items,
                searchQuery: searchQuery,
              );
              // Keep the header visible whenever the wishlist isn't empty —
              // the text-style picker stays consistent as tags appear and
              // disappear during edits.
              final bool showHeader = items.isNotEmpty;

              return Column(
                children: <Widget>[
                  if (showHeader)
                    WishlistTagHeader(
                      tags: tags,
                      selected: _tagFilter,
                      filteredCount: filtered.length,
                      totalCount: items.length,
                      onChanged: (WishlistTagFilter v) =>
                          setState(() => _tagFilter = v),
                      onRename: _handleRenameTag,
                      onDelete: _handleDeleteTag,
                      onBulkAction: (WishlistBulkAction a) =>
                          _runBulkAction(a, filtered),
                    ),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder:
                                (BuildContext context, int index) {
                              final WishlistItem item = filtered[index];
                              return WishlistTile(
                                item: item,
                                onTap: () => _searchForItem(context, item),
                                onResolve: () => _toggleResolved(item),
                                onEdit: () => _editItem(context, item),
                                onDelete: () => _deleteItem(context, item),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          DraggableFab(
            mainAction: _buildAddItem(context),
            items: _buildFabItems(context),
          ),
        ],
      ),
    );
  }

  List<WishlistItem> _applyFilters(
    List<WishlistItem> items, {
    required String searchQuery,
  }) {
    Iterable<WishlistItem> filtered = items;

    if (!_showResolved) {
      filtered = filtered.where((WishlistItem item) => !item.isResolved);
    }

    final WishlistTagFilter tagFilter = _tagFilter;
    if (tagFilter is WishlistTagFilterUntagged) {
      filtered = filtered.where((WishlistItem item) => item.tag == null);
    } else if (tagFilter is WishlistTagFilterNamed) {
      filtered =
          filtered.where((WishlistItem item) => item.tag == tagFilter.tag);
    }

    if (searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      filtered = filtered.where((WishlistItem item) {
        if (item.text.toLowerCase().contains(query)) return true;
        final String? note = item.note;
        return note != null && note.toLowerCase().contains(query);
      });
    }

    return filtered.toList();
  }

  DraggableFabItem _buildAddItem(BuildContext context) {
    final S l = S.of(context);
    return DraggableFabItem(
      icon: Icons.add,
      label: l.wishlistAddTitle,
      onTap: () => _addItem(context),
    );
  }

  List<DraggableFabItem> _buildFabItems(BuildContext context) {
    final S l = S.of(context);
    return <DraggableFabItem>[
      DraggableFabItem(
        icon: _showResolved ? Icons.visibility_off : Icons.visibility,
        label: _showResolved
            ? l.wishlistHideResolved
            : l.wishlistShowResolved,
        onTap: () => setState(() => _showResolved = !_showResolved),
      ),
      DraggableFabItem(
        icon: Icons.delete_sweep,
        label: l.wishlistClearResolved,
        iconColor: AppColors.error,
        onTap: () => _confirmClearResolved(context),
      ),
    ];
  }

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts() {
    if (kIsMobile) return <ShortcutActivator, VoidCallback>{};
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          () => _addItem(context),
      const SingleActivator(LogicalKeyboardKey.keyH, control: true):
          () => setState(() => _showResolved = !_showResolved),
      const SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true):
          () => _confirmClearResolved(context),
    };
  }

  Widget _buildEmptyState(BuildContext context) {
    final S l = S.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppColors.textTertiary.withAlpha(120),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.wishlistEmpty,
            style: AppTypography.h2.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.wishlistEmptyHint,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
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
          tag: result.tag,
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
          tag: result.tag,
          clearTag: result.tag == null,
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
    final bool confirmed =
        await WishlistDialogs.confirmDeleteItem(context, item.text);
    if (!confirmed || !mounted) return;
    await ref.read(wishlistProvider.notifier).delete(item.id);
  }

  void _searchForItem(BuildContext context, WishlistItem item) {
    final String? sourceId = wishlistSourceIdFor(item.mediaTypeHint);

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchScreen(
          initialQuery: item.text,
          initialSourceId: sourceId,
          isPushed: true,
        ),
      ),
    );
  }

  Future<void> _runBulkAction(
    WishlistBulkAction action,
    List<WishlistItem> visible,
  ) async {
    if (visible.isEmpty) return;
    final Set<int> ids = visible.map((WishlistItem i) => i.id).toSet();

    switch (action) {
      case WishlistBulkAction.applyTag:
        final String? tag =
            await WishlistDialogs.promptBulkTag(context, ids.length);
        if (tag == null || !mounted) return;
        await ref.read(wishlistProvider.notifier).applyTagToIds(ids, tag);
      case WishlistBulkAction.removeTag:
        await ref.read(wishlistProvider.notifier).applyTagToIds(ids, null);
      case WishlistBulkAction.delete:
        final bool confirmed =
            await WishlistDialogs.confirmBulkDelete(context, ids.length);
        if (!confirmed || !mounted) return;
        await ref.read(wishlistProvider.notifier).deleteIds(ids);
    }
  }

  Future<void> _handleRenameTag(String? currentTag) async {
    final String? newTag =
        await WishlistDialogs.promptRenameTag(context, currentTag);
    if (newTag == null || !mounted) return;
    await ref.read(wishlistProvider.notifier).renameTag(currentTag, newTag);
    if (mounted) {
      setState(() => _tagFilter = WishlistTagFilter.named(newTag));
    }
  }

  Future<void> _handleDeleteTag(String? tag, int itemCount) async {
    final bool confirmed =
        await WishlistDialogs.confirmDeleteTag(context, tag, itemCount);
    if (!confirmed || !mounted) return;
    await ref.read(wishlistProvider.notifier).deleteByTag(tag);
    if (mounted) {
      setState(() => _tagFilter = const WishlistTagFilter.all());
    }
  }

  Future<void> _confirmClearResolved(BuildContext context) async {
    final int resolvedCount = ref
            .read(wishlistProvider)
            .valueOrNull
            ?.where((WishlistItem item) => item.isResolved)
            .length ??
        0;
    if (resolvedCount == 0) return;

    final bool confirmed =
        await WishlistDialogs.confirmClearResolved(context, resolvedCount);
    if (!confirmed || !mounted) return;
    await ref.read(wishlistProvider.notifier).clearResolved();
  }
}
