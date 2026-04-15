// Bottom sheet с тегами и сортировкой коллекции — для узких экранов
// (где TagSidebar не помещается).
//
// Открывается из CollectionFilterBar по тапу на иконку «Теги/Сортировка».
// Все изменения применяются мгновенно (sheet остаётся открытым).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../settings/widgets/settings_tile.dart';
import '../providers/collections_provider.dart';

/// Открыть [CollectionFilterSheet] как modal bottom sheet.
Future<void> showCollectionFilterSheet(
  BuildContext context, {
  required int? collectionId,
  required List<CollectionTag> tags,
  required Set<int> selectedTagIds,
  required bool groupByTags,
  required ValueChanged<int?> onTagToggled,
  required VoidCallback onGroupToggled,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext _, ScrollController scrollController) =>
          CollectionFilterSheet(
        scrollController: scrollController,
        collectionId: collectionId,
        tags: tags,
        selectedTagIds: selectedTagIds,
        groupByTags: groupByTags,
        onTagToggled: onTagToggled,
        onGroupToggled: onGroupToggled,
      ),
    ),
  );
}

/// Содержимое bottom sheet: теги (multi-select) + сортировка.
///
/// Sheet хранит свой локальный snapshot `selectedTagIds`/`groupByTags` —
/// иначе он не реагирует на собственные действия (Navigator-овые маршруты
/// не пересоздаются от setState родителя). После каждого изменения
/// callback родителя вызывается, чтобы parent тоже обновился.
class CollectionFilterSheet extends ConsumerStatefulWidget {
  /// Создаёт [CollectionFilterSheet].
  const CollectionFilterSheet({
    required this.scrollController,
    required this.collectionId,
    required this.tags,
    required this.selectedTagIds,
    required this.groupByTags,
    required this.onTagToggled,
    required this.onGroupToggled,
    super.key,
  });

  /// Контроллер скролла из [DraggableScrollableSheet].
  final ScrollController scrollController;

  /// ID коллекции (null = uncategorized).
  final int? collectionId;

  /// Все теги коллекции.
  final List<CollectionTag> tags;

  /// ID выбранных тегов (initial snapshot).
  final Set<int> selectedTagIds;

  /// Включена ли группировка по тегам (initial snapshot).
  final bool groupByTags;

  /// Callback при тапе на тег (id) или null = сбросить все.
  final ValueChanged<int?> onTagToggled;

  /// Callback переключения «Группировать по тегам».
  final VoidCallback onGroupToggled;

  @override
  ConsumerState<CollectionFilterSheet> createState() =>
      _CollectionFilterSheetState();
}

class _CollectionFilterSheetState
    extends ConsumerState<CollectionFilterSheet> {
  late final Set<int> _selectedTagIds = <int>{...widget.selectedTagIds};
  late bool _groupByTags = widget.groupByTags;

  void _handleTagToggle(int? id) {
    setState(() {
      if (id == null) {
        _selectedTagIds.clear();
      } else if (_selectedTagIds.contains(id)) {
        _selectedTagIds.remove(id);
      } else {
        _selectedTagIds.add(id);
      }
      // groupByTags сбрасывает теги в parent; учитываем
      // что parent же сбрасывает _filterTagIds при включении группы.
    });
    widget.onTagToggled(id);
  }

  void _handleGroupToggle() {
    setState(() {
      _groupByTags = !_groupByTags;
      // Логика parent: при тоггле group сбрасывает выбранные теги.
      _selectedTagIds.clear();
    });
    widget.onGroupToggled();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(widget.collectionId));
    final bool hasTagFilter = _selectedTagIds.isNotEmpty;

    return Material(
      color: AppColors.background,
      elevation: 16,
      shadowColor: Colors.black,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.backgroundTile),
            repeat: ImageRepeat.repeat,
            opacity: 0.03,
            scale: 0.667,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Цветной glow brand сверху.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.7),
                      radius: 1.1,
                      colors: <Color>[
                        AppColors.brand.withAlpha(80),
                        AppColors.brand.withAlpha(20),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Затемнение к низу.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.background.withAlpha(80),
                        AppColors.background.withAlpha(160),
                        AppColors.background.withAlpha(220),
                      ],
                      stops: const <double>[0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(80),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.surfaceBorder.withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Header: drag handle + Сбросить теги (если выбраны).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(80),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              if (hasTagFilter)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      minimumSize: const Size(0, 28),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _handleTagToggle(null),
                                    child: Text(
                                      l.filtersClear,
                                      style:
                                          AppTypography.bodySmall.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ===== Tags section =====
                    if (widget.tags.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          l.tagsLabel.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: <Widget>[
                            for (final CollectionTag tag in widget.tags)
                              _TagChip(
                                tag: tag,
                                selected: _selectedTagIds.contains(tag.id),
                                onTap: () => _handleTagToggle(tag.id),
                              ),
                          ],
                        ),
                      ),
                      // Group by tags toggle — стандартный паттерн settings.
                      SettingsTile(
                        title: l.tagSidebarGroup,
                        showChevron: false,
                        onTap: _handleGroupToggle,
                        trailing: Switch(
                          value: _groupByTags,
                          onChanged: (_) => _handleGroupToggle(),
                        ),
                      ),
                    ],

                    // ===== Sort section =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              l.collectionFilterSort.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          // Переключатель направления.
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              minimumSize: const Size(0, 28),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => ref
                                .read(collectionSortDescProvider(widget.collectionId)
                                    .notifier)
                                .toggle(),
                            icon: Icon(
                              isDescending
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            label: Text(
                              isDescending
                                  ? l.collectionFilterDescending
                                  : l.collectionFilterAscending,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final CollectionSortMode mode
                        in CollectionSortMode.values)
                      _SortTile(
                        label: mode.localizedDisplayLabel(l),
                        selected: mode == currentSort,
                        onTap: () => ref
                            .read(collectionSortProvider(widget.collectionId)
                                .notifier)
                            .setSortMode(mode),
                      ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Tag chip
// =========================================================================

/// Чип-тег для multi-select. Цвет тега + selected состояние.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final CollectionTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = tag.color != null
        ? Color(tag.color!)
        : AppColors.textSecondary;
    // Selected: цветная заливка + чек-иконка + тёмный текст. Unselected:
    // прозрачный + цветной бордер + цветной текст.
    final Color bg = selected ? color : Colors.transparent;
    final Color fg = selected ? AppColors.background : color;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(
          color: color,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(Icons.check, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                tag.name,
                style: AppTypography.bodySmall.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Sort tile
// =========================================================================

/// Строка-радиокнопка для выбора сортировки.
class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 18,
        color: selected ? AppColors.brand : AppColors.textTertiary,
      ),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: selected ? AppColors.brand : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      onTap: onTap,
    );
  }
}
