import 'package:flutter/material.dart';

import '../../../core/database/dao/wishlist_dao.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/wishlist_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';

/// Bulk operation surfaced when a tag/search filter narrows the visible list.
enum WishlistBulkAction { applyTag, removeTag, delete }

/// Full-width chevron filter bar for the wishlist: tag picker + bulk actions.
class WishlistTagHeader extends StatelessWidget {
  const WishlistTagHeader({
    required this.tags,
    required this.selected,
    required this.filteredCount,
    required this.totalCount,
    required this.onChanged,
    required this.onRename,
    required this.onDelete,
    required this.onBulkAction,
    super.key,
  });

  final List<WishlistTagCount> tags;
  final WishlistTagFilter selected;
  final int filteredCount;
  final int totalCount;
  final ValueChanged<WishlistTagFilter> onChanged;
  final Future<void> Function(String? tag) onRename;
  final Future<void> Function(String? tag, int itemCount) onDelete;
  final Future<void> Function(WishlistBulkAction action) onBulkAction;

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

class _BulkActionsSegment extends StatelessWidget {
  const _BulkActionsSegment({
    required this.count,
    required this.onAction,
  });

  final int count;
  final Future<void> Function(WishlistBulkAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return DropdownChevronSegment<WishlistBulkAction>(
      label: l.wishlistBulkActionsButton(count),
      icon: Icons.checklist,
      selected: false,
      accentColor: AppColors.brand,
      isFirst: false,
      isLast: true,
      menuBuilder: (BuildContext ctx) {
        final S sl = S.of(ctx);
        return <PopupMenuEntry<WishlistBulkAction>>[
          PopupMenuItem<WishlistBulkAction>(
            value: WishlistBulkAction.applyTag,
            child: ListTile(
              leading: const Icon(Icons.label),
              title: Text(sl.wishlistBulkApplyTag),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          PopupMenuItem<WishlistBulkAction>(
            value: WishlistBulkAction.removeTag,
            child: ListTile(
              leading: const Icon(Icons.label_off),
              title: Text(sl.wishlistBulkRemoveTag),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<WishlistBulkAction>(
            value: WishlistBulkAction.delete,
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
      onSelected: (WishlistBulkAction? picked) async {
        if (picked != null) await onAction(picked);
      },
    );
  }
}
