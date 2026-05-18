// Экран вишлиста — заметки для отложенного поиска контента.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/wishlist_dao.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/models/wishlist_tag.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/mini_markdown_text.dart';
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

  /// Группа хоткеев этого экрана для легенды F1.
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
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stack) => Center(
              child: Text(S.of(context).errorPrefix(error.toString())),
            ),
            data: (List<WishlistItem> items) {
              final List<WishlistItem> filtered = _applyFilters(
                items,
                searchQuery: searchQuery,
              );

              // Always show the header when the wishlist isn't empty — the
              // text-style picker is unobtrusive and stays consistent as
              // tags appear/disappear during edits.
              final bool showHeader = items.isNotEmpty;

              return Column(
                children: <Widget>[
                  if (showHeader)
                    _WishlistTagHeader(
                      tags: tags,
                      selected: _tagFilter,
                      filteredCount: filtered.length,
                      totalCount: items.length,
                      onChanged: (WishlistTagFilter v) =>
                          setState(() => _tagFilter = v),
                      onRename: _promptRenameTag,
                      onDelete: _confirmDeleteTag,
                      onBulkAction: (_BulkAction a) =>
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
                              return _WishlistTile(
                                item: filtered[index],
                                onTap: () =>
                                    _searchForItem(context, filtered[index]),
                                onResolve: () =>
                                    _toggleResolved(filtered[index]),
                                onEdit: () =>
                                    _editItem(context, filtered[index]),
                                onDelete: () =>
                                    _deleteItem(context, filtered[index]),
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
    final String? sourceId = switch (item.mediaTypeHint) {
      MediaType.game => 'games',
      MediaType.movie => 'movies',
      MediaType.tvShow => 'tv',
      MediaType.animation => 'anime',
      MediaType.visualNovel => 'visual_novels',
      MediaType.manga => 'manga',
      MediaType.anime => 'anilist_anime',
      MediaType.custom => null,
      null => null,
    };

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
    _BulkAction action,
    List<WishlistItem> visible,
  ) async {
    if (visible.isEmpty) return;
    final Set<int> ids = visible.map((WishlistItem i) => i.id).toSet();

    switch (action) {
      case _BulkAction.applyTag:
        final String? tag = await _promptTagForBulk(ids.length);
        if (tag == null || !mounted) return;
        await ref.read(wishlistProvider.notifier).applyTagToIds(ids, tag);
      case _BulkAction.removeTag:
        await ref.read(wishlistProvider.notifier).applyTagToIds(ids, null);
      case _BulkAction.delete:
        final S l = S.of(context);
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l.wishlistBulkDelete),
            content: Text(l.wishlistBulkDeleteConfirm(ids.length)),
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
        if (confirmed != true || !mounted) return;
        await ref.read(wishlistProvider.notifier).deleteIds(ids);
    }
  }

  Future<String?> _promptTagForBulk(int count) async {
    final S l = S.of(context);
    final TextEditingController controller = TextEditingController();
    final String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.wishlistBulkApplyTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.wishlistBulkApplyTagHint(count)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l.wishlistTagPlaceholder),
              onSubmitted: (String v) =>
                  Navigator.of(context).pop(v.trim()),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l.apply),
          ),
        ],
      ),
    );
    if (input == null || input.isEmpty) return null;
    return input;
  }

  Future<void> _promptRenameTag(String? currentTag) async {
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: currentTag ?? '');

    final String? newTag = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.wishlistTagRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.wishlistTagPlaceholder),
          onSubmitted: (String value) =>
              Navigator.of(context).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (newTag == null || newTag.isEmpty || newTag == currentTag) return;
    if (!mounted) return;

    await ref.read(wishlistProvider.notifier).renameTag(currentTag, newTag);

    if (mounted) {
      setState(() => _tagFilter = WishlistTagFilter.named(newTag));
    }
  }

  Future<void> _confirmDeleteTag(
    String? tag,
    int itemCount,
  ) async {
    final S l = S.of(context);
    final String label = tag ?? l.wishlistTagUntagged;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.wishlistTagDelete),
        content: Text(l.wishlistTagDeleteConfirm(label, itemCount)),
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

    if (confirmed != true || !mounted) return;

    await ref.read(wishlistProvider.notifier).deleteByTag(tag);

    if (mounted) {
      setState(() => _tagFilter = const WishlistTagFilter.all());
    }
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

/// Full-width chevron filter bar: two segments (tag picker + bulk actions),
/// always shown. Same visual language as the collection / search filter bars.
class _WishlistTagHeader extends StatelessWidget {
  const _WishlistTagHeader({
    required this.tags,
    required this.selected,
    required this.filteredCount,
    required this.totalCount,
    required this.onChanged,
    required this.onRename,
    required this.onDelete,
    required this.onBulkAction,
  });

  final List<WishlistTagCount> tags;
  final WishlistTagFilter selected;
  final int filteredCount;
  final int totalCount;
  final ValueChanged<WishlistTagFilter> onChanged;
  final Future<void> Function(String? tag) onRename;
  final Future<void> Function(String? tag, int itemCount) onDelete;
  final Future<void> Function(_BulkAction action) onBulkAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _TagPickerSegment(
                tags: tags,
                selected: selected,
                onChanged: onChanged,
                onRename: onRename,
                onDelete: onDelete,
              ),
            ),
            Expanded(
              child: _BulkActionsSegment(
                count: filteredCount,
                onAction: onBulkAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPickerSegment extends StatelessWidget {
  const _TagPickerSegment({
    required this.tags,
    required this.selected,
    required this.onChanged,
    required this.onRename,
    required this.onDelete,
  });

  final List<WishlistTagCount> tags;
  final WishlistTagFilter selected;
  final ValueChanged<WishlistTagFilter> onChanged;
  final Future<void> Function(String? tag) onRename;
  final Future<void> Function(String? tag, int itemCount) onDelete;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final int totalActive =
        tags.fold(0, (int sum, WishlistTagCount t) => sum + t.activeCount);
    final int totalAll =
        tags.fold(0, (int sum, WishlistTagCount t) => sum + t.totalCount);

    final String label = _currentLabel(l);
    final int count = _currentCount(totalActive);
    final bool active = selected is! WishlistTagFilterAll;

    return DropdownChevronSegment<_TagMenuChoice>(
      label: '$label ($count)',
      icon: Icons.folder_outlined,
      selected: active,
      accentColor: AppColors.brand,
      isFirst: true,
      isLast: false,
      menuBuilder: (BuildContext ctx) =>
          _buildMenu(ctx, totalActive, totalAll),
      onSelected: (_TagMenuChoice? picked) async {
        if (picked == null) return;
        switch (picked) {
          case _TagMenuFilter(:final WishlistTagFilter filter):
            onChanged(filter);
          case _TagMenuRename():
            if (selected is WishlistTagFilterNamed) {
              await onRename((selected as WishlistTagFilterNamed).tag);
            }
          case _TagMenuDelete():
            final String? rawTag = switch (selected) {
              WishlistTagFilterNamed(:final String tag) => tag,
              _ => null,
            };
            final WishlistTagCount bucket = tags.firstWhere(
              (WishlistTagCount t) => t.tag == rawTag,
              orElse: () => const WishlistTagCount(
                tag: null,
                activeCount: 0,
                totalCount: 0,
              ),
            );
            await onDelete(rawTag, bucket.totalCount);
        }
      },
    );
  }

  String _currentLabel(S l) {
    return switch (selected) {
      WishlistTagFilterAll() => l.wishlistTagAll,
      WishlistTagFilterUntagged() => l.wishlistTagUntagged,
      WishlistTagFilterNamed(:final String tag) => _humanLabel(tag),
    };
  }

  int _currentCount(int totalActive) {
    return switch (selected) {
      WishlistTagFilterAll() => totalActive,
      WishlistTagFilterUntagged() => _countFor(null),
      WishlistTagFilterNamed(:final String tag) => _countFor(tag),
    };
  }

  int _countFor(String? tag) {
    for (final WishlistTagCount t in tags) {
      if (t.tag == tag) return t.activeCount;
    }
    return 0;
  }

  List<PopupMenuEntry<_TagMenuChoice>> _buildMenu(
    BuildContext context,
    int totalActive,
    int totalAll,
  ) {
    final S l = S.of(context);
    final bool canManage = selected is WishlistTagFilterNamed ||
        selected is WishlistTagFilterUntagged;

    return <PopupMenuEntry<_TagMenuChoice>>[
      _tagMenuItem(
        value: const _TagMenuChoice.filter(WishlistTagFilter.all()),
        label: l.wishlistTagAll,
        count: totalActive,
        total: totalAll,
        isSelected: selected is WishlistTagFilterAll,
      ),
      for (final WishlistTagCount t in tags)
        _tagMenuItem(
          value: _TagMenuChoice.filter(t.tag == null
              ? const WishlistTagFilter.untagged()
              : WishlistTagFilter.named(t.tag!)),
          label: t.tag == null ? l.wishlistTagUntagged : _humanLabel(t.tag!),
          count: t.activeCount,
          total: t.totalCount,
          isSelected: _isSelected(t.tag),
        ),
      if (canManage) ...<PopupMenuEntry<_TagMenuChoice>>[
        const PopupMenuDivider(),
        if (selected is WishlistTagFilterNamed)
          PopupMenuItem<_TagMenuChoice>(
            value: const _TagMenuChoice.rename(),
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.wishlistTagRename),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        PopupMenuItem<_TagMenuChoice>(
          value: const _TagMenuChoice.deleteTag(),
          child: ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              l.wishlistTagDelete,
              style: const TextStyle(color: Colors.red),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    ];
  }

  PopupMenuItem<_TagMenuChoice> _tagMenuItem({
    required _TagMenuChoice value,
    required String label,
    required int count,
    required int total,
    required bool isSelected,
  }) {
    return PopupMenuItem<_TagMenuChoice>(
      value: value,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            child: isSelected
                ? const Icon(Icons.check, size: 18)
                : const SizedBox.shrink(),
          ),
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count/$total',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSelected(String? rowTag) {
    return switch (selected) {
      WishlistTagFilterAll() => false,
      WishlistTagFilterUntagged() => rowTag == null,
      WishlistTagFilterNamed(:final String tag) => tag == rowTag,
    };
  }

  static String _humanLabel(String tag) {
    final WishlistTagInfo info = parseWishlistTag(tag);
    if (info.isAutoGenerated) {
      final DateTime ts = info.timestamp!.toLocal();
      return '${info.source} — '
          '${ts.year}-${_two(ts.month)}-${_two(ts.day)} '
          '${_two(ts.hour)}:${_two(ts.minute)}';
    }
    return tag;
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';
}

sealed class _TagMenuChoice {
  const _TagMenuChoice();
  const factory _TagMenuChoice.filter(WishlistTagFilter filter) =
      _TagMenuFilter;
  const factory _TagMenuChoice.rename() = _TagMenuRename;
  const factory _TagMenuChoice.deleteTag() = _TagMenuDelete;
}

final class _TagMenuFilter extends _TagMenuChoice {
  const _TagMenuFilter(this.filter);
  final WishlistTagFilter filter;
}

final class _TagMenuRename extends _TagMenuChoice {
  const _TagMenuRename();
}

final class _TagMenuDelete extends _TagMenuChoice {
  const _TagMenuDelete();
}

/// Bulk operation surfaced when the visible list is narrower than the full
/// wishlist (tag filter and/or search query active).
enum _BulkAction { applyTag, removeTag, delete }

class _BulkActionsSegment extends StatelessWidget {
  const _BulkActionsSegment({
    required this.count,
    required this.onAction,
  });

  final int count;
  final Future<void> Function(_BulkAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return DropdownChevronSegment<_BulkAction>(
      label: l.wishlistBulkActionsButton(count),
      icon: Icons.checklist,
      selected: false,
      accentColor: AppColors.brand,
      isFirst: false,
      isLast: true,
      menuBuilder: (BuildContext ctx) {
        final S sl = S.of(ctx);
        return <PopupMenuEntry<_BulkAction>>[
          PopupMenuItem<_BulkAction>(
            value: _BulkAction.applyTag,
            child: ListTile(
              leading: const Icon(Icons.label),
              title: Text(sl.wishlistBulkApplyTag),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          PopupMenuItem<_BulkAction>(
            value: _BulkAction.removeTag,
            child: ListTile(
              leading: const Icon(Icons.label_off),
              title: Text(sl.wishlistBulkRemoveTag),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<_BulkAction>(
            value: _BulkAction.delete,
            child: ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                sl.wishlistBulkDelete,
                style: const TextStyle(color: Colors.red),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ];
      },
      onSelected: (_BulkAction? picked) async {
        if (picked != null) await onAction(picked);
      },
    );
  }
}

/// FAB с popup-меню: добавить, показать/скрыть resolved, очистить resolved.
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
      child: GestureDetector(
        onSecondaryTapUp: (TapUpDetails details) =>
            _showContextMenu(context, details.globalPosition),
        child: ListTile(
          leading: _buildLeadingIcon(),
          title: Text(
            item.text,
            style: item.isResolved
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: _buildSubtitle(context),
          onLongPress: () => _showContextMenu(
            context,
            _centerOfContext(context),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Offset _centerOfContext(BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
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
    ).then((String? value) {
      if (value == null) return;
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
    });
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

    final String subtitle = parts.join(' \u00b7 ');

    // Если есть заметка — рендерим через MiniMarkdownText для поддержки разметки.
    if (item.hasNote) {
      return MiniMarkdownText(
        text: subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      );
    }

    return Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
