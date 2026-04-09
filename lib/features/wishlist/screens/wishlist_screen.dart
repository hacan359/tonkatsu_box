// Экран вишлиста — заметки для отложенного поиска контента.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/mini_markdown_text.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
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
  String _typeToFilterQuery = '';

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<WishlistItem>> itemsAsync =
        ref.watch(wishlistProvider);

    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(),
      child: Scaffold(
      appBar: ScreenAppBar(
        title: l.navWishlist,
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
      body: TypeToFilterOverlay(
        onFilterChanged: (String query) {
          setState(() => _typeToFilterQuery = query);
        },
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) => Center(
            child: Text(S.of(context).errorPrefix(error.toString())),
          ),
          data: (List<WishlistItem> items) {
            List<WishlistItem> filtered = _showResolved
                ? items
                : items
                    .where((WishlistItem item) => !item.isResolved)
                    .toList();

            if (_typeToFilterQuery.isNotEmpty) {
              final String query = _typeToFilterQuery.toLowerCase();
              filtered = filtered
                  .where((WishlistItem item) =>
                      item.text.toLowerCase().contains(query))
                  .toList();
            }

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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wishlist_add',
        tooltip: kIsMobile ? null : '${S.of(context).wishlistAddTitle} (Ctrl+N)',
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add),
      ),
    ),
    );
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
    final String? sourceId = switch (item.mediaTypeHint) {
      MediaType.game => 'games',
      MediaType.movie => 'movies',
      MediaType.tvShow => 'tv',
      MediaType.animation => 'anime',
      MediaType.visualNovel => 'visual_novels',
      MediaType.manga => 'manga',
      MediaType.custom => null,
      null => null,
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchScreen(
          initialQuery: item.text,
          initialSourceId: sourceId,
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
