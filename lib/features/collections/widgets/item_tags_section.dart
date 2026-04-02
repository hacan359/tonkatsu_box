// Компактный выбор тега на экране деталей элемента.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collection_tags_provider.dart';
import '../providers/collections_provider.dart';

/// Компактный виджет выбора одного тега (секции) на экране деталей элемента.
///
/// Отображается как небольшой чип/бейдж с названием тега.
/// По тапу — popup menu для выбора тега.
class ItemTagsSection extends ConsumerWidget {
  /// Создаёт [ItemTagsSection].
  const ItemTagsSection({
    required this.collectionId,
    required this.itemId,
    required this.currentTagId,
    required this.isEditable,
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  /// ID элемента коллекции.
  final int itemId;

  /// Текущий tag_id элемента.
  final int? currentTagId;

  /// Можно ли редактировать тег.
  final bool isEditable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<List<CollectionTag>> tagsAsync =
        ref.watch(collectionTagsProvider(collectionId));
    final List<CollectionTag> tags =
        tagsAsync.valueOrNull ?? <CollectionTag>[];

    if (tags.isEmpty) return const SizedBox.shrink();

    CollectionTag? currentTag;
    if (currentTagId != null) {
      for (final CollectionTag t in tags) {
        if (t.id == currentTagId) {
          currentTag = t;
          break;
        }
      }
    }

    final Color accentColor = currentTag?.color != null
        ? Color(currentTag!.color!)
        : AppColors.brand;

    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: currentTag != null
            ? accentColor.withAlpha(30)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: currentTag != null
              ? accentColor.withAlpha(80)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.label_outlined,
            size: 12,
            color: currentTag != null ? accentColor : AppColors.textTertiary,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              currentTag?.name ?? l.tagNone,
              style: AppTypography.caption.copyWith(
                color: currentTag != null
                    ? accentColor
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!isEditable) return chip;

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        _showTagPopup(context, ref, details.globalPosition, tags);
      },
      child: chip,
    );
  }

  /// Sentinel value для "без тега".
  static const int _noTagSentinel = -1;

  void _showTagPopup(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    List<CollectionTag> tags,
  ) {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: _noTagSentinel,
          child: Text(
            l.tagNone,
            style: AppTypography.bodySmall.copyWith(
              color: currentTagId == null
                  ? AppColors.brand
                  : AppColors.textTertiary,
            ),
          ),
        ),
        const PopupMenuDivider(),
        for (final CollectionTag tag in tags)
          PopupMenuItem<int>(
            value: tag.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tag.color != null
                        ? Color(tag.color!)
                        : AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  tag.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: currentTagId == tag.id
                        ? AppColors.brand
                        : null,
                    fontWeight: currentTagId == tag.id
                        ? FontWeight.w600
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((int? selected) {
      if (selected == null || !context.mounted) return;
      final int? newTagId = selected == _noTagSentinel ? null : selected;
      if (newTagId == currentTagId) return;
      _setTag(ref, newTagId);
    });
  }

  Future<void> _setTag(WidgetRef ref, int? tagId) async {
    final TagDao dao = ref.read(tagDaoProvider);
    await dao.setItemTag(itemId, tagId);
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateItemTag(itemId, tagId);
  }
}
