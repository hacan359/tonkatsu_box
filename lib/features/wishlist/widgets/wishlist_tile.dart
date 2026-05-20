import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/mini_markdown_text.dart';

enum _TileAction { search, edit, resolve, delete }

/// Single wishlist item row with a right-click / long-press context menu.
class WishlistTile extends StatelessWidget {
  const WishlistTile({
    required this.item,
    required this.onTap,
    required this.onResolve,
    required this.onEdit,
    required this.onDelete,
    super.key,
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

  Future<void> _showContextMenu(
    BuildContext context,
    Offset position,
  ) async {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final _TileAction? picked = await showMenu<_TileAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<_TileAction>>[
        PopupMenuItem<_TileAction>(
          value: _TileAction.search,
          child: ListTile(
            leading: const Icon(Icons.search),
            title: Text(l.search),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem<_TileAction>(
          value: _TileAction.edit,
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l.edit),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem<_TileAction>(
          value: _TileAction.resolve,
          child: ListTile(
            leading: Icon(
              item.isResolved ? Icons.undo : Icons.check_circle_outline,
            ),
            title: Text(item.isResolved
                ? l.wishlistUnresolve
                : l.wishlistMarkResolved),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_TileAction>(
          value: _TileAction.delete,
          child: ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                Text(l.delete, style: const TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );

    if (picked == null) return;
    switch (picked) {
      case _TileAction.search:
        onTap();
      case _TileAction.edit:
        onEdit();
      case _TileAction.resolve:
        onResolve();
      case _TileAction.delete:
        onDelete();
    }
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

    final String subtitle = parts.join(' · ');

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
